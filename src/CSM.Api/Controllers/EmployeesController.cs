using System.Security.Claims;
using CSM.Application.Common.Exceptions;
using CSM.Application.Common.Security;
using CSM.Application.HRM.Employees;
using CSM.Application.HRM.Employees.Dtos;
using CSM.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSM.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = AppPolicies.ProjectManagement)]
public sealed class EmployeesController : ControllerBase
{
    private readonly IEmployeeService _employeeService;

    public EmployeesController(
        IEmployeeService employeeService)
    {
        _employeeService = employeeService;
    }

    [HttpGet]
    public async Task<
        ActionResult<IReadOnlyCollection<EmployeeResponse>>> GetAll(
        [FromQuery] EmployeeStatus? status,
        CancellationToken cancellationToken)
    {
        try
        {
            var employees =
                await _employeeService.GetAllAsync(
                    GetCurrentUserId(),
                    status,
                    cancellationToken);

            return Ok(employees);
        }
        catch (EmployeeManagementException ex)
        {
            return BadRequest(
                new { message = ex.Message });
        }
    }

    [HttpGet("{employeeId:guid}")]
    public async Task<ActionResult<EmployeeResponse>> GetById(
        Guid employeeId,
        CancellationToken cancellationToken)
    {
        try
        {
            var employee =
                await _employeeService.GetByIdAsync(
                    GetCurrentUserId(),
                    employeeId,
                    cancellationToken);

            return Ok(employee);
        }
        catch (EmployeeManagementException ex)
        {
            return BadRequest(
                new { message = ex.Message });
        }
    }

    [HttpPost]
    public async Task<ActionResult<EmployeeResponse>> Create(
        CreateEmployeeRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var employee =
                await _employeeService.CreateAsync(
                    GetCurrentUserId(),
                    request,
                    cancellationToken);

            return CreatedAtAction(
                nameof(GetById),
                new { employeeId = employee.Id },
                employee);
        }
        catch (EmployeeManagementException ex)
        {
            return BadRequest(
                new { message = ex.Message });
        }
    }

    [HttpPut("{employeeId:guid}")]
    public async Task<ActionResult<EmployeeResponse>> Update(
        Guid employeeId,
        UpdateEmployeeRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var employee =
                await _employeeService.UpdateAsync(
                    GetCurrentUserId(),
                    employeeId,
                    request,
                    cancellationToken);

            return Ok(employee);
        }
        catch (EmployeeManagementException ex)
        {
            return BadRequest(
                new { message = ex.Message });
        }
    }

    [HttpPut("{employeeId:guid}/status")]
    public async Task<ActionResult<EmployeeResponse>> ChangeStatus(
        Guid employeeId,
        ChangeEmployeeStatusRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var employee =
                await _employeeService.ChangeStatusAsync(
                    GetCurrentUserId(),
                    employeeId,
                    request,
                    cancellationToken);

            return Ok(employee);
        }
        catch (EmployeeManagementException ex)
        {
            return BadRequest(
                new { message = ex.Message });
        }
    }

    private Guid GetCurrentUserId()
    {
        var value = User.FindFirstValue(
            ClaimTypes.NameIdentifier);

        if (!Guid.TryParse(value, out var userId))
        {
            throw new EmployeeManagementException(
                "Authenticated user identifier is invalid.");
        }

        return userId;
    }
}