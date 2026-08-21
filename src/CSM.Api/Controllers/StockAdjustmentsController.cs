using System.Security.Claims;
using CSM.Application.Common.Exceptions;
using CSM.Application.Common.Security;
using CSM.Application.Inventory.StockAdjustments;
using CSM.Application.Inventory.StockAdjustments.Dtos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSM.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = AppPolicies.ProcurementManagement)]
public sealed class StockAdjustmentsController : ControllerBase
{
    private readonly IStockAdjustmentService _stockAdjustmentService;

    public StockAdjustmentsController(
        IStockAdjustmentService stockAdjustmentService)
    {
        _stockAdjustmentService = stockAdjustmentService;
    }

    [HttpPost]
    public async Task<ActionResult<StockAdjustmentResponse>> Create(
        CreateStockAdjustmentRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var result =
                await _stockAdjustmentService.CreateAsync(
                    GetCurrentUserId(),
                    request,
                    cancellationToken);

            return Ok(result);
        }
        catch (StockAdjustmentManagementException ex)
        {
            return BadRequest(new
            {
                message = ex.Message
            });
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
            throw new StockAdjustmentManagementException(
                "Invalid authenticated user.");
        }

        return userId;
    }
}
