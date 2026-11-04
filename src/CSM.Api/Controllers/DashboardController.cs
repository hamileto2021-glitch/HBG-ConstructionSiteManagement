using System.Security.Claims;
using CSM.Application.Dashboard;
using CSM.Application.Common.Exceptions;
using CSM.Infrastructure.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSM.Api.Controllers;

[ApiController]
[Route("api/dashboard")]
[Authorize]
public sealed class DashboardController : ControllerBase
{
    private readonly IExecutiveDashboardService _dashboardService;
    private readonly IPermissionEvaluator _permissionEvaluator;

    public DashboardController(
        IExecutiveDashboardService dashboardService,
        IPermissionEvaluator permissionEvaluator)
    {
        _dashboardService = dashboardService;
        _permissionEvaluator = permissionEvaluator;
    }

    [HttpGet("executive")]
    public async Task<IActionResult> GetExecutiveDashboard(
        CancellationToken cancellationToken)
    {
        var companyId = GetCompanyId();
        var userIdValue = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!Guid.TryParse(userIdValue, out var userId))
            return Unauthorized();

        var permissions = await _permissionEvaluator.GetPermissionsAsync(
            userId,
            cancellationToken);
        var permissionSet = permissions.ToHashSet(StringComparer.Ordinal);
        if (!DashboardPermissions.Any(permission =>
                permissionSet.Contains(permission)))
        {
            return Forbid();
        }

        var dashboard = await _dashboardService.GetAsync(
            companyId,
            userId,
            cancellationToken);

        return Ok(dashboard with
        {
            ActiveProjects = Has("Projects_View") ? dashboard.ActiveProjects : null,
            CompletedProjects = Has("Projects_View") ? dashboard.CompletedProjects : null,
            OpenDelays = Has("Projects_View") ? dashboard.OpenDelays : null,
            TotalEmployees = Has("HRM_Employee_View") ? dashboard.TotalEmployees : null,
            LowStockItems = Has("Procurement_Inventory_View") ? dashboard.LowStockItems : null,
            OpenSafetyIncidents = Has("Compliance_View") ? dashboard.OpenSafetyIncidents : null,
            TotalBudget = Has("Reports_FinancialSummary_View") ? dashboard.TotalBudget : null,
            TotalExpenses = Has("Reports_FinancialSummary_View") ? dashboard.TotalExpenses : null,
            BudgetUtilization = Has("Reports_FinancialSummary_View") ? dashboard.BudgetUtilization : null
        });

        bool Has(string permission) => permissionSet.Contains(permission);
    }

    private static readonly string[] DashboardPermissions =
    [
        "Reports_View",
        "Reports_FinancialSummary_View",
        "Projects_View",
        "HRM_Employee_View",
        "Compliance_View",
        "Procurement_Inventory_View"
    ];

    private Guid GetCompanyId()
    {
        var value =
            User.FindFirst("companyId")?.Value ??
            User.FindFirst("CompanyId")?.Value ??
            User.FindFirst("company_id")?.Value;

        if (!Guid.TryParse(value, out var companyId))
        {
            throw new ProjectManagementException(
                "Authenticated company identifier is invalid.");
        }

        return companyId;
    }
}
