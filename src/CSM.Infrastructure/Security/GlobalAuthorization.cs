using CSM.Domain.Constants;
using CSM.Domain.Entities.Identity;

namespace CSM.Infrastructure.Security;

public static class GlobalAuthorization
{
    public static bool IsSuperAdmin(User user)
    {
        return user.UserRoles.Any(userRole =>
            !userRole.IsDeleted &&
            !userRole.Role.IsDeleted &&
            string.Equals(
                userRole.Role.Name,
                AppRoles.SuperAdmin,
                StringComparison.OrdinalIgnoreCase));
    }

    public static bool HasRole(User user, string roleName)
    {
        return user.UserRoles.Any(userRole =>
            !userRole.IsDeleted &&
            !userRole.Role.IsDeleted &&
            string.Equals(
                userRole.Role.Name,
                roleName,
                StringComparison.OrdinalIgnoreCase));
    }

    public static Guid? GetCompanyId(User user)
    {
        return user.CompanyId;
    }

    public static bool CanAccessCompany(User user, Guid companyId)
    {
        return IsSuperAdmin(user) ||
               (user.CompanyId.HasValue && user.CompanyId.Value == companyId);
    }
}
