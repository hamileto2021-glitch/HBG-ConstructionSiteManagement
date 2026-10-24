using CSM.Application.Common.Exceptions;
using CSM.Application.Reporting;
using CSM.Application.Reporting.Dtos;
using CSM.Domain.Constants;
using CSM.Domain.Entities.Identity;
using CSM.Domain.Enums;
using CSM.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CSM.Infrastructure.Services;

/// <summary>
/// All reports are built from ONE set of calculations (LoadRawBySiteAsync),
/// so the dashboards, the company summary, the site summaries and the
/// "all" total always agree, and the total equals company + sites.
///
/// Definitions
///   Budget        Approved, Active and Closed budgets.
///   Expenses      Approved and Paid expenses, Amount + TaxAmount.
///   Invoiced      Client invoices that are issued (not Draft, not Cancelled).
///   Outstanding   Per invoice: max(0, invoice total - completed payments
///                 linked to that invoice), then summed. This is the same sum
///                 PaymentService uses to recalculate an invoice.
///   Cash in/out   COMPLETED payments only. A payment on an invoice follows
///                 the invoice (client invoice = in, vendor bill = out);
///                 otherwise its own Direction is used.
///   Pending       Pending payments: recorded but not yet completed. They are
///                 shown separately and never counted as cash.
///   Payment site  The invoice's site when the payment is on an invoice,
///                 otherwise the payment's own site (as PaymentService).
///   Petty cash    Balance of all accounts; count of active accounts. Money
///                 in = recorded CashIn plus each account's opening balance
///                 (balance - CashIn + CashOut, when positive).
/// </summary>
public sealed class ReportingService : IReportingService
{
    private readonly ApplicationDbContext _dbContext;

