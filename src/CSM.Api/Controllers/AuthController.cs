using System.Security.Claims;
using CSM.Application.Auth;
using CSM.Application.Auth.Dtos;
using CSM.Application.Common.Exceptions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using CSM.Infrastructure.Security;
using Microsoft.EntityFrameworkCore;
using CSM.Infrastructure.Persistence;
using CSM.Application.Users.Dtos;

namespace CSM.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class AuthController : ControllerBase
{
    private readonly IAuthService _authService;

    private readonly IPermissionEvaluator _permissionEvaluator;

    private readonly ApplicationDbContext _dbContext;

    public AuthController(
        IAuthService authService,
        IPermissionEvaluator permissionEvaluator,
        ApplicationDbContext dbContext)
    {
        _authService = authService;
        _permissionEvaluator = permissionEvaluator;
        _dbContext = dbContext;
    }

    [AllowAnonymous]
    [HttpPost("login")]
    public async Task<ActionResult<AuthResponse>> Login(
        LoginRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var response =
                await _authService.LoginAsync(
                    request,
                    GetIpAddress(),
                    cancellationToken);

            return Ok(response);
        }
        catch (AuthenticationException ex)
        {
            return Unauthorized(new
            {
                message = ex.Message
            });
        }
    }

    [AllowAnonymous]
    [HttpPost("refresh")]
    public async Task<ActionResult<AuthResponse>> Refresh(
        RefreshTokenRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var response =
                await _authService.RefreshAsync(
                    request,
                    GetIpAddress(),
                    cancellationToken);

            return Ok(response);
        }
        catch (AuthenticationException ex)
        {
            return Unauthorized(new
            {
                message = ex.Message
            });
        }
    }

    [Authorize]
    [MustChangePasswordAllowed]
    [HttpPost("logout")]
    public async Task<IActionResult> Logout(
        LogoutRequest request,
        CancellationToken cancellationToken)
    {
        await _authService.LogoutAsync(
            request,
            GetIpAddress(),
            cancellationToken);

        return NoContent();
    }


[Authorize]
[HttpGet("sessions")]
public async Task<IActionResult> GetSessions(
    [FromHeader(Name = "X-Current-Refresh-Token")]
    string? currentRefreshToken,
    CancellationToken cancellationToken)
{
    var userIdValue =
        User.FindFirstValue(ClaimTypes.NameIdentifier);

    if (!Guid.TryParse(userIdValue, out var userId))
    {
        return Unauthorized(new
        {
            message = "Invalid authenticated user."
        });
    }

    var sessions = await _authService.GetSessionsAsync(
        userId,
        currentRefreshToken,
        cancellationToken);

    return Ok(sessions);
}

[Authorize]
[HttpGet("login-history")]
public async Task<IActionResult> GetLoginHistory(
    CancellationToken cancellationToken)
{
    var userIdValue =
        User.FindFirstValue(ClaimTypes.NameIdentifier);

    if (!Guid.TryParse(userIdValue, out var userId))
    {
        return Unauthorized(new
        {
            message = "Invalid authenticated user."
        });
    }

    var history = await _dbContext.LoginHistoryEntries
        .AsNoTracking()
        .Where(x => x.UserId == userId)
        .OrderByDescending(x => x.OccurredAtUtc)
        .Select(x => new
        {
            x.Id,
            x.OccurredAtUtc,
            x.Succeeded,
            x.IpAddress,
            x.DeviceName,
            x.FailureReason
        })
        .Take(100)
        .ToListAsync(cancellationToken);

    return Ok(history);
}

[Authorize]
[HttpDelete("sessions/{sessionId:guid}")]
public async Task<IActionResult> RevokeSession(
    Guid sessionId,
    [FromHeader(Name = "X-Current-Refresh-Token")]
    string? currentRefreshToken,
    CancellationToken cancellationToken)
{
    var userIdValue =
        User.FindFirstValue(ClaimTypes.NameIdentifier);

    if (!Guid.TryParse(userIdValue, out var userId))
    {
        return Unauthorized(new
        {
            message = "Invalid authenticated user."
        });
    }

    var revoked = await _authService.RevokeSessionAsync(
        userId,
        sessionId,
        GetIpAddress(),
        currentRefreshToken,
        cancellationToken);

    if (!revoked)
    {
        return NotFound(new
        {
            message = "Session not found, already revoked, or current session."
        });
    }

    return NoContent();
}


