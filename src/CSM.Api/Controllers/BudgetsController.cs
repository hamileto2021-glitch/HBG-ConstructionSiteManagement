using System.Security.Claims;
using CSM.Application.Common.Exceptions;
using CSM.Application.Common.Security;
using CSM.Application.Finance.Budgets;
using CSM.Application.Finance.Budgets.Dtos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSM.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = AppPolicies.FinanceManagement)]
public sealed class BudgetsController : ControllerBase
{
    private readonly IBudgetService _budgetService;

    public BudgetsController(
        IBudgetService budgetService)
    {
        _budgetService = budgetService;
    }

    [HttpGet]
    public async Task<
        ActionResult<IReadOnlyCollection<BudgetResponse>>> GetAll(
        CancellationToken cancellationToken)
    {
        try
        {
            var budgets = await _budgetService.GetAllAsync(
                GetCurrentUserId(),
                cancellationToken);

            return Ok(budgets);
        }
        catch (BudgetManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("{budgetId:guid}")]
    public async Task<ActionResult<BudgetResponse>> GetById(
        Guid budgetId,
        CancellationToken cancellationToken)
    {
        try
        {
            var budget = await _budgetService.GetByIdAsync(
                GetCurrentUserId(),
                budgetId,
                cancellationToken);

            return Ok(budget);
        }
        catch (BudgetManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost]
    public async Task<ActionResult<BudgetResponse>> Create(
        CreateBudgetRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var budget = await _budgetService.CreateAsync(
                GetCurrentUserId(),
                request,
                cancellationToken);

            return CreatedAtAction(
                nameof(GetById),
                new { budgetId = budget.Id },
                budget);
        }
        catch (BudgetManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("{budgetId:guid}")]
    public async Task<ActionResult<BudgetResponse>> Update(
        Guid budgetId,
        UpdateBudgetRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var budget = await _budgetService.UpdateAsync(
                GetCurrentUserId(),
                budgetId,
                request,
                cancellationToken);

            return Ok(budget);
        }
        catch (BudgetManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("{budgetId:guid}/status")]
    public async Task<ActionResult<BudgetResponse>> ChangeStatus(
        Guid budgetId,
        ChangeBudgetStatusRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var budget = await _budgetService.ChangeStatusAsync(
                GetCurrentUserId(),
                budgetId,
                request,
                cancellationToken);

            return Ok(budget);
        }
        catch (BudgetManagementException ex)
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
            throw new BudgetManagementException(
                "Authenticated user identifier is invalid.");
        }

        return userId;
    }
}
