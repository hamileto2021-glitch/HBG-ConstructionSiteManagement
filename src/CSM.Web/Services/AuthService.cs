using System.Net.Http.Headers;
using System.Net.Http.Json;
using CSM.Web.Models.Auth;
using Microsoft.AspNetCore.Components.Server.ProtectedBrowserStorage;

namespace CSM.Web.Services;

public class AuthService : IAuthService
{
    private readonly IHttpClientFactory _factory;
    private readonly ProtectedSessionStorage _sessionStorage;

    private sealed class CurrentUserResponse
    {
        public string? CompanyId { get; set; }
    }


private sealed class CurrentUserScopeResponse
{
    public string? UserId { get; set; }
    public string? Email { get; set; }
    public string? Name { get; set; }
    public string[] Roles { get; set; } = [];
    public bool HasActiveSiteAccess { get; set; }
}


    private IReadOnlyCollection<string>? _permissions;
    private Guid? _companyId;

    public Guid? CompanyId => _companyId;

    public AuthService(
        IHttpClientFactory factory,
        ProtectedSessionStorage sessionStorage)
    {
        _factory = factory;
        _sessionStorage = sessionStorage;
    }

    public async Task<LoginResponse?> LoginAsync(LoginRequest request)
    {
        var client = _factory.CreateClient("CSM.Api");

        var response = await client.PostAsJsonAsync("auth/login", request);

        if (!response.IsSuccessStatusCode)
            return null;

        var result = await response.Content.ReadFromJsonAsync<LoginResponse>();

        if (result is not null &&
            !string.IsNullOrWhiteSpace(result.AccessToken))
        {
            await _sessionStorage.SetAsync("jwt", result.AccessToken);
            await _sessionStorage.SetAsync("refreshToken", result.RefreshToken);
            _companyId = result.CompanyId;
            _permissions = null;
        }

        return result;
    }

    public async Task<string?> GetRefreshTokenAsync()
    {
        var token = await _sessionStorage.GetAsync<string>("refreshToken");

        if (!token.Success || string.IsNullOrWhiteSpace(token.Value))
            return null;

        return token.Value;
    }

    public async Task LogoutAsync()
    {
        // Best-effort: tell the API this token is no longer valid so it can
        // be revoked server-side. If this fails (offline, server down,
        // token already expired), we still clear local state below —
        // the user must not stay "signed in" locally just because the
        // API call didn't succeed.
        try
        {
            var client = _factory.CreateClient("CSM.Api");
            await ApplyAuthenticationAsync(client);
            await client.PostAsync("auth/logout", content: null);
        }
        catch
        {
            // Ignored — local sign-out below still proceeds.
        }
        finally
        {
            await _sessionStorage.DeleteAsync("jwt");
            await _sessionStorage.DeleteAsync("refreshToken");
            _permissions = null;
            _companyId = null;
        }
    }

    // NEW METHOD
    public async Task<string?> GetTokenAsync()
    {
        var token = await _sessionStorage.GetAsync<string>("jwt");

        if (!token.Success || string.IsNullOrWhiteSpace(token.Value))
            return null;

        return token.Value;
    }

    public async Task<IReadOnlyCollection<string>> GetPermissionsAsync()
    {
        if (_permissions is not null)
            return _permissions;

        if (string.IsNullOrWhiteSpace(await GetTokenAsync()))
            return Array.Empty<string>();

        var client = _factory.CreateClient("CSM.Api");

        await ApplyAuthenticationAsync(client);

        var response =
            await client.GetAsync("auth/permissions");

        if (!response.IsSuccessStatusCode)
        {
            return Array.Empty<string>();
        }

        var permissions =
            await response.Content
                .ReadFromJsonAsync<List<string>>();

        _permissions = permissions ?? [];

        return _permissions;
    }

    public async Task ApplyAuthenticationAsync(HttpClient httpClient)
    {
        var token = await GetTokenAsync();

        httpClient.DefaultRequestHeaders.Authorization = null;

        if (!string.IsNullOrWhiteSpace(token))
        {
            httpClient.DefaultRequestHeaders.Authorization =
                new AuthenticationHeaderValue("Bearer", token);
        }
    }

    public async Task<string?> GetCurrentUserIdAsync()
    {
        if (string.IsNullOrWhiteSpace(await GetTokenAsync()))
            return null;

        var client = _factory.CreateClient("CSM.Api");

        await ApplyAuthenticationAsync(client);

        var response = await client.GetAsync("auth/me");

        if (!response.IsSuccessStatusCode)
            return null;

        var result = await response.Content
            .ReadFromJsonAsync<CurrentUserScopeResponse>();

        return result?.UserId;
    }

    public async Task<Guid?> GetCurrentCompanyIdAsync()
    {
        if (string.IsNullOrWhiteSpace(await GetTokenAsync()))
            return null;

        var client = _factory.CreateClient("CSM.Api");

        await ApplyAuthenticationAsync(client);

        var response = await client.GetAsync("auth/me");

        if (!response.IsSuccessStatusCode)
            return null;

        var result =
            await response.Content.ReadFromJsonAsync<CurrentUserResponse>();

        if (result is null ||
            !Guid.TryParse(result.CompanyId, out var companyId))
        {
            return null;
        }

        return companyId;
    }


public async Task<(string[] Roles, bool HasActiveSiteAccess)>
    GetCurrentUserScopeAsync()
{
    if (string.IsNullOrWhiteSpace(await GetTokenAsync()))
        throw new HttpRequestException("No authenticated session is available.");

    var client = _factory.CreateClient("CSM.Api");
    await ApplyAuthenticationAsync(client);

    var response = await client.GetAsync("auth/me");

    if (!response.IsSuccessStatusCode)
        throw new HttpRequestException(
            $"Could not load current user scope: {(int)response.StatusCode}");

    var result = await response.Content
        .ReadFromJsonAsync<CurrentUserScopeResponse>();

    if (result is null)
        throw new InvalidOperationException(
            "The current user scope response was empty.");

    return (result.Roles, result.HasActiveSiteAccess);
}


}