[Authorize]
[HttpPost("sessions/revoke-others")]
public async Task<IActionResult> RevokeOtherSessions(
    [FromHeader(Name = "X-Current-Refresh-Token")]
    string? currentRefreshToken,
    CancellationToken cancellationToken)
{
    var userIdValue =
        User.FindFirstValue(ClaimTypes.NameIdentifier);

    if (!Guid.TryParse(userIdValue, out var userId))
    {
        return Unauthorized(new
        {
            message = "Invalid authenticated user."
        });
    }

    if (string.IsNullOrWhiteSpace(currentRefreshToken))
    {
        return BadRequest(new
        {
            message = "Current refresh token is required."
        });
    }

    var revokedCount = await _authService.RevokeOtherSessionsAsync(
        userId,
        currentRefreshToken,
        GetIpAddress(),
        cancellationToken);

    if (revokedCount == 0)
    {
        return Conflict(new
        {
            message = "Current session could not be verified, or no other active sessions exist."
        });
    }

    return Ok(new
    {
        revokedCount,
        message = $"Revoked {revokedCount} other session(s)."
    });
}






[Authorize]
[HttpGet("me")]
public async Task<IActionResult> Me(
    CancellationToken cancellationToken)
{
    var userIdValue =
        User.FindFirstValue(ClaimTypes.NameIdentifier);

    var hasActiveSiteAccess = false;

    if (Guid.TryParse(userIdValue, out var userId))
    {
        hasActiveSiteAccess = await _dbContext.UserSiteAccesses
            .AsNoTracking()
            .AnyAsync(
                x => x.UserId == userId &&
                     x.IsActive &&
                     !x.IsDeleted,
                cancellationToken);
    }

    return Ok(new
    {
        userId = userIdValue,
        email = User.FindFirstValue(ClaimTypes.Email),
        name = User.Identity?.Name,
        companyId = User.FindFirst("company_id")?.Value,
        employeeId = User.FindFirst("employee_id")?.Value,
        roles = User.FindAll(ClaimTypes.Role)
            .Select(x => x.Value)
            .ToArray(),
        hasActiveSiteAccess
    });
}

[Authorize]
[HttpPut("me/profile")]
public async Task<IActionResult> UpdateMyProfile(
    UpdateMyProfileRequest request,
    CancellationToken cancellationToken)
{
    var userIdValue =
        User.FindFirstValue(ClaimTypes.NameIdentifier);

    if (!Guid.TryParse(userIdValue, out var userId))
    {
        return Unauthorized(new
        {
            message = "Invalid authenticated user."
        });
    }

    var firstName = request.FirstName?.Trim();
    var lastName = request.LastName?.Trim();
    var phoneNumber = request.PhoneNumber?.Trim() ?? string.Empty;
    var jobTitle = request.JobTitle?.Trim() ?? string.Empty;

    if (string.IsNullOrWhiteSpace(firstName) ||
        string.IsNullOrWhiteSpace(lastName))
    {
        return BadRequest(new
        {
            message = "First name and last name are required."
        });
    }

    if (firstName.Length > 100 ||
        lastName.Length > 100 ||
        phoneNumber.Length > 30 ||
        jobTitle.Length > 100)
    {
        return BadRequest(new
        {
            message = "One or more profile fields exceed the permitted length."
        });
    }

    var user = await _dbContext.Users
        .SingleOrDefaultAsync(
            x => x.Id == userId && !x.IsDeleted,
            cancellationToken);

    if (user is null)
    {
        return NotFound(new
        {
            message = "User account not found."
        });
    }

    user.FirstName = firstName;
    user.LastName = lastName;
    user.PhoneNumber = phoneNumber;
    user.JobTitle = jobTitle;

    await _dbContext.SaveChangesAsync(cancellationToken);

    return Ok(new
    {
        firstName = user.FirstName,
        lastName = user.LastName,
        phoneNumber = user.PhoneNumber,
        jobTitle = user.JobTitle
    });
}

