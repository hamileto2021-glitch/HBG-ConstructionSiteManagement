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
/// Every report is built from ONE calculation (LoadRawBySiteAsync), so the
/// dashboards, the company summary, the site summaries and the total always
/// agree, and the total is exactly company level + sites.
///
/// THE RULES
///
///  1. Budget    Approved, Active and Closed budgets.
///
///  2. Expenses  = expense records + paid payroll + petty cash out
///       expense records  Approved and Paid expenses, including tax.
///       paid payroll     COMPLETED payments linked to a payroll record.
///       petty cash out   Petty cash CashOut transactions.
///     Payments on vendor bills and other payments are NOT expenses.
///     Remaining = Budget - Expenses.      Used % = Expenses / Budget.
///
///  3. Invoices  Issued invoices only (not Draft, not Cancelled).
///     Invoiced               Client invoices.
///     Receivables / Payables Per invoice: total minus the COMPLETED payments
///                            on it (never below zero), then added up. This
///                            is the same sum PaymentService uses.
///
///  4. Petty cash   Opening + Cash In - Cash Out = Balance.
///     Cash In / Out are the recorded CashIn / CashOut transactions. Opening
///     is what an account was opened with (no transaction): balance - cash in
///     + cash out, never below zero.
///
///  Executive dashboard "Collected" = completed incoming client payments.
///
///  Where a record belongs
///     Every record belongs to its own site; no site = company level. A
///     payment on an invoice belongs to the invoice's site.
/// </summary>
public sealed class ReportingService : IReportingService
{
    private const string CompanyLevelKey = "";

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
        var actor = await GetActorAsync(currentUserId, cancellationToken);

        EnsureHasPermission(actor, GranularPermission.Reports_View);

        var companyId = GetCompanyId(actor);
        var scope = await GetScopeAsync(actor, companyId, cancellationToken);

