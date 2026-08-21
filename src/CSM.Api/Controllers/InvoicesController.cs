using System.Security.Claims;
using CSM.Application.Common.Exceptions;
using CSM.Application.Common.Security;
using CSM.Application.Finance.Invoices;
using CSM.Application.Finance.Invoices.Dtos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSM.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = AppPolicies.FinanceManagement)]
public sealed class InvoicesController : ControllerBase
{
    private readonly IInvoiceService _invoiceService;

    public InvoicesController(
        IInvoiceService invoiceService)
    {
        _invoiceService = invoiceService;
    }

    [HttpGet]
    public async Task<
        ActionResult<IReadOnlyCollection<InvoiceResponse>>> GetAll(
        CancellationToken cancellationToken)
    {
        try
        {
            var invoices = await _invoiceService.GetAllAsync(
                GetCurrentUserId(),
                cancellationToken);

            return Ok(invoices);
        }
        catch (InvoiceManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("{invoiceId:guid}")]
    public async Task<ActionResult<InvoiceResponse>> GetById(
        Guid invoiceId,
        CancellationToken cancellationToken)
    {
        try
        {
            var invoice = await _invoiceService.GetByIdAsync(
                GetCurrentUserId(),
                invoiceId,
                cancellationToken);

            return Ok(invoice);
        }
        catch (InvoiceManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost]
    public async Task<ActionResult<InvoiceResponse>> Create(
        CreateInvoiceRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var invoice = await _invoiceService.CreateAsync(
                GetCurrentUserId(),
                request,
                cancellationToken);

            return CreatedAtAction(
                nameof(GetById),
                new { invoiceId = invoice.Id },
                invoice);
        }
        catch (InvoiceManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("{invoiceId:guid}")]
    public async Task<ActionResult<InvoiceResponse>> Update(
        Guid invoiceId,
        UpdateInvoiceRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var invoice = await _invoiceService.UpdateAsync(
                GetCurrentUserId(),
                invoiceId,
                request,
                cancellationToken);

            return Ok(invoice);
        }
        catch (InvoiceManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("{invoiceId:guid}/status")]
    public async Task<ActionResult<InvoiceResponse>> ChangeStatus(
        Guid invoiceId,
        ChangeInvoiceStatusRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var invoice = await _invoiceService.ChangeStatusAsync(
                GetCurrentUserId(),
                invoiceId,
                request,
                cancellationToken);

            return Ok(invoice);
        }
        catch (InvoiceManagementException ex)
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
            throw new InvoiceManagementException(
                "Authenticated user identifier is invalid.");
        }

        return userId;
    }
}