[Authorize]
[HttpGet("me/profile")]
public async Task<IActionResult> GetMyProfileForEdit(
    CancellationToken cancellationToken)
{
    var userIdValue =
        User.FindFirstValue(ClaimTypes.NameIdentifier);

    if (!Guid.TryParse(userIdValue, out var userId))
    {
        return Unauthorized(new
        {
            message = "Invalid authenticated user."
        });
    }

    var profile = await _dbContext.Users
        .AsNoTracking()
        .Where(x => x.Id == userId && !x.IsDeleted)
        .Select(x => new
        {
            x.FirstName,
            x.LastName,
            x.PhoneNumber,
            x.JobTitle
        })
        .SingleOrDefaultAsync(cancellationToken);

    if (profile is null)
    {
        return NotFound(new
        {
            message = "User account not found."
        });
    }

    return Ok(profile);
}

[Authorize]
[HttpGet("organization-membership")]
public async Task<IActionResult> GetOrganizationMembership(
    CancellationToken cancellationToken)
{
    var userIdValue =
        User.FindFirstValue(ClaimTypes.NameIdentifier);

    if (!Guid.TryParse(userIdValue, out var userId))
    {
        return Unauthorized(new
        {
            message = "Invalid authenticated user."
        });
    }

    var memberships = await _dbContext.UserSiteAccesses
        .AsNoTracking()
        .Where(x =>
            x.UserId == userId &&
            x.IsActive &&
            !x.IsDeleted &&
            x.Site.IsActive &&
            !x.Site.IsDeleted)
        .OrderByDescending(x => x.IsDefault)
        .ThenBy(x => x.Site.Name)
        .Select(x => new
        {
            x.CompanyId,
            x.SiteId,
            SiteCode = x.Site.SiteCode,
            SiteName = x.Site.Name,
            x.Site.Address,
            x.Site.City,
            x.Site.Region,
            x.Site.Country,
            SiteStatus = x.Site.Status.ToString(),
            x.IsDefault
        })
        .ToListAsync(cancellationToken);

    return Ok(memberships);
}


    [Authorize]
    [HttpGet("permissions")]
    public async Task<IActionResult> Permissions(
        CancellationToken cancellationToken)
    {
        var userIdValue =
            User.FindFirstValue(
                ClaimTypes.NameIdentifier);

        if (!Guid.TryParse(userIdValue, out var userId))
        {
            return Unauthorized(new
            {
                message = "Invalid authenticated user."
            });
        }

        var permissions =
            await _permissionEvaluator.GetPermissionsAsync(
                userId,
                cancellationToken);

        return Ok(permissions);
    }

    [Authorize]
    [MustChangePasswordAllowed]
    [HttpPost("change-password")]
    public async Task<IActionResult> ChangePassword(
        ChangePasswordRequest request,
        CancellationToken cancellationToken)
    {
        var userIdValue =
            User.FindFirstValue(
                ClaimTypes.NameIdentifier);

        if (!Guid.TryParse(userIdValue, out var userId))
        {
            return Unauthorized(new
            {
                message = "Invalid authenticated user."
            });
        }

        try
        {
            await _authService.ChangePasswordAsync(
                userId,
                request,
                GetIpAddress(),
                cancellationToken);

            return Ok(new
            {
                message =
                    "Password changed successfully. Please sign in again."
            });
        }
        catch (AuthenticationException ex)
        {
            return BadRequest(new
            {
                message = ex.Message
            });
        }
    }

    private string? GetIpAddress()
    {
        return HttpContext.Connection
            .RemoteIpAddress?
            .ToString();
    }
}

[AttributeUsage(AttributeTargets.Method)]
internal sealed class MustChangePasswordAllowedAttribute : Attribute
{
}