using System.Security.Claims;
using CSM.Application.Common.Exceptions;
using CSM.Application.Common.Security;
using CSM.Application.HRM.Payroll;
using CSM.Application.HRM.Payroll.Dtos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSM.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = AppPolicies.ProjectManagement)]
public sealed class PayrollController : ControllerBase
{
    private readonly IPayrollService _payrollService;

    public PayrollController(
        IPayrollService payrollService)
    {
        _payrollService = payrollService;
    }

    [HttpGet]
    public async Task<
        ActionResult<IReadOnlyCollection<PayrollResponse>>> GetAll(
        [FromQuery] Guid? employeeId = null,
        [FromQuery] DateOnly? fromDate = null,
        [FromQuery] DateOnly? toDate = null,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var records =
                await _payrollService.GetAllAsync(
                    GetCurrentUserId(),
                    employeeId,
                    fromDate,
                    toDate,
                    cancellationToken);

            return Ok(records);
        }
        catch (PayrollManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("{payrollRecordId:guid}")]
    public async Task<ActionResult<PayrollResponse>> GetById(
        Guid payrollRecordId,
        CancellationToken cancellationToken)
    {
        try
        {
            var record =
                await _payrollService.GetByIdAsync(
                    GetCurrentUserId(),
                    payrollRecordId,
                    cancellationToken);

            return Ok(record);
        }
        catch (PayrollManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost]
    public async Task<ActionResult<PayrollResponse>> Create(
        CreatePayrollRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var record =
                await _payrollService.CreateAsync(
                    GetCurrentUserId(),
                    request,
                    cancellationToken);

            return CreatedAtAction(
                nameof(GetById),
                new { payrollRecordId = record.Id },
                record);
        }
        catch (PayrollManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("{payrollRecordId:guid}/calculate")]
    public async Task<ActionResult<PayrollResponse>> Calculate(
        Guid payrollRecordId,
        CalculatePayrollRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var record =
                await _payrollService.CalculateAsync(
                    GetCurrentUserId(),
                    payrollRecordId,
                    request,
                    cancellationToken);

            return Ok(record);
        }
        catch (PayrollManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("{payrollRecordId:guid}/approve")]
    public async Task<ActionResult<PayrollResponse>> Approve(
        Guid payrollRecordId,
        ApprovePayrollRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var record =
                await _payrollService.ApproveAsync(
                    GetCurrentUserId(),
                    payrollRecordId,
                    request,
                    cancellationToken);

            return Ok(record);
        }
        catch (PayrollManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("{payrollRecordId:guid}/paid")]
    public async Task<ActionResult<PayrollResponse>> MarkPaid(
        Guid payrollRecordId,
        MarkPayrollPaidRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var record =
                await _payrollService.MarkPaidAsync(
                    GetCurrentUserId(),
                    payrollRecordId,
                    request,
                    cancellationToken);

            return Ok(record);
        }
        catch (PayrollManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("{payrollRecordId:guid}/cancel")]
    public async Task<ActionResult<PayrollResponse>> Cancel(
        Guid payrollRecordId,
        CancelPayrollRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var record =
                await _payrollService.CancelAsync(
                    GetCurrentUserId(),
                    payrollRecordId,
                    request,
                    cancellationToken);

            return Ok(record);
        }
        catch (PayrollManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("{payrollRecordId:guid}/adjustments")]
    public async Task<ActionResult<PayrollResponse>> AddAdjustment(
        Guid payrollRecordId,
        CreatePayrollAdjustmentRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var record =
                await _payrollService.AddAdjustmentAsync(
                    GetCurrentUserId(),
                    payrollRecordId,
                    request,
                    cancellationToken);

            return Ok(record);
        }
        catch (PayrollManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    private Guid GetCurrentUserId()
    {
        var value =
            User.FindFirstValue(ClaimTypes.NameIdentifier);

        if (!Guid.TryParse(value, out var userId))
        {
            throw new PayrollManagementException(
                "Authenticated user identifier is missing.");
        }

        return userId;
    }
}
