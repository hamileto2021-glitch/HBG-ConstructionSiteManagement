using System.Security.Claims;
using CSM.Application.Common.Exceptions;
using CSM.Application.Common.Security;
using CSM.Application.Inventory.StockIssues;
using CSM.Application.Inventory.StockIssues.Dtos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSM.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = AppPolicies.ProcurementManagement)]
public sealed class StockIssuesController : ControllerBase
{
    private readonly IStockIssueService _stockIssueService;

    public StockIssuesController(
        IStockIssueService stockIssueService)
    {
        _stockIssueService = stockIssueService;
    }

    [HttpPost]
    public async Task<ActionResult<StockIssueResponse>> Create(
        [FromBody] CreateStockIssueRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var result =
                await _stockIssueService.CreateAsync(
                    GetCurrentUserId(),
                    request,
                    cancellationToken);

            return Ok(result);
        }
        catch (StockIssueManagementException ex)
        {
            return BadRequest(
                new { message = ex.Message });
        }
    }

    private Guid GetCurrentUserId()
    {
        var value =
            User.FindFirstValue(
                ClaimTypes.NameIdentifier);

        if (!Guid.TryParse(
                value,
                out var userId))
        {
            throw new UnauthorizedAccessException(
                "Authenticated user identifier is invalid.");
        }

        return userId;
    }
}
