using CSM.Application.Compliance.Reports;
using CSM.Domain.Enums;
using CSM.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CSM.Infrastructure.Services;

public class ComplianceReportService
{
    private readonly ApplicationDbContext _db;

    public ComplianceReportService(ApplicationDbContext db)
    {
        _db = db;
    }

    public async Task<ComplianceSummaryReportResponse> GetSummaryAsync(
        Guid companyId,
        IReadOnlyCollection<Guid>? siteIds = null,
        CancellationToken cancellationToken = default)
    {
        var today = DateOnly.FromDateTime(DateTime.UtcNow);

        var inspections = await _db.Inspections
            .CountAsync(x => x.CompanyId == companyId &&
                             (siteIds == null || siteIds.Contains(x.ConstructionSiteId)), cancellationToken);

        var compliant = await _db.InspectionChecklistItems
            .CountAsync(x =>
                x.CompanyId == companyId &&
                (siteIds == null || (x.Inspection != null && siteIds.Contains(x.Inspection.ConstructionSiteId))) &&
                x.IsCompliant == true,
                cancellationToken);

        var nonCompliant = await _db.InspectionChecklistItems
            .CountAsync(x =>
                x.CompanyId == companyId &&
                (siteIds == null || (x.Inspection != null && siteIds.Contains(x.Inspection.ConstructionSiteId))) &&
                x.IsCompliant == false,
                cancellationToken);

        var corrective = await _db.InspectionChecklistItems
            .CountAsync(x =>
                x.CompanyId == companyId &&
                (siteIds == null || (x.Inspection != null && siteIds.Contains(x.Inspection.ConstructionSiteId))) &&
                x.IsCompliant == false &&
                !x.IsResolved,
                cancellationToken);

        var activePermits = await _db.Permits
            .CountAsync(x =>
                x.CompanyId == companyId &&
                (siteIds == null || siteIds.Contains(x.ConstructionSiteId)) &&
                x.Status == PermitStatus.Active,
                cancellationToken);

        var expiredPermits = await _db.Permits
            .CountAsync(x =>
                x.CompanyId == companyId &&
                (siteIds == null || siteIds.Contains(x.ConstructionSiteId)) &&
                x.ExpiryDate != null &&
                x.ExpiryDate < today,
                cancellationToken);

        var incidents = await _db.SafetyIncidents
            .CountAsync(x => x.CompanyId == companyId &&
                             (siteIds == null || siteIds.Contains(x.ConstructionSiteId)), cancellationToken);

        var observations = await _db.SafetyObservations
            .CountAsync(x => x.CompanyId == companyId &&
                             (siteIds == null || siteIds.Contains(x.ConstructionSiteId)), cancellationToken);

        return new ComplianceSummaryReportResponse(
            inspections,
            compliant,
            nonCompliant,
            corrective,
            activePermits,
            expiredPermits,
            incidents,
            observations);
    }
}
