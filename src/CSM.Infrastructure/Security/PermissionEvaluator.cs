
using CSM.Domain.Enums;
using CSM.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CSM.Infrastructure.Security;

public sealed class PermissionEvaluator : IPermissionEvaluator
{
    private readonly ApplicationDbContext _db;

    public PermissionEvaluator(ApplicationDbContext db)
    {
        _db = db;
    }

    public async Task<bool> HasPermissionAsync(
        Guid userId,
        string permission,
        CancellationToken cancellationToken = default)
    {
        if (!Enum.TryParse<GranularPermission>(
                permission,
                ignoreCase: true,
                out var parsedPermission))
        {
            return false;
        }

        return await _db.UserRoles
            .AsNoTracking()
            .AnyAsync(
                userRole =>
                    userRole.UserId == userId &&
                    !userRole.IsDeleted &&
                    !userRole.Role.IsDeleted &&
                    userRole.Role.GranularPermissions.Any(
                        rolePermission =>
                            rolePermission.Permission ==
                            parsedPermission),
                cancellationToken);
    }

    public async Task<IReadOnlyCollection<string>> GetPermissionsAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        return await _db.UserRoles
            .AsNoTracking()
            .Where(
                userRole =>
                    userRole.UserId == userId &&
                    !userRole.IsDeleted &&
                    !userRole.Role.IsDeleted)
            .SelectMany(
                userRole => userRole.Role.GranularPermissions)
            .Select(
                rolePermission =>
                    rolePermission.Permission.ToString())
            .Distinct()
            .OrderBy(permissionName => permissionName)
            .ToListAsync(cancellationToken);
    }
}
