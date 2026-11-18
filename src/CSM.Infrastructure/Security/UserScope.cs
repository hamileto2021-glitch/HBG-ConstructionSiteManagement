using CSM.Domain.Constants;
using CSM.Domain.Entities.Identity;

namespace CSM.Infrastructure.Security;

public static class UserScope
{
    public static bool IsSuperAdmin(User user) =>
        HasRole(user, AppRoles.SuperAdmin);

    public static bool HasRole(User user, string roleName) =>
        user.UserRoles.Any(userRole =>
            !userRole.IsDeleted &&
            !userRole.Role.IsDeleted &&
            string.Equals(userRole.Role.Name, roleName,
                StringComparison.OrdinalIgnoreCase));

    public static bool CanAccessCompany(User user, Guid companyId) =>
        IsSuperAdmin(user) ||
        (user.CompanyId.HasValue && user.CompanyId.Value == companyId);

    public static Guid RequireCompanyId(User user, string companyMessage)
    {
        if (IsSuperAdmin(user))
            throw new InvalidOperationException(
                "A company must be selected for global operations.");

        if (!user.CompanyId.HasValue)
            throw new InvalidOperationException(companyMessage);

        return user.CompanyId.Value;
    }
}
