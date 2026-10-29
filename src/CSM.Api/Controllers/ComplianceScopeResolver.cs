using CSM.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CSM.Api.Controllers;

internal static class ComplianceScopeResolver
{
    public static async Task<List<Guid>?> GetAssignedSiteIdsAsync(
        ApplicationDbContext dbContext,
        Guid userId,
        Guid companyId,
        bool isSuperAdmin,
        CancellationToken cancellationToken)
    {
        if (isSuperAdmin) return null;

        var siteIds = await dbContext.UserSiteAccesses
            .AsNoTracking()
            .Where(access => access.UserId == userId &&
                             access.CompanyId == companyId &&
                             access.IsActive &&
                             !access.IsDeleted)
            .Select(access => access.SiteId)
            .Distinct()
            .ToListAsync(cancellationToken);

        return siteIds.Count == 0 ? null : siteIds;
    }
}
