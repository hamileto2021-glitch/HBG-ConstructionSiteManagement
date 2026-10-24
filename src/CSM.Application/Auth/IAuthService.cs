using CSM.Application.Auth.Dtos;

namespace CSM.Application.Auth;

public interface IAuthService
{
    Task<AuthResponse> LoginAsync(
        LoginRequest request,
        string? ipAddress,
        CancellationToken cancellationToken = default);

    Task<AuthResponse> RefreshAsync(
        RefreshTokenRequest request,
        string? ipAddress,
        CancellationToken cancellationToken = default);

    Task LogoutAsync(
        LogoutRequest request,
        string? ipAddress,
        CancellationToken cancellationToken = default);


Task<IReadOnlyList<UserSessionResponse>> GetSessionsAsync(
    Guid userId,
    string? currentRefreshToken,
    CancellationToken cancellationToken = default);


Task<bool> RevokeSessionAsync(
    Guid userId,
    Guid sessionId,
    string? ipAddress,
    string? currentRefreshToken,
    CancellationToken cancellationToken = default);


Task<int> RevokeOtherSessionsAsync(
    Guid userId,
    string? currentRefreshToken,
    string? ipAddress,
    CancellationToken cancellationToken = default);




    Task ChangePasswordAsync(
        Guid userId,
        ChangePasswordRequest request,
        string? ipAddress,
        CancellationToken cancellationToken = default);
}