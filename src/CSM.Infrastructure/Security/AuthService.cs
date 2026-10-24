using CSM.Application.Auth;
using CSM.Application.Auth.Dtos;
using CSM.Application.Common.Exceptions;
using CSM.Application.Common.Security;
using CSM.Domain.Entities.Identity;
using CSM.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace CSM.Infrastructure.Security;

public sealed class AuthService : IAuthService
{
    private const int MaxFailedLoginAttempts = 5;

    private static readonly TimeSpan LockoutDuration =
        TimeSpan.FromMinutes(15);

    private readonly ApplicationDbContext _dbContext;
    private readonly IPasswordHasher _passwordHasher;
    private readonly ITokenService _tokenService;
    private readonly JwtSettings _jwtSettings;

    public AuthService(
        ApplicationDbContext dbContext,
        IPasswordHasher passwordHasher,
        ITokenService tokenService,
        IOptions<JwtSettings> jwtOptions)
    {
        _dbContext = dbContext;
        _passwordHasher = passwordHasher;
        _tokenService = tokenService;
        _jwtSettings = jwtOptions.Value;
    }

    public async Task<AuthResponse> LoginAsync(
        LoginRequest request,
        string? ipAddress,
        CancellationToken cancellationToken = default)
    {
        var normalizedEmail = NormalizeEmail(request.Email);

        var user = await _dbContext.Users
            .Include(x => x.UserRoles)
                .ThenInclude(x => x.Role)
            .SingleOrDefaultAsync(
                x => x.NormalizedEmail == normalizedEmail,
                cancellationToken);

        if (user is null)
        {
            throw new AuthenticationException(
                "Invalid email or password.");
        }

        var utcNow = DateTime.UtcNow;

        if (!user.IsActive)
        {
            throw new AuthenticationException(
                "This account is inactive.");
        }

        if (user.LockedUntilUtc.HasValue &&
            user.LockedUntilUtc.Value > utcNow)
        {
            throw new AuthenticationException(
                "This account is temporarily locked.");
        }

        if (!_passwordHasher.Verify(
                request.Password,
                user.PasswordHash))
        {
            user.FailedLoginAttempts++;

            if (user.FailedLoginAttempts >= MaxFailedLoginAttempts)
            {
                user.LockedUntilUtc =
                    utcNow.Add(LockoutDuration);

                user.FailedLoginAttempts = 0;
            }

            _dbContext.LoginHistoryEntries.Add(
                new LoginHistoryEntry
                {
                    UserId = user.Id,
                    OccurredAtUtc = utcNow,
                    Succeeded = false,
                    IpAddress = ipAddress,
                    DeviceName = request.DeviceName,
                    FailureReason = "Invalid email or password."
                });

            await _dbContext.SaveChangesAsync(cancellationToken);

            throw new AuthenticationException(
                "Invalid email or password.");
        }

        user.FailedLoginAttempts = 0;
        user.LockedUntilUtc = null;
        user.LastLoginAtUtc = utcNow;

        var roles = GetRoles(user);

        var response = CreateTokenPair(
            user,
            roles,
            ipAddress,
            request.DeviceName,
            utcNow);

        await _dbContext.SaveChangesAsync(cancellationToken);

        return response;
    }

    public async Task<AuthResponse> RefreshAsync(
        RefreshTokenRequest request,
        string? ipAddress,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.RefreshToken))
        {
            throw new AuthenticationException(
                "Refresh token is required.");
        }

        var utcNow = DateTime.UtcNow;

        var tokenHash =
            _tokenService.HashRefreshToken(
                request.RefreshToken);

        var storedToken = await _dbContext.RefreshTokens
            .IgnoreQueryFilters()
            .Include(x => x.User)
                .ThenInclude(x => x.UserRoles)
                    .ThenInclude(x => x.Role)
            .SingleOrDefaultAsync(
                x => x.TokenHash == tokenHash,
                cancellationToken);

        if (storedToken is null ||
            storedToken.IsDeleted)
        {
            throw new AuthenticationException(
                "Invalid refresh token.");
        }

        if (storedToken.RevokedAtUtc.HasValue)
        {
            await RevokeActiveTokenFamilyAsync(
                storedToken.UserId,
                ipAddress,
                "Refresh token reuse detected.",
                utcNow,
                cancellationToken);

            throw new AuthenticationException(
                "Refresh token reuse detected. Please sign in again.");
        }

        if (storedToken.ExpiresAtUtc <= utcNow)
        {
            throw new AuthenticationException(
                "Refresh token has expired.");
        }

        var user = storedToken.User;

        if (!user.IsActive || user.IsDeleted)
        {
            throw new AuthenticationException(
                "This account is inactive.");
        }

        var roles = GetRoles(user);

        var rawRefreshToken =
            _tokenService.GenerateRefreshToken();

        var newTokenHash =
            _tokenService.HashRefreshToken(
                rawRefreshToken);

        storedToken.RevokedAtUtc = utcNow;
        storedToken.RevokedByIp = ipAddress;
        storedToken.RevocationReason =
            "Rotated during refresh.";
        storedToken.ReplacedByTokenHash =
            newTokenHash;

        var newRefreshToken = new RefreshToken
        {
            UserId = user.Id,
            TokenHash = newTokenHash,
            ExpiresAtUtc =
                utcNow.AddDays(
                    _jwtSettings.RefreshTokenDays),
            CreatedByIp = ipAddress,
            DeviceName = request.DeviceName
        };

        _dbContext.RefreshTokens.Add(newRefreshToken);

        var accessToken =
            _tokenService.GenerateAccessToken(
                user,
                roles);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return BuildResponse(
            user,
            roles,
            accessToken,
            rawRefreshToken,
            utcNow);
    }

    public async Task LogoutAsync(
        LogoutRequest request,
        string? ipAddress,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.RefreshToken))
        {
            return;
        }

        var tokenHash =
            _tokenService.HashRefreshToken(
                request.RefreshToken);

        var token = await _dbContext.RefreshTokens
            .SingleOrDefaultAsync(
                x => x.TokenHash == tokenHash,
                cancellationToken);

        if (token is null ||
            token.RevokedAtUtc.HasValue)
        {
            return;
        }

        token.RevokedAtUtc = DateTime.UtcNow;
        token.RevokedByIp = ipAddress;
        token.RevocationReason = "User logout.";

        await _dbContext.SaveChangesAsync(
            cancellationToken);
    }


