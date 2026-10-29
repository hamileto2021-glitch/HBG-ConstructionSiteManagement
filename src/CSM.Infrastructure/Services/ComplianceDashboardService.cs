using CSM.Application.Compliance.Dashboard;
using CSM.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using CSM.Domain.Enums;

namespace CSM.Infrastructure.Services;

public class ComplianceDashboardService
{
    private readonly ApplicationDbContext _dbContext;

    public ComplianceDashboardService(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ComplianceDashboardResponse> GetAsync(
        Guid companyId,
        IReadOnlyCollection<Guid>? siteIds = null,
        CancellationToken cancellationToken = default)
    {
        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        var expiry = today.AddDays(30);

        var inspections = await _dbContext.Inspections
            .CountAsync(x => x.CompanyId == companyId &&
                             (siteIds == null || siteIds.Contains(x.ConstructionSiteId)), cancellationToken);

        // Existing model uses IsResolved instead of Status enum
        var corrective = await _dbContext.InspectionChecklistItems
            .CountAsync(x =>
                x.CompanyId == companyId &&
                (siteIds == null || (x.Inspection != null && siteIds.Contains(x.Inspection.ConstructionSiteId))) &&
                !x.IsResolved,
                cancellationToken);

        // Active permits
        var permits = await _dbContext.Permits
            .CountAsync(x =>
                x.CompanyId == companyId &&
                (siteIds == null || siteIds.Contains(x.ConstructionSiteId)) &&
                x.Status == PermitStatus.Active,
                cancellationToken);

        // Permits expiring within 30 days
        var expiring = await _dbContext.Permits
            .CountAsync(x =>
                x.CompanyId == companyId &&
                (siteIds == null || siteIds.Contains(x.ConstructionSiteId)) &&
                x.Status == PermitStatus.Active &&
                x.ExpiryDate != null &&
                x.ExpiryDate >= today &&
                x.ExpiryDate <= expiry,
                cancellationToken);

        // Open NCRs
        var ncrs = await _dbContext.NonConformanceReports
            .CountAsync(x =>
                x.CompanyId == companyId &&
                (siteIds == null || siteIds.Contains(x.ConstructionSiteId)) &&
                x.Status != NcrStatus.Closed,
                cancellationToken);

        var incidents = await _dbContext.SafetyIncidents
            .CountAsync(x => x.CompanyId == companyId &&
                             (siteIds == null || siteIds.Contains(x.ConstructionSiteId)), cancellationToken);

        var observations = await _dbContext.SafetyObservations
            .CountAsync(x => x.CompanyId == companyId &&
                             (siteIds == null || siteIds.Contains(x.ConstructionSiteId)), cancellationToken);

        return new ComplianceDashboardResponse(
            inspections,
            corrective,
            permits,
            expiring,
            ncrs,
            incidents,
            observations);
    }
}
