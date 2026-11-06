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
///       paid payroll     Payroll that has been paid, by either route:
///                          - completed payments linked to the payroll record
///                          - or, when the payroll was only marked as paid and
///                            has no completed payment, its net pay.
///                        Never both for the same record. A payment that has
///                        its own site keeps it; otherwise the amount is split
///                        across the sites the employee was assigned to during
///                        the pay period, by days. Days with no assignment go
///                        to company level.
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

    public async Task<ManagementReportsResponse> GetManagementReportsAsync(
        Guid currentUserId,
        Guid? constructionSiteId,
        CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(currentUserId, cancellationToken);
        EnsureHasPermission(actor, GranularPermission.Reports_View);

        var companyId = GetCompanyId(actor);
        var scope = await GetScopeAsync(actor, companyId, cancellationToken);
        if (HasRole(actor, AppRoles.Accountant))
        {
            var assignedSiteIds = await _dbContext.UserSiteAccesses
                .AsNoTracking()
                .Where(x =>
                    x.UserId == actor.Id &&
                    x.CompanyId == companyId &&
                    x.IsActive &&
                    !x.IsDeleted)
                .Select(x => x.SiteId)
                .Distinct()
                .ToArrayAsync(cancellationToken);

            if (assignedSiteIds.Length > 0)
            {
                scope = new Scope
                {
                    SiteIds = assignedSiteIds.ToHashSet()
                };
            }
        }

        if (constructionSiteId.HasValue)
        {
            await EnsureSiteExistsAsync(
                companyId,
                constructionSiteId.Value,
                cancellationToken);
            EnsureSiteInScope(scope, constructionSiteId.Value);
        }

        var sites = constructionSiteId.HasValue
            ? new[] { constructionSiteId.Value }
            : scope.SiteIds.ToArray();
        var siteScoped = constructionSiteId.HasValue || !scope.All;

        return new ManagementReportsResponse(
            HasPermission(actor, GranularPermission.Projects_View)
                ? await BuildProjectProgressReportAsync(
                    companyId,
                    sites,
                    siteScoped,
                    cancellationToken)
                : null,
            CanViewSiteOperations(actor)
                ? await BuildSiteOperationsReportAsync(
                    companyId,
                    sites,
                    siteScoped,
                    actor,
                    cancellationToken)
                : null,
            CanViewHrReports(actor)
                ? await BuildHrReportAsync(
                    companyId,
                    sites,
                    siteScoped,
                    actor,
                    cancellationToken)
                : null,
            CanViewProcurementReports(actor)
                ? await BuildProcurementReportAsync(
                    companyId,
                    sites,
                    siteScoped,
                    actor,
                    cancellationToken)
                : null,
            HasPermission(actor, GranularPermission.Compliance_View)
                ? await BuildSafetyComplianceReportAsync(
                    companyId,
                    sites,
                    siteScoped,
                    cancellationToken)
                : null);
    }

    private async Task<ManagementReportSectionResponse>
        BuildProjectProgressReportAsync(
            Guid companyId,
            Guid[] sites,
            bool siteScoped,
            CancellationToken cancellationToken)
    {
        var projects = _dbContext.Projects
            .AsNoTracking()
            .Where(x => x.CompanyId == companyId && !x.IsDeleted);
        if (siteScoped)
        {
            projects = projects.Where(x => sites.Contains(x.ConstructionSiteId));
        }

        var projectRows = await projects
            .Select(x => new
            {
                x.Id,
                x.Status,
                x.ProgressPercentage,
                x.PlannedEndDate
            })
            .ToListAsync(cancellationToken);
        var projectIds = projectRows.Select(x => x.Id).ToArray();
        var today = DateOnly.FromDateTime(DateTime.UtcNow);

        var metrics = new List<ManagementReportMetricResponse>
        {
            Metric("Projects", projectRows.Count),
            Metric(
                "Average progress",
                projectRows.Count == 0
                    ? 0m
                    : projectRows.Average(x => x.ProgressPercentage),
                "percent"),
            Metric(
                "Overdue projects",
                projectRows.Count(x =>
                    x.PlannedEndDate < today &&
                    x.Status is not (ProjectStatus.Completed or
                        ProjectStatus.Closed or ProjectStatus.Cancelled)),
                hint: "Past planned end date and not completed")
        };
        var statuses = new List<ManagementReportStatusResponse>();

        AddStatusCounts(
            statuses,
            "Projects",
            projectRows.Select(x => x.Status));

        var phases = _dbContext.ProjectPhases
            .AsNoTracking()
            .Where(x => x.CompanyId == companyId &&
                        !x.IsDeleted &&
                        projectIds.Contains(x.ProjectId));
        await AddStatusCountsAsync(
            statuses,
            "Phases",
            phases.Select(x => x.Status),
            cancellationToken);

        var milestones = _dbContext.Milestones
            .AsNoTracking()
            .Where(x => x.CompanyId == companyId &&
                        !x.IsDeleted &&
                        projectIds.Contains(x.ProjectId));
        await AddStatusCountsAsync(
            statuses,
            "Milestones",
            milestones.Select(x => x.Status),
            cancellationToken);
        metrics.Add(Metric(
            "Overdue milestones",
            await milestones.CountAsync(
                x => x.PlannedDate < today &&
                     x.Status != MilestoneStatus.Completed,
                cancellationToken),
            hint: "Past planned date and not completed"));

        var tasks = _dbContext.WorkTasks
            .AsNoTracking()
            .Where(x => x.CompanyId == companyId &&
                        !x.IsDeleted &&
                        projectIds.Contains(x.ProjectId));
        await AddStatusCountsAsync(
            statuses,
            "Tasks",
            tasks.Select(x => x.Status),
            cancellationToken);
        metrics.Add(Metric(
            "Overdue tasks",
            await tasks.CountAsync(
                x => x.PlannedEndDate < today &&
                     x.Status != WorkTaskStatus.Completed &&
                     x.Status != WorkTaskStatus.Cancelled,
                cancellationToken),
            hint: "Past planned end date and not completed"));

        var delays = _dbContext.ProjectDelays
            .AsNoTracking()
            .Where(x => x.CompanyId == companyId &&
                        !x.IsDeleted &&
                        projectIds.Contains(x.ProjectId));
        var openDelayDays = await delays
            .Where(x => !x.IsResolved)
            .SumAsync(x => (int?)x.DelayDays, cancellationToken) ?? 0;
        metrics.Add(Metric(
            "Open delays",
            await delays.CountAsync(x => !x.IsResolved, cancellationToken)));
        metrics.Add(Metric("Open delay days", openDelayDays, "days"));

        return new ManagementReportSectionResponse(metrics, statuses);
    }

    private async Task<ManagementReportSectionResponse>
        BuildSiteOperationsReportAsync(
            Guid companyId,
            Guid[] sites,
            bool siteScoped,
            User actor,
            CancellationToken cancellationToken)
    {
        var metrics = new List<ManagementReportMetricResponse>();
        var statuses = new List<ManagementReportStatusResponse>();
        var fromDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(-30));

        if (HasPermission(actor, GranularPermission.Sites_View))
        {
            var sitesQuery = _dbContext.ConstructionSites
                .AsNoTracking()
                .Where(x => x.CompanyId == companyId && !x.IsDeleted);
            if (siteScoped)
            {
                sitesQuery = sitesQuery.Where(x => sites.Contains(x.Id));
            }

            var siteRows = await sitesQuery
                .Select(x => x.IsActive)
                .ToListAsync(cancellationToken);
            metrics.Add(Metric("Construction sites", siteRows.Count));
            metrics.Add(Metric("Active sites", siteRows.Count(x => x)));
        }

        if (HasPermission(actor, GranularPermission.Projects_View))
        {
            var projects = _dbContext.Projects
                .AsNoTracking()
                .Where(x => x.CompanyId == companyId && !x.IsDeleted);
            if (siteScoped)
            {
                projects = projects.Where(
                    x => sites.Contains(x.ConstructionSiteId));
            }

            metrics.Add(Metric(
                "Active projects",
                await projects.CountAsync(
                    x => x.Status == ProjectStatus.Active,
                    cancellationToken)));
        }

        if (HasPermission(actor, GranularPermission.Projects_DailyProgress_View))
        {
            var diaries = _dbContext.DailySiteDiaries
                .AsNoTracking()
                .Where(x => x.CompanyId == companyId &&
                            !x.IsDeleted &&
                            x.DiaryDate >= fromDate);
            if (siteScoped)
            {
                diaries = diaries.Where(x => sites.Contains(x.SiteId));
            }

            var diaryRows = await diaries
                .Select(x => new { x.WorkforceCount, x.DelayReason })
                .ToListAsync(cancellationToken);
            metrics.Add(Metric("Daily diaries (30 days)", diaryRows.Count));
            metrics.Add(Metric(
                "Average daily workforce",
                diaryRows.Count == 0
                    ? 0m
                    : diaryRows.Average(x => (decimal)x.WorkforceCount)));
            metrics.Add(Metric(
                "Diaries reporting delays",
                diaryRows.Count(x => !string.IsNullOrWhiteSpace(x.DelayReason))));
        }

        if (HasPermission(actor, GranularPermission.Equipment_View))
        {
            var assignments = _dbContext.EquipmentAssignments
                .AsNoTracking()
                .Where(x => x.CompanyId == companyId &&
                            !x.IsDeleted &&
                            !x.ReleasedAtUtc.HasValue);
            if (siteScoped)
            {
                assignments = assignments.Where(
                    x => sites.Contains(x.ConstructionSiteId));
            }

            metrics.Add(Metric(
                "Equipment currently assigned",
                await assignments.Select(x => x.EquipmentId)
                    .Distinct()
                    .CountAsync(cancellationToken)));
        }

        if (HasPermission(actor, GranularPermission.Procurement_Inventory_View))
        {
            var usage = _dbContext.DailyMaterialUsages
                .AsNoTracking()
                .Where(x => x.CompanyId == companyId &&
                            !x.IsDeleted &&
                            x.Date >= fromDate);
            var stock = _dbContext.StockItems
                .AsNoTracking()
                .Where(x => x.CompanyId == companyId && !x.IsDeleted);
            if (siteScoped)
            {
                usage = usage.Where(x => sites.Contains(x.ConstructionSiteId));
                stock = stock.Where(x => sites.Contains(x.ConstructionSiteId));
            }

            var usageRows = await usage
                .Select(x => new
                {
                    x.Unit,
                    x.QuantityIssued,
                    x.QuantityUsed,
                    x.QuantityReturned,
                    x.QuantityVariance
                })
                .ToListAsync(cancellationToken);
            foreach (var group in usageRows.GroupBy(x => x.Unit))
            {
                metrics.Add(Metric(
                    $"Issued ({group.Key}) - 30 days",
                    group.Sum(x => x.QuantityIssued),
                    "quantity"));
                metrics.Add(Metric(
                    $"Used ({group.Key}) - 30 days",
                    group.Sum(x => x.QuantityUsed),
                    "quantity"));
                metrics.Add(Metric(
                    $"Returned ({group.Key}) - 30 days",
                    group.Sum(x => x.QuantityReturned),
                    "quantity"));
                metrics.Add(Metric(
                    $"Variance ({group.Key}) - 30 days",
                    group.Sum(x => x.QuantityVariance),
                    "quantity"));
            }
            metrics.Add(Metric(
                "Low-stock items",
                await stock.CountAsync(
                    x => x.QuantityOnHand <= x.ReorderLevel,
                    cancellationToken)));
        }

        return new ManagementReportSectionResponse(metrics, statuses);
    }

    private async Task<ManagementReportSectionResponse>
        BuildHrReportAsync(
            Guid companyId,
            Guid[] sites,
            bool siteScoped,
            User actor,
            CancellationToken cancellationToken)
    {
        var metrics = new List<ManagementReportMetricResponse>();
        var statuses = new List<ManagementReportStatusResponse>();
        var employees = _dbContext.Employees
            .AsNoTracking()
            .Where(x => x.CompanyId == companyId && !x.IsDeleted);
        var siteEmployeeIds = _dbContext.SiteAssignments
            .AsNoTracking()
            .Where(x => x.CompanyId == companyId &&
                        !x.IsDeleted &&
                        (!siteScoped || sites.Contains(x.ConstructionSiteId)))
            .Select(x => x.EmployeeId)
            .Distinct();

        if (HasPermission(actor, GranularPermission.HRM_SiteAssignment_View))
        {
            var assignments = _dbContext.SiteAssignments
                .AsNoTracking()
                .Where(x =>
                    x.CompanyId == companyId &&
                    !x.IsDeleted &&
                    x.StartDate <= DateOnly.FromDateTime(DateTime.UtcNow) &&
                    (!x.EndDate.HasValue ||
                     x.EndDate >= DateOnly.FromDateTime(DateTime.UtcNow)));
            if (siteScoped)
            {
                assignments = assignments.Where(
                    x => sites.Contains(x.ConstructionSiteId));
            }

            metrics.Add(Metric(
                "Current site assignments",
                await assignments.CountAsync(cancellationToken)));
        }

        if (siteScoped)
        {
            employees = employees.Where(
                x => siteEmployeeIds.Contains(x.Id));
        }

        var employeeIds = await employees
            .Select(x => x.Id)
            .ToArrayAsync(cancellationToken);

        if (HasPermission(actor, GranularPermission.HRM_Employee_View))
        {
            metrics.Add(Metric(
                "Employees",
                await employees.CountAsync(cancellationToken)));
            await AddStatusCountsAsync(
                statuses,
                "Employees",
                employees.Select(x => x.Status),
                cancellationToken);
        }

        if (!siteScoped &&
            HasPermission(actor, GranularPermission.HRM_Contractor_View))
        {
            metrics.Add(Metric(
                "Active contractors",
                await _dbContext.Contractors
                    .CountAsync(
                        x => x.CompanyId == companyId &&
                             !x.IsDeleted &&
                             x.IsActive,
                        cancellationToken)));
        }

        if (!siteScoped &&
            HasPermission(actor, GranularPermission.HRM_Shift_View))
        {
            metrics.Add(Metric(
                "Active shifts",
                await _dbContext.Shifts
                    .CountAsync(
                        x => x.CompanyId == companyId &&
                             !x.IsDeleted &&
                             x.IsActive,
                        cancellationToken)));
        }

        var fromDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(-30));
        if (HasPermission(actor, GranularPermission.HRM_Attendance_View))
        {
            var attendance = _dbContext.Attendances
                .AsNoTracking()
                .Where(x => x.CompanyId == companyId &&
                            !x.IsDeleted &&
                            x.AttendanceDate >= fromDate);
            if (siteScoped)
            {
                attendance = attendance.Where(
                    x => sites.Contains(x.ConstructionSiteId));
            }

            var rows = await attendance
                .Select(x => new { x.Status, x.RegularHours, x.OvertimeHours })
                .ToListAsync(cancellationToken);
            metrics.Add(Metric("Attendance records (30 days)", rows.Count));
            metrics.Add(Metric(
                "Regular hours (30 days)",
                rows.Sum(x => x.RegularHours),
                "hours"));
            metrics.Add(Metric(
                "Overtime hours (30 days)",
                rows.Sum(x => x.OvertimeHours),
                "hours"));
            AddStatusCounts(statuses, "Attendance (30 days)", rows.Select(x => x.Status));
        }

        if (HasPermission(actor, GranularPermission.HRM_Timesheet_View))
        {
            var timesheets = _dbContext.Timesheets
                .AsNoTracking()
                .Where(x => x.CompanyId == companyId &&
                            !x.IsDeleted &&
                            employeeIds.Contains(x.EmployeeId));
            metrics.Add(Metric(
                "Timesheets",
                await timesheets.CountAsync(cancellationToken)));
            metrics.Add(Metric(
                "Timesheet hours",
                await timesheets.SumAsync(
                    x => (decimal?)x.TotalHours,
                    cancellationToken) ?? 0m,
                "hours"));
            await AddStatusCountsAsync(
                statuses,
                "Timesheets",
                timesheets.Select(x => x.Status),
                cancellationToken);
        }

        if (HasPermission(actor, GranularPermission.HRM_Leave_View))
        {
            var leaveRequests = _dbContext.LeaveRequests
                .AsNoTracking()
                .Where(x => x.CompanyId == companyId &&
                            !x.IsDeleted &&
                            employeeIds.Contains(x.EmployeeId));
            metrics.Add(Metric(
                "Leave requests",
                await leaveRequests.CountAsync(cancellationToken)));
            await AddStatusCountsAsync(
                statuses,
                "Leave requests",
                leaveRequests.Select(x => x.Status),
                cancellationToken);
        }

        if (HasPermission(actor, GranularPermission.HRM_Payroll_View))
        {
            var payrollRecords = _dbContext.PayrollRecords
                .AsNoTracking()
                .Where(x => x.CompanyId == companyId &&
                            !x.IsDeleted &&
                            employeeIds.Contains(x.EmployeeId));
            metrics.Add(Metric(
                "Payroll records",
                await payrollRecords.CountAsync(cancellationToken)));
            await AddStatusCountsAsync(
                statuses,
                "Payroll",
                payrollRecords.Select(x => x.Status),
                cancellationToken);
        }

        return new ManagementReportSectionResponse(metrics, statuses);
    }

    private async Task<ManagementReportSectionResponse>
        BuildProcurementReportAsync(
            Guid companyId,
            Guid[] sites,
            bool siteScoped,
            User actor,
            CancellationToken cancellationToken)
    {
        var metrics = new List<ManagementReportMetricResponse>();
        var statuses = new List<ManagementReportStatusResponse>();

        if (HasPermission(actor, GranularPermission.Procurement_MaterialRequest_View))
        {
            var requests = _dbContext.MaterialRequests
                .AsNoTracking()
                .Where(x => x.CompanyId == companyId && !x.IsDeleted);
            if (siteScoped)
            {
                requests = requests.Where(
                    x => sites.Contains(x.ConstructionSiteId));
            }

            metrics.Add(Metric(
                "Material requests",
                await requests.CountAsync(cancellationToken)));
            await AddStatusCountsAsync(
                statuses,
                "Material requests",
                requests.Select(x => x.Status),
                cancellationToken);
        }

        if (HasPermission(actor, GranularPermission.Procurement_PurchaseOrder_View))
        {
            var orders = _dbContext.PurchaseOrders
                .AsNoTracking()
                .Where(x => x.CompanyId == companyId && !x.IsDeleted);
            var receipts = _dbContext.GoodsReceipts
                .AsNoTracking()
                .Where(x => x.CompanyId == companyId && !x.IsDeleted);
            if (siteScoped)
            {
                orders = orders.Where(
                    x => sites.Contains(x.ConstructionSiteId));
                receipts = receipts.Where(
                    x => sites.Contains(x.ConstructionSiteId));
            }

            metrics.Add(Metric(
                "Purchase orders",
                await orders.CountAsync(cancellationToken)));
            await AddStatusCountsAsync(
                statuses,
                "Purchase orders",
                orders.Select(x => x.Status),
                cancellationToken);
            metrics.Add(Metric(
                "Goods receipts",
                await receipts.CountAsync(cancellationToken)));
        }

        if (HasPermission(actor, GranularPermission.Procurement_Vendor_View))
        {
            var vendorIds = _dbContext.PurchaseOrders
                .AsNoTracking()
                .Where(x => x.CompanyId == companyId && !x.IsDeleted);
            if (siteScoped)
            {
                vendorIds = vendorIds.Where(
                    x => sites.Contains(x.ConstructionSiteId));
            }

            metrics.Add(Metric(
                "Suppliers used",
                await vendorIds.Select(x => x.VendorId)
                    .Distinct()
                    .CountAsync(cancellationToken),
                hint: "Suppliers referenced by purchase orders in this scope"));
        }

        if (HasPermission(actor, GranularPermission.Procurement_Inventory_View))
        {
            var stock = _dbContext.StockItems
                .AsNoTracking()
                .Where(x => x.CompanyId == companyId && !x.IsDeleted);
            if (siteScoped)
            {
                stock = stock.Where(
                    x => sites.Contains(x.ConstructionSiteId));
            }

            metrics.Add(Metric(
                "Stock lines",
                await stock.CountAsync(cancellationToken)));
            metrics.Add(Metric(
                "Materials in stock",
                await stock.Select(x => x.MaterialId)
                    .Distinct()
                    .CountAsync(cancellationToken)));
            metrics.Add(Metric(
                "Low-stock items",
                await stock.CountAsync(
                    x => x.QuantityOnHand <= x.ReorderLevel,
                    cancellationToken)));
        }

        return new ManagementReportSectionResponse(metrics, statuses);
    }

    private async Task<ManagementReportSectionResponse>
        BuildSafetyComplianceReportAsync(
            Guid companyId,
            Guid[] sites,
            bool siteScoped,
            CancellationToken cancellationToken)
    {
        var metrics = new List<ManagementReportMetricResponse>();
        var statuses = new List<ManagementReportStatusResponse>();
        var incidents = _dbContext.SafetyIncidents
            .AsNoTracking()
            .Where(x => x.CompanyId == companyId && !x.IsDeleted);
        var observations = _dbContext.SafetyObservations
            .AsNoTracking()
            .Where(x => x.CompanyId == companyId && !x.IsDeleted);
        var inspections = _dbContext.Inspections
            .AsNoTracking()
            .Where(x => x.CompanyId == companyId && !x.IsDeleted);
        var permits = _dbContext.Permits
            .AsNoTracking()
            .Where(x => x.CompanyId == companyId && !x.IsDeleted);
        var ncrs = _dbContext.NonConformanceReports
            .AsNoTracking()
            .Where(x => x.CompanyId == companyId && !x.IsDeleted);
        if (siteScoped)
        {
            incidents = incidents.Where(x => sites.Contains(x.ConstructionSiteId));
            observations = observations.Where(x => sites.Contains(x.ConstructionSiteId));
            inspections = inspections.Where(x => sites.Contains(x.ConstructionSiteId));
            permits = permits.Where(x => sites.Contains(x.ConstructionSiteId));
            ncrs = ncrs.Where(x => sites.Contains(x.ConstructionSiteId));
        }

        metrics.Add(Metric(
            "Safety incidents",
            await incidents.CountAsync(cancellationToken)));
        await AddStatusCountsAsync(
            statuses,
            "Incidents",
            incidents.Select(x => x.Status),
            cancellationToken);
        await AddStatusCountsAsync(
            statuses,
            "Incident severity",
            incidents.Select(x => x.Severity),
            cancellationToken);
        metrics.Add(Metric(
            "Lost-time incidents",
            await incidents.CountAsync(x => x.LostTimeIncident, cancellationToken)));

        metrics.Add(Metric(
            "Safety observations",
            await observations.CountAsync(cancellationToken)));
        await AddStatusCountsAsync(
            statuses,
            "Observations",
            observations.Select(x => x.Status),
            cancellationToken);

        metrics.Add(Metric(
            "Inspections",
            await inspections.CountAsync(cancellationToken)));
        await AddStatusCountsAsync(
            statuses,
            "Inspections",
            inspections.Select(x => x.Status),
            cancellationToken);

        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        metrics.Add(Metric(
            "Permits",
            await permits.CountAsync(cancellationToken)));
        metrics.Add(Metric(
            "Expired permits",
            await permits.CountAsync(
                x => x.ExpiryDate < today &&
                     x.Status != PermitStatus.Revoked &&
                     x.Status != PermitStatus.Closed,
                cancellationToken)));
        await AddStatusCountsAsync(
            statuses,
            "Permits",
            permits.Select(x => x.Status),
            cancellationToken);

        metrics.Add(Metric(
            "Non-conformance reports",
            await ncrs.CountAsync(cancellationToken)));
        metrics.Add(Metric(
            "Overdue corrective actions",
            await ncrs.CountAsync(
                x => x.DueDate < DateTime.UtcNow &&
                     x.Status != NcrStatus.Closed,
                cancellationToken)));
        await AddStatusCountsAsync(
            statuses,
            "Non-conformance",
            ncrs.Select(x => x.Status),
            cancellationToken);

        return new ManagementReportSectionResponse(metrics, statuses);
    }

    private static bool CanViewSiteOperations(User actor) =>
        HasPermission(actor, GranularPermission.Sites_View) ||
        HasPermission(actor, GranularPermission.Projects_View) ||
        HasPermission(actor, GranularPermission.Projects_DailyProgress_View) ||
        HasPermission(actor, GranularPermission.Equipment_View) ||
        HasPermission(actor, GranularPermission.Procurement_Inventory_View);

    private static bool CanViewHrReports(User actor) =>
        HasPermission(actor, GranularPermission.HRM_Employee_View) ||
        HasPermission(actor, GranularPermission.HRM_Contractor_View) ||
        HasPermission(actor, GranularPermission.HRM_Shift_View) ||
        HasPermission(actor, GranularPermission.HRM_Payroll_View) ||
        HasPermission(actor, GranularPermission.HRM_SiteAssignment_View) ||
        HasPermission(actor, GranularPermission.HRM_Attendance_View) ||
        HasPermission(actor, GranularPermission.HRM_Leave_View) ||
        HasPermission(actor, GranularPermission.HRM_Timesheet_View);

    private static bool CanViewProcurementReports(User actor) =>
        HasPermission(actor, GranularPermission.Procurement_MaterialRequest_View) ||
        HasPermission(actor, GranularPermission.Procurement_PurchaseOrder_View) ||
        HasPermission(actor, GranularPermission.Procurement_Inventory_View) ||
        HasPermission(actor, GranularPermission.Procurement_Vendor_View);

    private static ManagementReportMetricResponse Metric(
        string label,
        decimal value,
        string unit = "count",
        string? hint = null) =>
        new(label, value, unit, hint);

    private static async Task AddStatusCountsAsync<TStatus>(
        ICollection<ManagementReportStatusResponse> target,
        string category,
        IQueryable<TStatus> statuses,
        CancellationToken cancellationToken)
        where TStatus : struct, Enum
    {
        var groupedStatuses = await statuses
            .GroupBy(x => x)
            .Select(group => new
            {
                Status = group.Key,
                Count = group.Count()
            })
            .ToListAsync(cancellationToken);

        foreach (var group in groupedStatuses)
        {
            target.Add(new ManagementReportStatusResponse(
                category,
                group.Status.ToString(),
                group.Count));
        }
    }

    private static void AddStatusCounts<TStatus>(
        ICollection<ManagementReportStatusResponse> target,
        string category,
        IEnumerable<TStatus> statuses)
        where TStatus : struct, Enum
    {
        foreach (var group in statuses.GroupBy(x => x).OrderBy(x => x.Key))
        {
            target.Add(new ManagementReportStatusResponse(
                category,
                group.Key.ToString(),
                group.Count()));
        }
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

    private sealed record PayrollRow(
        Guid Id,
        Guid EmployeeId,
        DateOnly PeriodStart,
        DateOnly PeriodEnd,
        PayrollStatus Status,
        decimal NetPay);

    private sealed record AssignmentRow(
        Guid EmployeeId,
        Guid SiteId,
        DateOnly Start,
        DateOnly? End);

    // Splits an amount across the sites an employee was assigned to during the
    // pay period, by days. A day with two sites is shared equally; a day with
    // none goes to company level (a null site). The parts always add up to the
    // amount: the last part takes any rounding difference.
    private static List<(Guid? Site, decimal Amount)> AllocateByAssignment(
        decimal amount,
        PayrollRow record,
        List<AssignmentRow> assignments)
    {
        var totalDays = record.PeriodEnd.DayNumber - record.PeriodStart.DayNumber + 1;

        if (totalDays <= 0)
        {
            return new List<(Guid? Site, decimal Amount)> { (null, amount) };
        }

        var weights = new Dictionary<Guid, decimal>();
        var unassigned = 0m;

        for (var day = record.PeriodStart; day <= record.PeriodEnd; day = day.AddDays(1))
        {
            var sites = assignments
                .Where(a => a.Start <= day && (!a.End.HasValue || a.End.Value >= day))
                .Select(a => a.SiteId)
                .Distinct()
                .ToList();

            if (sites.Count == 0)
            {
                unassigned += 1m;
                continue;
            }

            foreach (var site in sites)
            {
                weights[site] = weights.GetValueOrDefault(site) + 1m / sites.Count;
            }
        }

        var parts = weights
            .Select(w => ((Guid?)w.Key, w.Value))
            .ToList();

        if (unassigned > 0m)
        {
            parts.Add(((Guid?)null, unassigned));
        }

        var result = new List<(Guid? Site, decimal Amount)>();
        var allocated = 0m;

        for (var i = 0; i < parts.Count; i++)
        {
            var share = i == parts.Count - 1
                ? amount - allocated
                : Math.Round(amount * parts[i].Item2 / totalDays, 2);

            allocated += share;
            result.Add((parts[i].Item1, share));
        }

        return result;
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

            // Payroll payments are handled below, with the payroll records.
            if (payment.PayrollRecordId.HasValue)
            {
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

        // Paid payroll. Two routes make payroll "paid": a completed payment
        // linked to the record, or the record being marked as paid with no
        // payment. Each record is counted once.
        var payrollPayments = payments
            .Where(p => p.PayrollRecordId.HasValue)
            .ToList();

        var recordsWithPayment = payrollPayments
            .Select(p => p.PayrollRecordId!.Value)
            .ToHashSet();

        var payrollRecords = (await _dbContext.PayrollRecords
                .AsNoTracking()
                .Where(r =>
                    r.CompanyId == companyId &&
                    !r.IsDeleted &&
                    (r.Status == PayrollStatus.Paid ||
                     recordsWithPayment.Contains(r.Id)))
                .Select(r => new PayrollRow(
                    r.Id,
                    r.EmployeeId,
                    r.PeriodStart,
                    r.PeriodEnd,
                    r.Status,
                    r.NetPay))
                .ToListAsync(cancellationToken))
            .ToDictionary(r => r.Id);

        var payrollEmployeeIds = payrollRecords.Values
            .Select(r => r.EmployeeId)
            .Distinct()
            .ToList();

        var assignmentsByEmployee = (await _dbContext.SiteAssignments
                .AsNoTracking()
                .Where(a =>
                    a.CompanyId == companyId &&
                    payrollEmployeeIds.Contains(a.EmployeeId))
                .Select(a => new AssignmentRow(
                    a.EmployeeId,
                    a.ConstructionSiteId,
                    a.StartDate,
                    a.EndDate))
                .ToListAsync(cancellationToken))
            .GroupBy(a => a.EmployeeId)
            .ToDictionary(g => g.Key, g => g.ToList());

        List<AssignmentRow> AssignmentsOf(Guid employeeId) =>
            assignmentsByEmployee.TryGetValue(employeeId, out var list)
                ? list
                : new List<AssignmentRow>();

        // Route 1: completed payments linked to a payroll record.
        foreach (var payment in payrollPayments)
        {
            // A payment that has its own site keeps it.
            if (payment.Site.HasValue ||
                !payrollRecords.TryGetValue(
                    payment.PayrollRecordId!.Value,
                    out var record))
            {
                For(payment.Site).PayrollPaid += payment.Amount;
                continue;
            }

            foreach (var (site, amount) in AllocateByAssignment(
                         payment.Amount,
                         record,
                         AssignmentsOf(record.EmployeeId)))
            {
                For(site).PayrollPaid += amount;
            }
        }

        // Route 2: marked as paid, with no completed payment.
        foreach (var record in payrollRecords.Values.Where(r =>
                     r.Status == PayrollStatus.Paid &&
                     !recordsWithPayment.Contains(r.Id)))
        {
            foreach (var (site, amount) in AllocateByAssignment(
                         record.NetPay,
                         record,
                         AssignmentsOf(record.EmployeeId)))
            {
                For(site).PayrollPaid += amount;
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
