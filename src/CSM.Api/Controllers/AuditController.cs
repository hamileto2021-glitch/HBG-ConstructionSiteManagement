
using System.Security.Claims;
using CSM.Application.Common.Audit;
using CSM.Infrastructure.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSM.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public sealed class AuditController : ControllerBase
{
    private readonly IAuditQueryService _service;
    private readonly IPermissionEvaluator _permissionEvaluator;

    public AuditController(
        IAuditQueryService service,
        IPermissionEvaluator permissionEvaluator)
    {
        _service = service;
        _permissionEvaluator = permissionEvaluator;
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyCollection<AuditLogDto>>> GetAll(
        [FromQuery] string? module,
        [FromQuery] DateTime? fromUtc,
        [FromQuery] DateTime? toUtc,
        CancellationToken cancellationToken)
    {
        var userIdValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!Guid.TryParse(userIdValue, out var userId))
        {
            return Unauthorized();
        }

        var companyIdValue = User.FindFirst("company_id")?.Value;
        if (!Guid.TryParse(companyIdValue, out var companyId))
        {
            return Forbid();
        }

        var hasPermission = await _permissionEvaluator.HasPermissionAsync(
            userId,
            "Audit_View",
            cancellationToken);

        if (!hasPermission)
        {
            return Forbid();
        }

        if (fromUtc.HasValue && toUtc.HasValue &&
            fromUtc.Value > toUtc.Value)
        {
            return BadRequest("fromUtc must be earlier than or equal to toUtc.");
        }

        var logs = await _service.GetLogsAsync(
            companyId,
            module,
            fromUtc,
            toUtc,
            cancellationToken);

        return Ok(logs);
    }
}