public async Task<IReadOnlyList<UserSessionResponse>> GetSessionsAsync(
    Guid userId,
    string? currentRefreshToken,
    CancellationToken cancellationToken = default)
{
    var utcNow = DateTime.UtcNow;

    string? currentTokenHash = null;

    if (!string.IsNullOrWhiteSpace(currentRefreshToken))
    {
        currentTokenHash =
            _tokenService.HashRefreshToken(currentRefreshToken);
    }

    var sessions = await _dbContext.RefreshTokens
        .AsNoTracking()
        .Where(x =>
            x.UserId == userId &&
            !x.IsDeleted &&
            !x.RevokedAtUtc.HasValue &&
            x.ExpiresAtUtc > utcNow)
        .OrderByDescending(x => x.CreatedAtUtc)
        .Select(x => new UserSessionResponse(
            x.Id,
            x.DeviceName,
            x.CreatedByIp,
            x.CreatedAtUtc,
            x.ExpiresAtUtc,
            currentTokenHash != null &&
                x.TokenHash == currentTokenHash))
        .ToListAsync(cancellationToken);

    return sessions;
}



public async Task<bool> RevokeSessionAsync(
    Guid userId,
    Guid sessionId,
    string? ipAddress,
    string? currentRefreshToken,
    CancellationToken cancellationToken = default)
{
    var session = await _dbContext.RefreshTokens
        .SingleOrDefaultAsync(
            x => x.Id == sessionId &&
                 x.UserId == userId &&
                 !x.IsDeleted,
            cancellationToken);

    if (session is null || session.RevokedAtUtc.HasValue)
    {
        return false;
    }

    // Never revoke the refresh-token session used by this request.
    if (!string.IsNullOrWhiteSpace(currentRefreshToken))
    {
        var currentTokenHash =
            _tokenService.HashRefreshToken(currentRefreshToken);

        if (string.Equals(
                session.TokenHash,
                currentTokenHash,
                StringComparison.Ordinal))
        {
            return false;
        }
    }

    session.RevokedAtUtc = DateTime.UtcNow;
    session.RevokedByIp = ipAddress;
    session.RevocationReason = "Session revoked by user.";

    await _dbContext.SaveChangesAsync(cancellationToken);

    return true;
}


