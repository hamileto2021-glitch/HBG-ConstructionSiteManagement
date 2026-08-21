using System.Security.Claims;
using CSM.Application.Common.Exceptions;
using CSM.Application.Common.Security;
using CSM.Application.Finance.BudgetLines;
using CSM.Application.Finance.BudgetLines.Dtos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSM.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = AppPolicies.FinanceManagement)]
public sealed class BudgetLinesController : ControllerBase
{
    private readonly IBudgetLineService _budgetLineService;

    public BudgetLinesController(
        IBudgetLineService budgetLineService)
    {
        _budgetLineService = budgetLineService;
    }

    [HttpGet("budget/{budgetId:guid}")]
    public async Task<
        ActionResult<IReadOnlyCollection<BudgetLineResponse>>> GetByBudget(
        Guid budgetId,
        CancellationToken cancellationToken)
    {
        try
        {
            var lines = await _budgetLineService.GetByBudgetAsync(
                GetCurrentUserId(),
                budgetId,
                cancellationToken);

            return Ok(lines);
        }
        catch (BudgetLineManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("{budgetLineId:guid}")]
    public async Task<ActionResult<BudgetLineResponse>> GetById(
        Guid budgetLineId,
        CancellationToken cancellationToken)
    {
        try
        {
            var line = await _budgetLineService.GetByIdAsync(
                GetCurrentUserId(),
                budgetLineId,
                cancellationToken);

            return Ok(line);
        }
        catch (BudgetLineManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost]
    public async Task<ActionResult<BudgetLineResponse>> Create(
        CreateBudgetLineRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var line = await _budgetLineService.CreateAsync(
                GetCurrentUserId(),
                request,
                cancellationToken);

            return CreatedAtAction(
                nameof(GetById),
                new { budgetLineId = line.Id },
                line);
        }
        catch (BudgetLineManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("{budgetLineId:guid}")]
    public async Task<ActionResult<BudgetLineResponse>> Update(
        Guid budgetLineId,
        UpdateBudgetLineRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var line = await _budgetLineService.UpdateAsync(
                GetCurrentUserId(),
                budgetLineId,
                request,
                cancellationToken);

            return Ok(line);
        }
        catch (BudgetLineManagementException ex)
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
            throw new BudgetLineManagementException(
                "Authenticated user identifier is invalid.");
        }

        return userId;
    }
}
