using System.Security.Claims;
using CSM.Application.Common.Exceptions;
using CSM.Application.Compliance.Reports;
using CSM.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using CSM.Infrastructure.Persistence;

namespace CSM.Api.Controllers;

[ApiController]
[Authorize]
[Authorize(Policy = "Compliance.View")]
[Route("api/[controller]")]
public class ComplianceReportsController : ControllerBase
{
    private readonly ComplianceReportService _service;
    private readonly ApplicationDbContext _dbContext;

    public ComplianceReportsController(ComplianceReportService service, ApplicationDbContext dbContext)
    {
        _service = service;
        _dbContext = dbContext;
    }

    [HttpGet("summary")]
    public async Task<ActionResult<ComplianceSummaryReportResponse>> Summary(
        CancellationToken cancellationToken)
    {
        var companyId = GetCurrentCompanyId();
        var siteIds = await ComplianceScopeResolver.GetAssignedSiteIdsAsync(
            _dbContext, GetCurrentUserId(), companyId,
            User.IsInRole(CSM.Domain.Constants.AppRoles.SuperAdmin), cancellationToken);
        var result = await _service.GetSummaryAsync(companyId, siteIds, cancellationToken);

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
