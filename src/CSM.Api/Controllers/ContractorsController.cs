using System.Security.Claims;
using CSM.Application.Common.Exceptions;
using CSM.Application.HRM.Contractors;
using CSM.Application.HRM.Contractors.Dtos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSM.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize] // authentication only; each action declares its own granular policy
public sealed class ContractorsController : ControllerBase
{
    private readonly IContractorService _contractorService;

    public ContractorsController(
        IContractorService contractorService)
    {
        _contractorService = contractorService;
    }

    [Authorize(Policy = "HRM.Contractor.View")]
    [HttpGet]
    public async Task<
        ActionResult<IReadOnlyCollection<ContractorResponse>>> GetAll(
        [FromQuery] bool? isActive,
        CancellationToken cancellationToken)
    {
        try
        {
            var contractors =
                await _contractorService.GetAllAsync(
                    GetCurrentUserId(),
                    isActive,
                    cancellationToken);

            return Ok(contractors);
        }
        catch (ContractorManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [Authorize(Policy = "HRM.Contractor.View")]
    [HttpGet("{contractorId:guid}")]
    public async Task<ActionResult<ContractorResponse>> GetById(
        Guid contractorId,
        CancellationToken cancellationToken)
    {
        try
        {
            var contractor =
                await _contractorService.GetByIdAsync(
                    GetCurrentUserId(),
                    contractorId,
                    cancellationToken);

            return Ok(contractor);
        }
        catch (ContractorManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [Authorize(Policy = "HRM.Contractor.Manage")]
    [HttpPost]
    public async Task<ActionResult<ContractorResponse>> Create(
        CreateContractorRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var contractor =
                await _contractorService.CreateAsync(
                    GetCurrentUserId(),
                    request,
                    cancellationToken);

            return CreatedAtAction(
                nameof(GetById),
                new
                {
                    contractorId = contractor.Id
                },
                contractor);
        }
        catch (ContractorManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [Authorize(Policy = "HRM.Contractor.Manage")]
    [HttpPut("{contractorId:guid}")]
    public async Task<ActionResult<ContractorResponse>> Update(
        Guid contractorId,
        UpdateContractorRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var contractor =
                await _contractorService.UpdateAsync(
                    GetCurrentUserId(),
                    contractorId,
                    request,
                    cancellationToken);

            return Ok(contractor);
        }
        catch (ContractorManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    private Guid GetCurrentUserId()
    {
        var userId =
            User.FindFirstValue(ClaimTypes.NameIdentifier);

        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ContractorManagementException(
                "Authenticated user identifier is invalid.");
        }

        return parsedUserId;
    }
}
