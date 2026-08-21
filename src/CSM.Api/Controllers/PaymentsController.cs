using System.Security.Claims;
using CSM.Application.Common.Exceptions;
using CSM.Application.Common.Security;
using CSM.Application.Finance.Payments;
using CSM.Application.Finance.Payments.Dtos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSM.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = AppPolicies.FinanceManagement)]
public sealed class PaymentsController : ControllerBase
{
    private readonly IPaymentService _paymentService;

    public PaymentsController(
        IPaymentService paymentService)
    {
        _paymentService = paymentService;
    }

    [HttpGet]
    public async Task<
        ActionResult<IReadOnlyCollection<PaymentResponse>>> GetAll(
        CancellationToken cancellationToken)
    {
        try
        {
            var payments = await _paymentService.GetAllAsync(
                GetCurrentUserId(),
                cancellationToken);

            return Ok(payments);
        }
        catch (PaymentManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("{paymentId:guid}")]
    public async Task<ActionResult<PaymentResponse>> GetById(
        Guid paymentId,
        CancellationToken cancellationToken)
    {
        try
        {
            var payment = await _paymentService.GetByIdAsync(
                GetCurrentUserId(),
                paymentId,
                cancellationToken);

            return Ok(payment);
        }
        catch (PaymentManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost]
    public async Task<ActionResult<PaymentResponse>> Create(
        CreatePaymentRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var payment = await _paymentService.CreateAsync(
                GetCurrentUserId(),
                request,
                cancellationToken);

            return CreatedAtAction(
                nameof(GetById),
                new { paymentId = payment.Id },
                payment);
        }
        catch (PaymentManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("{paymentId:guid}")]
    public async Task<ActionResult<PaymentResponse>> Update(
        Guid paymentId,
        UpdatePaymentRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var payment = await _paymentService.UpdateAsync(
                GetCurrentUserId(),
                paymentId,
                request,
                cancellationToken);

            return Ok(payment);
        }
        catch (PaymentManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("{paymentId:guid}/status")]
    public async Task<ActionResult<PaymentResponse>> ChangeStatus(
        Guid paymentId,
        ChangePaymentStatusRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var payment = await _paymentService.ChangeStatusAsync(
                GetCurrentUserId(),
                paymentId,
                request,
                cancellationToken);

            return Ok(payment);
        }
        catch (PaymentManagementException ex)
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
            throw new PaymentManagementException(
                "Authenticated user identifier is invalid.");
        }

        return userId;
    }
}
