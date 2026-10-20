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
///   Invoiced      Client invoices that are not cancelled.
///   Outstanding   Per invoice: max(0, invoice total - completed payments
///                 linked to that invoice), then summed.
///   Payments      Completed payments. A payment belongs to its own site,
///                 or to its invoice's site when it has none.
///   Petty cash    Balance of all accounts; count of active accounts.
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

        return ToResponse(raw, raw.PettyBalance, raw.PettyActive);
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

        // Site reports have no company-level petty cash figures.
        return ToResponse(raw, 0m, 0);
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

        var companySummary = ToResponse(
            companyRaw,
            companyRaw.PettyBalance,
            companyRaw.PettyActive);

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
                    ToResponse(raw, 0m, 0)));
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
            companyPettyCashAccounts);   // 15 company petty cash accounts
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
            PettyIn += o.PettyIn;
            PettyOut += o.PettyOut;
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

        // Invoices and the payments applied to each one.
        var invoices = await _dbContext.Invoices
            .AsNoTracking()
            .Where(i =>
                i.CompanyId == companyId &&
                !i.IsDeleted &&
                i.Status != InvoiceStatus.Cancelled)
            .Select(i => new
            {
                i.Id,
                i.ConstructionSiteId,
                i.Type,
                i.TotalAmount
            })
            .ToListAsync(cancellationToken);

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
                InvoiceId = p.Invoice != null
                    ? (Guid?)p.Invoice.Id
                    : null,
                Site = p.ConstructionSiteId ??
                       (p.Invoice != null
                           ? p.Invoice.ConstructionSiteId
                           : null)
            })
            .ToListAsync(cancellationToken);

        var paidByInvoice = payments
            .Where(p => p.InvoiceId.HasValue)
            .GroupBy(p => (Invoice: p.InvoiceId!.Value, p.Direction))
            .ToDictionary(g => g.Key, g => g.Sum(p => p.Amount));

        foreach (var invoice in invoices)
        {
            var raw = For(invoice.ConstructionSiteId);

            if (invoice.Type == InvoiceType.ClientInvoice)
            {
                paidByInvoice.TryGetValue(
                    (invoice.Id, PaymentDirection.Incoming),
                    out var paid);

                raw.ClientInvoiced += invoice.TotalAmount;
                raw.ClientOutstanding +=
                    Math.Max(0m, invoice.TotalAmount - paid);
            }
            else if (invoice.Type == InvoiceType.VendorBill)
            {
                paidByInvoice.TryGetValue(
                    (invoice.Id, PaymentDirection.Outgoing),
                    out var paid);

                raw.VendorOutstanding +=
                    Math.Max(0m, invoice.TotalAmount - paid);
            }
        }

        foreach (var payment in payments)
        {
            var raw = For(payment.Site);

            if (payment.Direction == PaymentDirection.Incoming)
            {
                raw.PaymentsIn += payment.Amount;
            }
            else if (payment.Direction == PaymentDirection.Outgoing)
            {
                raw.PaymentsOut += payment.Amount;
            }
        }

        // Petty cash movement.
        var pettyMovement = await _dbContext.PettyCashTransactions
            .AsNoTracking()
            .Where(t =>
                t.PettyCashAccount.CompanyId == companyId &&
                !t.IsDeleted)
            .GroupBy(t => new
            {
                t.PettyCashAccount.ConstructionSiteId,
                t.TransactionType
            })
            .Select(g => new
            {
                Site = g.Key.ConstructionSiteId,
                Type = g.Key.TransactionType,
                Total = g.Sum(t => t.Amount)
            })
            .ToListAsync(cancellationToken);

        foreach (var m in pettyMovement)
        {
            var raw = For(m.Site);

            if (m.Type == "CashIn")
            {
                raw.PettyIn += m.Total;
            }
            else if (m.Type == "CashOut")
            {
                raw.PettyOut += m.Total;
            }
        }

        // Petty cash balances (all accounts) and active account counts.
        var pettyAccounts = await _dbContext.PettyCashAccounts
            .AsNoTracking()
            .Where(a => a.CompanyId == companyId && !a.IsDeleted)
            .GroupBy(a => a.ConstructionSiteId)
            .Select(g => new
            {
                Site = g.Key,
                Balance = g.Sum(a => a.CurrentBalance),
                Active = g.Count(a => a.IsActive)
            })
            .ToListAsync(cancellationToken);

        foreach (var a in pettyAccounts)
        {
            var raw = For(a.Site);

            raw.PettyBalance += a.Balance;
            raw.PettyActive += a.Active;
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
