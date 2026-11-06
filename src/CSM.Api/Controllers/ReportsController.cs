using System.Security.Claims;
using CSM.Application.Common.Exceptions;
using CSM.Application.Common.Security;
using CSM.Application.Reporting;
using CSM.Application.Reporting.Dtos;
using CSM.Infrastructure.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSM.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public sealed class ReportsController : ControllerBase
{
    private readonly IReportingService _reportingService;
    private readonly IPermissionEvaluator _permissionEvaluator;

    public ReportsController(
        IReportingService reportingService,
        IPermissionEvaluator permissionEvaluator)
    {
        _reportingService = reportingService;
        _permissionEvaluator = permissionEvaluator;
    }

    [HttpGet("executive-dashboard")]
    [Authorize(Policy = "Reports.View")]
    public async Task<ActionResult<ExecutiveDashboardResponse>> GetExecutiveDashboard(
        CancellationToken cancellationToken)
    {
        try
        {
            var result =
                await _reportingService.GetExecutiveDashboardAsync(
                    GetCurrentUserId(),
                    cancellationToken);

            return Ok(await FilterExecutiveDashboardAsync(
                result,
                cancellationToken));
        }
        catch (ReportingManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("financial-summary")]
    [Authorize(Policy = "Reports.FinancialSummary.View")]
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

    [HttpGet("site/{constructionSiteId:guid}/executive-dashboard")]
    [Authorize(Policy = "Reports.View")]
    public async Task<ActionResult<ExecutiveDashboardResponse>>
        GetSiteExecutiveDashboard(
            Guid constructionSiteId,
            CancellationToken cancellationToken)
    {
        try
        {
            var result =
                await _reportingService.GetSiteExecutiveDashboardAsync(
                    GetCurrentUserId(),
                    constructionSiteId,
                    cancellationToken);

            return Ok(await FilterExecutiveDashboardAsync(
                result,
                cancellationToken));
        }
        catch (ReportingManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("site/{constructionSiteId:guid}/financial-summary")]
    [Authorize(Policy = "Reports.FinancialSummary.View")]
    public async Task<ActionResult<FinancialSummaryResponse>>
        GetSiteFinancialSummary(
            Guid constructionSiteId,
            CancellationToken cancellationToken)
    {
        try
        {
            var result =
                await _reportingService.GetSiteFinancialSummaryAsync(
                    GetCurrentUserId(),
                    constructionSiteId,
                    cancellationToken);

            return Ok(result);
        }
        catch (ReportingManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("financial-summary/all")]
    [Authorize(Policy = "Reports.FinancialSummary.View")]
    public async Task<ActionResult<AllFinancialSummaryResponse>>
        GetAllFinancialSummaries(
            CancellationToken cancellationToken)
    {
        try
        {
            var result =
                await _reportingService
                    .GetAllFinancialSummariesAsync(
                        GetCurrentUserId(),
                        cancellationToken);

            return Ok(result);
        }
        catch (ReportingManagementException ex)
        {
            return BadRequest(new
            {
                message = ex.Message
            });
        }
    }

    [HttpGet("management")]
    [Authorize(Policy = "Reports.View")]
    public async Task<ActionResult<ManagementReportsResponse>>
        GetManagementReports(
            [FromQuery] Guid? constructionSiteId,
            CancellationToken cancellationToken)
    {
        try
        {
            var result = await _reportingService.GetManagementReportsAsync(
                GetCurrentUserId(),
                constructionSiteId,
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

    private async Task<ExecutiveDashboardResponse>
        FilterExecutiveDashboardAsync(
            ExecutiveDashboardResponse dashboard,
            CancellationToken cancellationToken)
    {
        var permissions = (await _permissionEvaluator.GetPermissionsAsync(
                GetCurrentUserId(),
                cancellationToken))
            .ToHashSet(StringComparer.Ordinal);

        var canViewSites = permissions.Contains("Sites_View");
        var canViewProjects = permissions.Contains("Projects_View");
        var canViewFinancialSummary =
            permissions.Contains("Reports_FinancialSummary_View");

        return dashboard with
        {
            TotalSites = canViewSites ? dashboard.TotalSites : null,
            ActiveSites = canViewSites ? dashboard.ActiveSites : null,
            SitesByStatus = canViewSites ? dashboard.SitesByStatus : null,
            TotalProjects = canViewProjects ? dashboard.TotalProjects : null,
            ProjectsByStatus = canViewProjects
                ? dashboard.ProjectsByStatus
                : null,
            TotalContractValue = canViewFinancialSummary
                ? dashboard.TotalContractValue
                : null,
            TotalBudget = canViewFinancialSummary
                ? dashboard.TotalBudget
                : null,
            TotalExpenses = canViewFinancialSummary
                ? dashboard.TotalExpenses
                : null,
            TotalInvoices = canViewFinancialSummary
                ? dashboard.TotalInvoices
                : null,
            TotalCompletedPayments = canViewFinancialSummary
                ? dashboard.TotalCompletedPayments
                : null,
            OutstandingInvoices = canViewFinancialSummary
                ? dashboard.OutstandingInvoices
                : null
        };
    }
}
