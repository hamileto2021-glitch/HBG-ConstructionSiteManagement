using CSM.Application.Dashboard;
using CSM.Application.Dashboard.Dtos;
using CSM.Domain.Constants;
using CSM.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CSM.Infrastructure.Services;

public sealed class ExecutiveDashboardService
    : IExecutiveDashboardService
{
    private readonly ApplicationDbContext _context;

    public ExecutiveDashboardService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<ExecutiveDashboardResponse> GetAsync(
        Guid companyId,
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var actor = await _context.Users
            .AsNoTracking()
            .Include(x => x.UserRoles)
                .ThenInclude(x => x.Role)
            .SingleOrDefaultAsync(
                x => x.Id == userId,
                cancellationToken)
            ?? throw new InvalidOperationException(
                "The authenticated user was not found.");

        var isEmployee = actor.UserRoles.Any(x =>
            !x.IsDeleted &&
            !x.Role.IsDeleted &&
            string.Equals(
                x.Role.Name,
                AppRoles.Employee,
                StringComparison.OrdinalIgnoreCase));

        var isSuperAdmin = actor.UserRoles.Any(x =>
            !x.IsDeleted &&
            !x.Role.IsDeleted &&
            string.Equals(
                x.Role.Name,
                AppRoles.SuperAdmin,
                StringComparison.OrdinalIgnoreCase));

        List<Guid> authorizedSiteIds = isSuperAdmin
            ? []
            : await _context.UserSiteAccesses
                .AsNoTracking()
                .Where(x =>
                    x.UserId == userId &&
                    x.CompanyId == companyId &&
                    x.IsActive &&
                    !x.IsDeleted)
                .Select(x => x.SiteId)
                .Distinct()
                .ToListAsync(cancellationToken);
        var isSiteScoped = authorizedSiteIds.Count > 0;
        List<Guid> authorizedProjectIds = isSiteScoped
            ? await _context.Projects
                .AsNoTracking()
                .Where(x =>
                    x.CompanyId == companyId &&
                    authorizedSiteIds.Contains(x.ConstructionSiteId))
                .Select(x => x.Id)
                .ToListAsync(cancellationToken)
            : [];

        var activeProjects = await _context.Projects
            .CountAsync(x =>
                x.CompanyId == companyId &&
                x.Status != Domain.Enums.ProjectStatus.Completed &&
                (!isSiteScoped ||
                 authorizedSiteIds.Contains(x.ConstructionSiteId)),
                cancellationToken);

        var completedProjects = await _context.Projects
            .CountAsync(x =>
                x.CompanyId == companyId &&
                x.Status == Domain.Enums.ProjectStatus.Completed &&
                (!isSiteScoped ||
                 authorizedSiteIds.Contains(x.ConstructionSiteId)),
                cancellationToken);

        var totalBudget = await _context.Budgets
            .Where(x =>
                x.CompanyId == companyId &&
                (!isSiteScoped ||
                 (x.ConstructionSiteId.HasValue &&
                  authorizedSiteIds.Contains(x.ConstructionSiteId.Value)) ||
                 (x.ProjectId.HasValue &&
                  authorizedProjectIds.Contains(x.ProjectId.Value))))
            .SumAsync(x => (decimal?)x.TotalAmount ?? 0,
                cancellationToken);

        var totalExpenses = await _context.Expenses
            .Where(x =>
                x.CompanyId == companyId &&
                (!isSiteScoped ||
                 (x.ConstructionSiteId.HasValue &&
                  authorizedSiteIds.Contains(x.ConstructionSiteId.Value)) ||
                 (x.ProjectId.HasValue &&
                  authorizedProjectIds.Contains(x.ProjectId.Value))))
            .SumAsync(x => (decimal?)x.Amount ?? 0,
                cancellationToken);

        var budgetUtilization = totalBudget == 0
            ? 0
            : Math.Round((totalExpenses / totalBudget) * 100, 2);

        var openDelays = await _context.ProjectDelays
            .CountAsync(x =>
                x.CompanyId == companyId &&
                !x.IsResolved &&
                (!isSiteScoped ||
                 authorizedSiteIds.Contains(x.Project.ConstructionSiteId)),
                cancellationToken);

        int? totalEmployees = null;
        if (!isEmployee)
        {
            totalEmployees = isSiteScoped
                ? await _context.SiteAssignments
                    .Where(x =>
                        x.CompanyId == companyId &&
                        authorizedSiteIds.Contains(x.ConstructionSiteId) &&
                        x.StartDate <= DateOnly.FromDateTime(DateTime.UtcNow) &&
                        (!x.EndDate.HasValue ||
                         x.EndDate.Value >= DateOnly.FromDateTime(DateTime.UtcNow)))
                    .Select(x => x.EmployeeId)
                    .Distinct()
                    .CountAsync(cancellationToken)
                : await _context.Employees
                    .CountAsync(
                        x => x.CompanyId == companyId,
                        cancellationToken);
        }

        var lowStockItems = await _context.StockItems
            .CountAsync(x =>
                x.CompanyId == companyId &&
                x.QuantityOnHand <= x.ReorderLevel &&
                (!isSiteScoped ||
                 authorizedSiteIds.Contains(x.ConstructionSiteId)),
                cancellationToken);

        var openSafetyIncidents = await _context.SafetyIncidents
            .CountAsync(x =>
                x.CompanyId == companyId &&
                x.Status != Domain.Enums.SafetyIncidentStatus.Resolved &&
                (!isSiteScoped ||
                 authorizedSiteIds.Contains(x.ConstructionSiteId)),
                cancellationToken);

        return new ExecutiveDashboardResponse(
            activeProjects,
            completedProjects,
            totalBudget,
            totalExpenses,
            budgetUtilization,
            openDelays,
            totalEmployees,
            lowStockItems,
            openSafetyIncidents,
            DateTime.UtcNow);
    }
}