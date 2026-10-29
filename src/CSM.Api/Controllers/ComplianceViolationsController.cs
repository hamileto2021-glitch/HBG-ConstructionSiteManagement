using CSM.Application.Common.Exceptions;
using CSM.Application.Compliance.Violations;
using CSM.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using CSM.Infrastructure.Persistence;

namespace CSM.Api.Controllers;

[ApiController]
[Authorize]
[Authorize(Policy = "Compliance.View")]
[Route("api/[controller]")]
public class ComplianceViolationsController : ControllerBase
{
    private readonly ComplianceViolationService _service;
    private readonly ApplicationDbContext _dbContext;

    public ComplianceViolationsController(
        ComplianceViolationService service,
        ApplicationDbContext dbContext)
    {
        _service = service;
        _dbContext = dbContext;
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<ViolationResponse>>> GetAll(
        CancellationToken cancellationToken)
    {
        var companyId = GetCurrentCompanyId();
        var siteIds = await ComplianceScopeResolver.GetAssignedSiteIdsAsync(
            _dbContext, GetCurrentUserId(), companyId,
            User.IsInRole(CSM.Domain.Constants.AppRoles.SuperAdmin), cancellationToken);
        var result = await _service.GetAllAsync(companyId, siteIds, cancellationToken);

        return Ok(result);
    }

    private Guid GetCurrentUserId() =>
        Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var userId)
            ? userId
            : throw new UnauthorizedAccessException("Authenticated user identifier is invalid.");

    private Guid GetCurrentCompanyId()
    {
        var value = User.FindFirst("company_id")?.Value;

        if (!Guid.TryParse(value, out var companyId))
        {
            throw new EquipmentManagementException(
                "Current company identity is invalid.");
        }

        return companyId;
    }
}
