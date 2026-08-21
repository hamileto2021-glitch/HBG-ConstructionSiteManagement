using System.Security.Claims;
using CSM.Application.Auth;
using CSM.Application.Auth.Dtos;
using CSM.Application.Common.Exceptions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSM.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class AuthController : ControllerBase
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService)
    {
        _authService = authService;
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
    public IActionResult Me()
    {
        return Ok(new
        {
            userId =
                User.FindFirstValue(
                    ClaimTypes.NameIdentifier),

            email =
                User.FindFirstValue(
                    ClaimTypes.Email),

            name = User.Identity?.Name,

            companyId =
                User.FindFirst("company_id")?.Value,

            employeeId =
                User.FindFirst("employee_id")?.Value,

            roles =
                User.FindAll(ClaimTypes.Role)
                    .Select(x => x.Value)
                    .ToArray()
        });
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