        return await BuildDashboardAsync(
            companyId,
            scope,
            onlySiteId: null,
            cancellationToken);
    }

    public async Task<ExecutiveDashboardResponse>
        GetSiteExecutiveDashboardAsync(
            Guid currentUserId,
            Guid constructionSiteId,
            CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(currentUserId, cancellationToken);

        EnsureHasPermission(actor, GranularPermission.Reports_View);

        var companyId = GetCompanyId(actor);
        var scope = await GetScopeAsync(actor, companyId, cancellationToken);

        await EnsureSiteExistsAsync(
            companyId,
            constructionSiteId,
            cancellationToken);

        EnsureSiteInScope(scope, constructionSiteId);

        return await BuildDashboardAsync(
            companyId,
            scope,
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

        bool KeyInScope(string key)
        {
            if (onlySiteId.HasValue)
            {
                return key == onlySiteId.Value.ToString();
            }

            return key == CompanyLevelKey
                ? scope.All
                : scope.Includes(Guid.Parse(key));
        }

        var total = new Raw();

        foreach (var (key, raw) in rawBySite)
        {
            if (KeyInScope(key))
            {
                total.Add(raw);
            }
        }

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
            total.Spent,
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
        var actor = await GetActorAsync(currentUserId, cancellationToken);

        EnsureHasPermission(
            actor,
            GranularPermission.Reports_FinancialSummary_View);

        var companyId = GetCompanyId(actor);
        var scope = await GetScopeAsync(actor, companyId, cancellationToken);

        // Company-level figures are not tied to any site, so only users with
        // company-wide access may see them.
        if (!scope.All)
        {
            throw new ReportingManagementException(
                "You are not authorized to view company-level financial reports.");
        }

        var rawBySite = await LoadRawBySiteAsync(companyId, cancellationToken);

        var raw = rawBySite.GetValueOrDefault(CompanyLevelKey) ?? new Raw();

        return ToResponse(raw);
    }

    public async Task<FinancialSummaryResponse>
        GetSiteFinancialSummaryAsync(
            Guid currentUserId,
            Guid constructionSiteId,
            CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(currentUserId, cancellationToken);

        EnsureHasPermission(
            actor,
            GranularPermission.Reports_FinancialSummary_View);

        var companyId = GetCompanyId(actor);
        var scope = await GetScopeAsync(actor, companyId, cancellationToken);

        await EnsureSiteExistsAsync(
            companyId,
            constructionSiteId,
            cancellationToken);

        EnsureSiteInScope(scope, constructionSiteId);

        var rawBySite = await LoadRawBySiteAsync(companyId, cancellationToken);

        var raw = rawBySite.GetValueOrDefault(constructionSiteId.ToString())
                  ?? new Raw();

        return ToResponse(raw);
    }

    public async Task<AllFinancialSummaryResponse>
        GetAllFinancialSummariesAsync(
            Guid currentUserId,
            CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(currentUserId, cancellationToken);

        EnsureHasPermission(
            actor,
            GranularPermission.Reports_FinancialSummary_View);

        var companyId = GetCompanyId(actor);
        var scope = await GetScopeAsync(actor, companyId, cancellationToken);

        // One load feeds the company summary, every site and the total.
        var rawBySite = await LoadRawBySiteAsync(companyId, cancellationToken);

        var sites = (await _dbContext.ConstructionSites
                .AsNoTracking()
                .Where(s => s.CompanyId == companyId && !s.IsDeleted)
                .OrderBy(s => s.Name)
                .Select(s => new { s.Id, s.Name, s.SiteCode })
                .ToListAsync(cancellationToken))
            .Where(s => scope.Includes(s.Id))
            .ToList();

        // Company-level figures: company-wide users only; others see zeros.
        var companyRaw = scope.All
            ? rawBySite.GetValueOrDefault(CompanyLevelKey) ?? new Raw()
            : new Raw();

        var companySummary = ToResponse(companyRaw);

        var siteSummaries = new List<SiteFinancialSummaryResponse>();

        foreach (var site in sites)
        {
            var raw = rawBySite.GetValueOrDefault(site.Id.ToString())
                      ?? new Raw();

            siteSummaries.Add(
                new SiteFinancialSummaryResponse(
                    site.Id,
                    site.Name,
                    site.SiteCode,
                    ToResponse(raw)));
        }

        // The total is the sum of the same raw figures, so it always equals
        // company + sites (plus records of deleted sites, for company-wide
        // users). Ratios are recalculated from the sums, never added.
        var total = new Raw();

        foreach (var (key, raw) in rawBySite)
        {
            var inScope = key == CompanyLevelKey
                ? scope.All
                : scope.Includes(Guid.Parse(key));

            if (inScope)
            {
                total.Add(raw);
            }
        }

        var totalSummary = ToResponse(total);

        return new AllFinancialSummaryResponse(
            companySummary,
            siteSummaries,
            totalSummary);
    }

    // The only place the response is built. Named arguments, so a value can
    // never land in the wrong field.
    private static FinancialSummaryResponse ToResponse(Raw r)
    {
        return new FinancialSummaryResponse(
            TotalBudget: r.Budget,
            TotalExpenses: r.Spent,
            ExpenseRecords: r.Expenses,
            PayrollPaid: r.PayrollPaid,
            RemainingBudget: r.Budget - r.Spent,
            BudgetUsedPercent: r.Budget == 0m
                ? 0m
                : Math.Round(r.Spent / r.Budget * 100m, 2),
            TotalInvoiced: r.ClientInvoiced,
            OutstandingReceivables: r.ClientOutstanding,
            OutstandingPayables: r.VendorOutstanding,
            PettyCashOpeningBalance: r.PettyOpening,
            PettyCashIn: r.PettyIn,
            PettyCashOut: r.PettyOut,
            PettyCashBalance: r.PettyBalance,
            ActivePettyCashAccounts: r.PettyActive);
    }

    // ------------------------------------------------------------------
    // The shared calculation
    // ------------------------------------------------------------------

    private sealed class Raw
    {
        public decimal Budget;

        // Expenses
        public decimal Expenses;      // approved and paid expense records
        public decimal PayrollPaid;   // completed payroll payments
        public decimal PettyOut;      // petty cash out

        // Invoices
        public decimal ClientInvoiced;
        public decimal ClientOutstanding;
        public decimal VendorOutstanding;

        // Completed incoming client payments (executive "Collected")
        public decimal PaymentsIn;

        // Petty cash
        public decimal PettyOpening;
        public decimal PettyIn;
        public decimal PettyBalance;
        public int PettyActive;

        // All spending.
        public decimal Spent => Expenses + PayrollPaid + PettyOut;

        public void Add(Raw o)
        {
            Budget += o.Budget;
            Expenses += o.Expenses;
            PayrollPaid += o.PayrollPaid;
            PettyOut += o.PettyOut;
            ClientInvoiced += o.ClientInvoiced;
            ClientOutstanding += o.ClientOutstanding;
            VendorOutstanding += o.VendorOutstanding;
            PaymentsIn += o.PaymentsIn;
            PettyOpening += o.PettyOpening;
            PettyIn += o.PettyIn;
            PettyBalance += o.PettyBalance;
            PettyActive += o.PettyActive;
        }
    }

    // Key: "" for company-level records, otherwise the site id as text.
    private async Task<Dictionary<string, Raw>> LoadRawBySiteAsync(
        Guid companyId,
        CancellationToken cancellationToken)
    {
        var result = new Dictionary<string, Raw>();

        Raw For(Guid? siteId)
        {
            var key = siteId?.ToString() ?? CompanyLevelKey;

            if (!result.TryGetValue(key, out var raw))
            {
                raw = new Raw();
                result[key] = raw;
            }

            return raw;
        }

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
            For(b.Site).Budget += b.Total;
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
            For(e.Site).Expenses += e.Total;
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

        // Completed payments only. Pending, failed, cancelled and reversed
        // payments are not money that moved.
        var payments = await _dbContext.Payments
            .AsNoTracking()
            .Where(p =>
                p.CompanyId == companyId &&
                !p.IsDeleted &&
                p.Status == PaymentStatus.Completed)
            .Select(p => new
            {
                p.Direction,
                p.Amount,
                p.InvoiceId,
                p.PayrollRecordId,
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
            .Where(p => p.InvoiceId.HasValue)
            .GroupBy(p => p.InvoiceId!.Value)
            .ToDictionary(g => g.Key, g => g.Sum(p => p.Amount));

        foreach (var invoice in invoices)
        {
            paidByInvoice.TryGetValue(invoice.Id, out var paid);

            var outstanding = Math.Max(0m, invoice.TotalAmount - paid);
            var raw = For(invoice.ConstructionSiteId);

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
            var raw = For(payment.Site);

            // Payroll is money out and counts as an expense.
            if (payment.PayrollRecordId.HasValue)
            {
                raw.PayrollPaid += payment.Amount;
                continue;
            }

            // Money in: a client invoice payment, or an incoming payment that
            // is not on a vendor bill. Other payments out (vendor bills,
            // vendors) are not expenses and are not counted here.
            var isIncoming =
                payment.InvoiceType == InvoiceType.ClientInvoice ||
                (payment.InvoiceType != InvoiceType.VendorBill &&
                 payment.Direction == PaymentDirection.Incoming);

            if (isIncoming)
            {
                raw.PaymentsIn += payment.Amount;
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
            var raw = For(account.ConstructionSiteId);

            var cashIn = pettyMovement
                .Where(m => m.AccountId == account.Id && m.Type == "CashIn")
                .Sum(m => m.Total);

            var cashOut = pettyMovement
                .Where(m => m.AccountId == account.Id && m.Type == "CashOut")
                .Sum(m => m.Total);

            // balance = opening + cash in - cash out, so the money an account
            // was opened with, which has no CashIn transaction, is
            //   opening = balance - cash in + cash out.
            // It is shown as its own figure, never mixed into cash in. A
            // negative figure (balance below what the transactions allow) is
            // left unexplained and the report page warns about it.
            var opening = Math.Max(
                0m,
                account.CurrentBalance - cashIn + cashOut);

            raw.PettyOpening += opening;
            raw.PettyIn += cashIn;
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
