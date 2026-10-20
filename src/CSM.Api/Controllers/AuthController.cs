using System.Security.Claims;
using CSM.Application.Auth;
using CSM.Application.Auth.Dtos;
using CSM.Application.Common.Exceptions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using CSM.Infrastructure.Security;
using Microsoft.EntityFrameworkCore;
using CSM.Infrastructure.Persistence;

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