using CSM.Web.Models.Auth;

namespace CSM.Web.Services;

public interface IAuthService
{
    Guid? CompanyId { get; }

    Task<Guid?> GetCurrentCompanyIdAsync();

    Task<LoginResponse?> LoginAsync(LoginRequest request);

    Task LogoutAsync();

    Task ApplyAuthenticationAsync(HttpClient httpClient);

    Task<string?> GetTokenAsync();

    Task<IReadOnlyCollection<string>> GetPermissionsAsync();

    Task<(string[] Roles, bool HasActiveSiteAccess)>
        GetCurrentUserScopeAsync();
}
