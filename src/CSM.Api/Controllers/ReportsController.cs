using System.Security.Claims;
using CSM.Application.Common.Exceptions;
using CSM.Application.Common.Security;
using CSM.Application.Reporting;
using CSM.Application.Reporting.Dtos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSM.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = AppPolicies.ProjectManagement)]
public sealed class ReportsController : ControllerBase
{
    private readonly IReportingService _reportingService;

    public ReportsController(
        IReportingService reportingService)
    {
        _reportingService = reportingService;
    }

    [HttpGet("executive-dashboard")]
    public async Task<ActionResult<ExecutiveDashboardResponse>> GetExecutiveDashboard(
        CancellationToken cancellationToken)
    {
        try
        {
            var result =
                await _reportingService.GetExecutiveDashboardAsync(
                    GetCurrentUserId(),
                    cancellationToken);

            return Ok(result);
        }
        catch (ReportingManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("financial-summary")]
    public async Task<ActionResult<FinancialSummaryResponse>> GetFinancialSummary(
        CancellationToken cancellationToken)
    {
        try
        {
            var result =
                await _reportingService.GetFinancialSummaryAsync(
                    GetCurrentUserId(),
                    cancellationToken);

            return Ok(result);
        }
        catch (ReportingManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    private Guid GetCurrentUserId()
    {
        var value = User.FindFirstValue(
            ClaimTypes.NameIdentifier);

        if (!Guid.TryParse(value, out var userId))
        {
            throw new ReportingManagementException(
                "Authenticated user identifier is invalid.");
        }

        return userId;
    }
}