    public ReportingService(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    // ------------------------------------------------------------------
    // Dashboards
    // ------------------------------------------------------------------

    public async Task<ExecutiveDashboardResponse> GetExecutiveDashboardAsync(
        Guid currentUserId,
        CancellationToken cancellationToken = default)
    {
        var context = await GetReportContextAsync(
            currentUserId,
            GranularPermission.Reports_View,
            cancellationToken);

        return await BuildDashboardAsync(
            context.CompanyId,
            context.Scope,
            onlySiteId: null,
            cancellationToken);
    }

    public async Task<ExecutiveDashboardResponse>
        GetSiteExecutiveDashboardAsync(
            Guid currentUserId,
            Guid constructionSiteId,
            CancellationToken cancellationToken = default)
    {
        var context = await GetReportContextAsync(
            currentUserId,
            GranularPermission.Reports_View,
            cancellationToken);

        await EnsureSiteExistsAsync(
            context.CompanyId,
            constructionSiteId,
            cancellationToken);

        EnsureSiteInScope(context.Scope, constructionSiteId);

        return await BuildDashboardAsync(
            context.CompanyId,
            context.Scope,
            onlySiteId: constructionSiteId,
            cancellationToken);
    }

    private async Task<ExecutiveDashboardResponse> BuildDashboardAsync(
        Guid companyId,
        Scope scope,
        Guid? onlySiteId,
        CancellationToken cancellationToken)
    {
        var rawBySite = await LoadRawBySiteAsync(companyId, cancellationToken);
        var total = rawBySite.TotalFor(scope, onlySiteId);

        var sites = (await _dbContext.ConstructionSites
                .AsNoTracking()
                .Where(s => s.CompanyId == companyId && !s.IsDeleted)
                .Select(s => new { s.Id, s.Status, s.IsActive })
                .ToListAsync(cancellationToken))
            .Where(s => onlySiteId.HasValue
                ? s.Id == onlySiteId.Value
                : scope.Includes(s.Id))
            .ToList();

        var projects = (await _dbContext.Projects
                .AsNoTracking()
                .Where(p => p.CompanyId == companyId && !p.IsDeleted)
                .Select(p => new
                {
                    p.Status,
                    p.ContractValue,
                    p.ConstructionSiteId
                })
                .ToListAsync(cancellationToken))
            .Where(p => onlySiteId.HasValue
                ? p.ConstructionSiteId == onlySiteId.Value
                : scope.Includes(p.ConstructionSiteId))
            .ToList();

        return new ExecutiveDashboardResponse(
            sites.Count,
            sites.Count(s => s.IsActive),
            projects.Count,
            projects.Sum(p => p.ContractValue),
            total.Budget,
            total.Expenses,
            total.ClientInvoiced,
            total.PaymentsIn,
            total.ClientOutstanding,
            sites
                .GroupBy(s => s.Status)
                .ToDictionary(g => g.Key, g => g.Count()),
            projects
                .GroupBy(p => p.Status)
                .ToDictionary(g => g.Key, g => g.Count()));
    }

    // ------------------------------------------------------------------
    // Financial summaries
    // ------------------------------------------------------------------

    /// <summary>Company-level records (not tied to a site).</summary>
    public async Task<FinancialSummaryResponse> GetFinancialSummaryAsync(
        Guid currentUserId,
        CancellationToken cancellationToken = default)
    {
        var context = await GetReportContextAsync(
            currentUserId,
            GranularPermission.Reports_FinancialSummary_View,
            cancellationToken);

        // Company-level figures are not tied to any site, so only users with
        // company-wide access may see them.
        if (!context.Scope.All)
        {
            throw new ReportingManagementException(
                "You are not authorized to view company-level financial reports.");
        }

        var rawBySite = await LoadRawBySiteAsync(context.CompanyId, cancellationToken);
        var raw = rawBySite.Company;

        return ToResponse(raw, raw.PettyBalance, raw.PettyActive);
    }

    public async Task<FinancialSummaryResponse>
        GetSiteFinancialSummaryAsync(
            Guid currentUserId,
            Guid constructionSiteId,
            CancellationToken cancellationToken = default)
    {
        var context = await GetReportContextAsync(
            currentUserId,
            GranularPermission.Reports_FinancialSummary_View,
            cancellationToken);

        await EnsureSiteExistsAsync(
            context.CompanyId,
            constructionSiteId,
            cancellationToken);

        EnsureSiteInScope(context.Scope, constructionSiteId);

        var rawBySite = await LoadRawBySiteAsync(context.CompanyId, cancellationToken);
        var raw = rawBySite.ForSite(constructionSiteId);

        // Site reports have no company-level petty cash figures.
        return ToResponse(raw, 0m, 0);
    }

    public async Task<AllFinancialSummaryResponse>
        GetAllFinancialSummariesAsync(
            Guid currentUserId,
            CancellationToken cancellationToken = default)
    {
        var context = await GetReportContextAsync(
            currentUserId,
            GranularPermission.Reports_FinancialSummary_View,
            cancellationToken);

        // One load feeds the company summary, every site and the total.
        var rawBySite = await LoadRawBySiteAsync(context.CompanyId, cancellationToken);

        var sites = (await _dbContext.ConstructionSites
                .AsNoTracking()
                .Where(s => s.CompanyId == context.CompanyId && !s.IsDeleted)
                .OrderBy(s => s.Name)
                .Select(s => new { s.Id, s.Name, s.SiteCode })
                .ToListAsync(cancellationToken))
            .Where(s => context.Scope.Includes(s.Id))
            .ToList();

        // Company-level figures: company-wide users only; others see zeros.
        var companyRaw = context.Scope.All
            ? rawBySite.Company
            : new Raw();

        var companySummary = ToResponse(
            companyRaw,
            companyRaw.PettyBalance,
            companyRaw.PettyActive);

        var siteSummaries = new List<SiteFinancialSummaryResponse>();

        foreach (var site in sites)
        {
            var raw = rawBySite.ForSite(site.Id);

            siteSummaries.Add(
                new SiteFinancialSummaryResponse(
                    site.Id,
                    site.Name,
                    site.SiteCode,
                    ToResponse(raw, 0m, 0)));
        }

        // The total is the sum of the same raw figures, so it always equals
        // company + sites (plus records of deleted sites, for company-wide
        // users). Ratios are recalculated from the sums, never added.
        var total = rawBySite.TotalFor(context.Scope);

        var totalSummary = ToResponse(
            total,
            total.PettyBalance,
            total.PettyActive);

        return new AllFinancialSummaryResponse(
            companySummary,
            siteSummaries,
            totalSummary);
    }

    // The single place the response is built. Order must match the
    // FinancialSummaryResponse constructor.
    private static FinancialSummaryResponse ToResponse(
        Raw r,
        decimal companyPettyCashBalance,
        int companyPettyCashAccounts)
    {
        var totalExpenditure = r.PaymentsOut + r.PettyOut;

        var balance = r.PaymentsIn - totalExpenditure;

        var netCashFlow =
            r.PaymentsIn - r.PaymentsOut + (r.PettyIn - r.PettyOut);

        var budgetUtilization = r.Budget == 0m
            ? 0m
            : Math.Round(r.Expenses / r.Budget * 100m, 2);

        return new FinancialSummaryResponse(
            r.Budget,                    //  1 total budget
            r.Expenses,                  //  2 total expenses
            totalExpenditure,            //  3 total expenditure
            balance,                     //  4 balance
            r.ClientInvoiced,            //  5 total invoices (client)
            r.PaymentsIn,                //  6 total cash in
            r.ClientOutstanding,         //  7 outstanding receivables
            r.VendorOutstanding,         //  8 outstanding payables
            netCashFlow,                 //  9 net cash flow
            r.PettyBalance,              // 10 petty cash balance
            r.PettyOut,                  // 11 petty cash spent
            r.PettyActive,               // 12 active petty cash accounts
            budgetUtilization,           // 13 budget utilization %
            companyPettyCashBalance,     // 14 company petty cash balance
            companyPettyCashAccounts,    // 15 company petty cash accounts
            r.PendingIn,                 // 16 pending cash in (not completed)
            r.PendingOut);               // 17 pending cash out (not completed)
    }

    // ------------------------------------------------------------------
    // The shared calculation
    // ------------------------------------------------------------------

    private sealed class Raw
    {
        public decimal Budget;
        public decimal Expenses;
        public decimal ClientInvoiced;
        public decimal ClientOutstanding;
        public decimal VendorOutstanding;
        public decimal PaymentsIn;
        public decimal PaymentsOut;
        public decimal PendingIn;
        public decimal PendingOut;
        public decimal PettyIn;
        public decimal PettyOut;
        public decimal PettyBalance;
        public int PettyActive;

        public void Add(Raw o)
        {
            Budget += o.Budget;
            Expenses += o.Expenses;
            ClientInvoiced += o.ClientInvoiced;
            ClientOutstanding += o.ClientOutstanding;
            VendorOutstanding += o.VendorOutstanding;
            PaymentsIn += o.PaymentsIn;
            PaymentsOut += o.PaymentsOut;
            PendingIn += o.PendingIn;
            PendingOut += o.PendingOut;
            PettyIn += o.PettyIn;
            PettyOut += o.PettyOut;
            PettyBalance += o.PettyBalance;
            PettyActive += o.PettyActive;
        }
    }

    private sealed class RawBySite
    {
        public Raw Company { get; } = new();

        public Dictionary<Guid, Raw> Sites { get; } = new();

        public Raw For(Guid? siteId)
        {
            if (!siteId.HasValue)
            {
                return Company;
            }

            if (!Sites.TryGetValue(siteId.Value, out var raw))
            {
                raw = new Raw();
                Sites.Add(siteId.Value, raw);
            }

            return raw;
        }

        public Raw ForSite(Guid siteId) =>
            Sites.TryGetValue(siteId, out var raw) ? raw : new Raw();

        public Raw TotalFor(Scope scope, Guid? onlySiteId = null)
        {
            var total = new Raw();

            if (onlySiteId.HasValue)
            {
                total.Add(ForSite(onlySiteId.Value));
                return total;
            }

            if (scope.All)
            {
                total.Add(Company);
            }

            foreach (var (siteId, raw) in Sites)
            {
                if (scope.Includes(siteId))
                {
                    total.Add(raw);
                }
            }

            return total;
        }
    }

    private async Task<RawBySite> LoadRawBySiteAsync(
        Guid companyId,
        CancellationToken cancellationToken)
    {
        var result = new RawBySite();

        // Budgets in force or finished (not Draft, PendingApproval, Cancelled).
        var budgets = await _dbContext.Budgets
            .AsNoTracking()
            .Where(b =>
                b.CompanyId == companyId &&
                !b.IsDeleted &&
                (b.Status == BudgetStatus.Approved ||
                 b.Status == BudgetStatus.Active ||
                 b.Status == BudgetStatus.Closed))
            .GroupBy(b => b.ConstructionSiteId)
            .Select(g => new
            {
                Site = g.Key,
                Total = g.Sum(b => b.TotalAmount)
            })
            .ToListAsync(cancellationToken);

        foreach (var b in budgets)
        {
            result.For(b.Site).Budget += b.Total;
        }

        // Spent = approved and paid expenses, including tax.
        var expenses = await _dbContext.Expenses
            .AsNoTracking()
            .Where(e =>
                e.CompanyId == companyId &&
                !e.IsDeleted &&
                (e.Status == ExpenseStatus.Approved ||
                 e.Status == ExpenseStatus.Paid))
            .GroupBy(e => e.ConstructionSiteId)
            .Select(g => new
            {
                Site = g.Key,
                Total = g.Sum(e => e.Amount + e.TaxAmount)
            })
            .ToListAsync(cancellationToken);

        foreach (var e in expenses)
        {
            result.For(e.Site).Expenses += e.Total;
        }

        // Issued invoices (not Draft, not Cancelled).
        var invoices = await _dbContext.Invoices
            .AsNoTracking()
            .Where(i =>
                i.CompanyId == companyId &&
                !i.IsDeleted &&
                i.Status != InvoiceStatus.Cancelled &&
                i.Status != InvoiceStatus.Draft)
            .Select(i => new
            {
                i.Id,
                i.ConstructionSiteId,
                i.Type,
                i.TotalAmount
            })
            .ToListAsync(cancellationToken);

        // Completed payments are cash. Pending ones are only recorded.
        var payments = await _dbContext.Payments
            .AsNoTracking()
            .Where(p =>
                p.CompanyId == companyId &&
                !p.IsDeleted &&
                (p.Status == PaymentStatus.Completed ||
                 p.Status == PaymentStatus.Pending))
            .Select(p => new
            {
                p.Status,
                p.Direction,
                p.Amount,
                p.InvoiceId,
                InvoiceType = p.Invoice != null
                    ? (InvoiceType?)p.Invoice.Type
                    : null,
                Site = p.Invoice != null
                    ? p.Invoice.ConstructionSiteId
                    : p.ConstructionSiteId
            })
            .ToListAsync(cancellationToken);

        // Paid per invoice: completed payments linked to it, whatever their
        // Direction field says. This is exactly how PaymentService
        // recalculates an invoice's paid amount.
        var paidByInvoice = payments
            .Where(p =>
                p.Status == PaymentStatus.Completed &&
                p.InvoiceId.HasValue)
            .GroupBy(p => p.InvoiceId!.Value)
            .ToDictionary(g => g.Key, g => g.Sum(p => p.Amount));

        foreach (var invoice in invoices)
        {
            paidByInvoice.TryGetValue(invoice.Id, out var paid);

            var outstanding = Math.Max(0m, invoice.TotalAmount - paid);
            var raw = result.For(invoice.ConstructionSiteId);

            if (invoice.Type == InvoiceType.ClientInvoice)
            {
                raw.ClientInvoiced += invoice.TotalAmount;
                raw.ClientOutstanding += outstanding;
            }
            else if (invoice.Type == InvoiceType.VendorBill)
            {
                raw.VendorOutstanding += outstanding;
            }
        }

        foreach (var payment in payments)
        {
            // A payment on an invoice follows the invoice: a client invoice
            // is money in, a vendor bill is money out. This protects the
            // report from a payment saved with the wrong Direction.
            bool? isIncoming =
                payment.InvoiceType == InvoiceType.ClientInvoice ? true
                : payment.InvoiceType == InvoiceType.VendorBill ? false
                : payment.Direction == PaymentDirection.Incoming ? true
                : payment.Direction == PaymentDirection.Outgoing ? false
                : null;

            if (isIncoming is null)
            {
                continue;
            }

            var raw = result.For(payment.Site);

            if (payment.Status == PaymentStatus.Completed)
            {
                if (isIncoming.Value)
                {
                    raw.PaymentsIn += payment.Amount;
                }
                else
                {
                    raw.PaymentsOut += payment.Amount;
                }
            }
            else
            {
                if (isIncoming.Value)
                {
                    raw.PendingIn += payment.Amount;
                }
                else
                {
                    raw.PendingOut += payment.Amount;
                }
            }
        }

        // Petty cash, worked out per account so the figures always agree with
        // the balances. Only accounts of this company that are not deleted
        // are used, for the movement as well as the balance.
        var pettyMovement = await _dbContext.PettyCashTransactions
            .AsNoTracking()
            .Where(t =>
                t.PettyCashAccount.CompanyId == companyId &&
                !t.PettyCashAccount.IsDeleted &&
                !t.IsDeleted)
            .GroupBy(t => new
            {
                AccountId = t.PettyCashAccount.Id,
                t.TransactionType
            })
            .Select(g => new
            {
                g.Key.AccountId,
                Type = g.Key.TransactionType,
                Total = g.Sum(t => t.Amount)
            })
            .ToListAsync(cancellationToken);
        var movementByAccountAndType = pettyMovement.ToDictionary(
            movement => (movement.AccountId, movement.Type),
            movement => movement.Total);

        var pettyAccounts = await _dbContext.PettyCashAccounts
            .AsNoTracking()
            .Where(a => a.CompanyId == companyId && !a.IsDeleted)
            .Select(a => new
            {
                a.Id,
                a.ConstructionSiteId,
                a.CurrentBalance,
                a.IsActive
            })
            .ToListAsync(cancellationToken);

        foreach (var account in pettyAccounts)
        {
            var raw = result.For(account.ConstructionSiteId);

            movementByAccountAndType.TryGetValue(
                (account.Id, "CashIn"),
                out var cashIn);
            movementByAccountAndType.TryGetValue(
                (account.Id, "CashOut"),
                out var cashOut);

            // balance = opening + cash in - cash out, so the money an account
            // was opened with, which has no CashIn transaction, is
            //   opening = balance - cash in + cash out.
            // It is money that went into petty cash, so it counts as cash in.
            // A negative figure (balance below what the transactions allow) is
            // left unexplained and the report page warns about it.
            var opening = Math.Max(
                0m,
                account.CurrentBalance - cashIn + cashOut);

            raw.PettyIn += cashIn + opening;
            raw.PettyOut += cashOut;
            raw.PettyBalance += account.CurrentBalance;

            if (account.IsActive)
            {
                raw.PettyActive++;
            }
        }

        return result;
    }

    // ------------------------------------------------------------------
    // Access
    // ------------------------------------------------------------------

    private sealed record ReportContext(Guid CompanyId, Scope Scope);

    private async Task<ReportContext> GetReportContextAsync(
        Guid currentUserId,
        GranularPermission permission,
        CancellationToken cancellationToken)
    {
        var actor = await GetActorAsync(currentUserId, cancellationToken);
        EnsureHasPermission(actor, permission);

        var companyId = GetCompanyId(actor);
        var scope = await GetScopeAsync(actor, companyId, cancellationToken);

        return new ReportContext(companyId, scope);
    }

    private sealed class Scope
    {
        public bool All { get; init; }

        public HashSet<Guid> SiteIds { get; init; } = new();

        public bool Includes(Guid? siteId) =>
            All || (siteId.HasValue && SiteIds.Contains(siteId.Value));
    }

    // Same rule as the budget and expense services: company admins and
    // accountants see everything; a Site Manager with no site assignments
    // sees everything; everyone else only their assigned sites.
    private async Task<Scope> GetScopeAsync(
        User actor,
        Guid companyId,
        CancellationToken cancellationToken)
    {
        if (HasRole(actor, AppRoles.SuperAdmin) ||
            HasRole(actor, AppRoles.CompanyAdmin) ||
            HasRole(actor, AppRoles.Accountant))
        {
            return new Scope { All = true };
        }

        var siteIds = await _dbContext.UserSiteAccesses
            .AsNoTracking()
            .Where(x =>
                x.UserId == actor.Id &&
                x.CompanyId == companyId &&
                x.IsActive)
            .Select(x => x.SiteId)
            .ToListAsync(cancellationToken);

        if (siteIds.Count == 0 && HasRole(actor, AppRoles.SiteManager))
        {
            return new Scope { All = true };
        }

        return new Scope { SiteIds = siteIds.ToHashSet() };
    }

    private static void EnsureSiteInScope(Scope scope, Guid siteId)
    {
        if (!scope.Includes(siteId))
        {
            throw new ReportingManagementException(
                "You are not assigned to this construction site.");
        }
    }

    private async Task EnsureSiteExistsAsync(
        Guid companyId,
        Guid siteId,
        CancellationToken cancellationToken)
    {
        var exists = await _dbContext.ConstructionSites
            .AsNoTracking()
            .AnyAsync(
                s =>
                    s.Id == siteId &&
                    s.CompanyId == companyId &&
                    !s.IsDeleted,
                cancellationToken);

        if (!exists)
        {
            throw new ReportingManagementException(
                "Construction site was not found or does not belong to the current company.");
        }
    }

    private async Task<User> GetActorAsync(
        Guid currentUserId,
        CancellationToken cancellationToken)
    {
        return await _dbContext.Users
            .Include(x => x.UserRoles)
            .ThenInclude(x => x.Role)
            .ThenInclude(x => x.GranularPermissions)
            .SingleOrDefaultAsync(
                x => x.Id == currentUserId,
                cancellationToken)
            ?? throw new ReportingManagementException(
                "Authenticated user was not found.");
    }

    private static void EnsureHasPermission(
        User actor,
        GranularPermission permission)
    {
        if (HasPermission(actor, permission))
        {
            return;
        }

        throw new ReportingManagementException(
            "You are not authorized to view this report.");
    }

    private static bool HasPermission(
        User actor,
        GranularPermission permission)
    {
        return actor.UserRoles.Any(
            userRole =>
                !userRole.IsDeleted &&
                !userRole.Role.IsDeleted &&
                userRole.Role.GranularPermissions.Any(
                    rolePermission =>
                        rolePermission.Permission == permission));
    }

    private static Guid GetCompanyId(User actor)
    {
        if (!actor.CompanyId.HasValue)
        {
            throw new ReportingManagementException(
                "Current user is not assigned to a company.");
        }

        return actor.CompanyId.Value;
    }

    private static bool HasRole(
        User actor,
        string roleName)
    {
        return actor.UserRoles.Any(
            x =>
                !x.IsDeleted &&
                !x.Role.IsDeleted &&
                string.Equals(
                    x.Role.Name,
                    roleName,
                    StringComparison.OrdinalIgnoreCase));
    }
}