public async Task<int> RevokeOtherSessionsAsync(
    Guid userId,
    string? currentRefreshToken,
    string? ipAddress,
    CancellationToken cancellationToken = default)
{
    // Fail safely if the current refresh token is unavailable.
    if (string.IsNullOrWhiteSpace(currentRefreshToken))
    {
        return 0;
    }

    var currentTokenHash =
        _tokenService.HashRefreshToken(currentRefreshToken);

    var utcNow = DateTime.UtcNow;

    var activeSessions = await _dbContext.RefreshTokens
        .Where(x =>
            x.UserId == userId &&
            !x.IsDeleted &&
            !x.RevokedAtUtc.HasValue &&
            x.ExpiresAtUtc > utcNow)
        .ToListAsync(cancellationToken);

    // Do not revoke anything unless the current session is verified.
    var currentSessionExists = activeSessions.Any(x =>
        string.Equals(
            x.TokenHash,
            currentTokenHash,
            StringComparison.Ordinal));

    if (!currentSessionExists)
    {
        return 0;
    }

    var otherSessions = activeSessions
        .Where(x => !string.Equals(
            x.TokenHash,
            currentTokenHash,
            StringComparison.Ordinal))
        .ToList();

    foreach (var session in otherSessions)
    {
        session.RevokedAtUtc = utcNow;
        session.RevokedByIp = ipAddress;
        session.RevocationReason =
            "All other sessions revoked by user.";
    }

    if (otherSessions.Count > 0)
    {
        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    return otherSessions.Count;
}



    private AuthResponse CreateTokenPair(
        User user,
        IReadOnlyCollection<string> roles,
        string? ipAddress,
        string? deviceName,
        DateTime utcNow)
    {
        var accessToken =
            _tokenService.GenerateAccessToken(
                user,
                roles);

        var rawRefreshToken =
            _tokenService.GenerateRefreshToken();

        var refreshToken = new RefreshToken
        {
            UserId = user.Id,
            TokenHash =
                _tokenService.HashRefreshToken(
                    rawRefreshToken),

            ExpiresAtUtc =
                utcNow.AddDays(
                    _jwtSettings.RefreshTokenDays),

            CreatedByIp = ipAddress,
            DeviceName = deviceName
        };

        _dbContext.RefreshTokens.Add(refreshToken);
        _dbContext.LoginHistoryEntries.Add(
            new LoginHistoryEntry
            {
                UserId = user.Id,
                OccurredAtUtc = utcNow,
                Succeeded = true,
                IpAddress = ipAddress,
                DeviceName = deviceName
            });

        return BuildResponse(
            user,
            roles,
            accessToken,
            rawRefreshToken,
            utcNow);
    }

    private AuthResponse BuildResponse(
        User user,
        IReadOnlyCollection<string> roles,
        string accessToken,
        string refreshToken,
        DateTime utcNow)
    {
        return new AuthResponse(
            accessToken,
            refreshToken,
            utcNow.AddMinutes(
                _jwtSettings.AccessTokenMinutes),
            user.Id,
            user.CompanyId,
            user.EmployeeId,
            user.Email,
            $"{user.FirstName} {user.LastName}".Trim(),
            user.MustChangePassword,
            roles);
    }

    private async Task RevokeActiveTokenFamilyAsync(
        Guid userId,
        string? ipAddress,
        string reason,
        DateTime utcNow,
        CancellationToken cancellationToken)
    {
        var activeTokens =
            await _dbContext.RefreshTokens
                .Where(x =>
                    x.UserId == userId &&
                    x.RevokedAtUtc == null &&
                    x.ExpiresAtUtc > utcNow)
                .ToListAsync(cancellationToken);

        foreach (var token in activeTokens)
        {
            token.RevokedAtUtc = utcNow;
            token.RevokedByIp = ipAddress;
            token.RevocationReason = reason;
        }

        await _dbContext.SaveChangesAsync(
            cancellationToken);
    }

    private static IReadOnlyCollection<string> GetRoles(
        User user)
    {
        return user.UserRoles
            .Where(x =>
                !x.IsDeleted &&
                !x.Role.IsDeleted)
            .Select(x => x.Role.Name)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToArray();
    }

    private static string NormalizeEmail(string email)
    {
        if (string.IsNullOrWhiteSpace(email))
        {
            return string.Empty;
        }

        return email.Trim().ToUpperInvariant();
    }

    public async Task ChangePasswordAsync(
        Guid userId,
        ChangePasswordRequest request,
        string? ipAddress,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.CurrentPassword))
        {
            throw new AuthenticationException(
                "Current password is required.");
        }

        if (string.IsNullOrWhiteSpace(request.NewPassword))
        {
            throw new AuthenticationException(
                "New password is required.");
        }

        if (request.NewPassword != request.ConfirmNewPassword)
        {
            throw new AuthenticationException(
                "New password and confirmation do not match.");
        }

        ValidatePassword(request.NewPassword);

        var user = await _dbContext.Users
            .SingleOrDefaultAsync(
                x => x.Id == userId,
                cancellationToken);

        if (user is null || !user.IsActive)
        {
            throw new AuthenticationException(
                "User account was not found or is inactive.");
        }

        if (!_passwordHasher.Verify(
                request.CurrentPassword,
                user.PasswordHash))
        {
            throw new AuthenticationException(
                "Current password is incorrect.");
        }

        if (_passwordHasher.Verify(
                request.NewPassword,
                user.PasswordHash))
        {
            throw new AuthenticationException(
                "New password must be different from the current password.");
        }

        user.PasswordHash =
            _passwordHasher.Hash(request.NewPassword);

        user.MustChangePassword = false;
        user.FailedLoginAttempts = 0;
        user.LockedUntilUtc = null;

        var utcNow = DateTime.UtcNow;

        var activeTokens =
            await _dbContext.RefreshTokens
                .Where(x =>
                    x.UserId == user.Id &&
                    x.RevokedAtUtc == null &&
                    x.ExpiresAtUtc > utcNow)
                .ToListAsync(cancellationToken);

        foreach (var token in activeTokens)
        {
            token.RevokedAtUtc = utcNow;
            token.RevokedByIp = ipAddress;
            token.RevocationReason = "Password changed.";
        }

                        await _dbContext.SaveChangesAsync(
                            cancellationToken);
                    }

                    private static void ValidatePassword(string password)
                    {
                        if (password.Length != 6 ||
                            password.Any(ch => ch < '0' || ch > '9'))
                        {
                            throw new AuthenticationException(
                                "Password must be exactly 6 digits.");
                        }
                    }
                }