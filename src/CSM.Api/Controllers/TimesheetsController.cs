using System.Security.Claims;
using CSM.Application.Common.Exceptions;
using CSM.Application.HRM.Timesheets;
using CSM.Application.HRM.Timesheets.Dtos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSM.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize] // authentication only; each action declares its own granular policy
public sealed class TimesheetsController : ControllerBase
{
    private readonly ITimesheetService _timesheetService;

    public TimesheetsController(
        ITimesheetService timesheetService)
    {
        _timesheetService = timesheetService;
    }

    [Authorize(Policy = "HRM.Timesheet.View")]
    [HttpGet]
    public async Task<
        ActionResult<IReadOnlyCollection<TimesheetResponse>>> GetAll(
        [FromQuery] Guid? employeeId = null,
        [FromQuery] DateOnly? fromDate = null,
        [FromQuery] DateOnly? toDate = null,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var timesheets =
                await _timesheetService.GetAllAsync(
                    GetCurrentUserId(),
                    employeeId,
                    fromDate,
                    toDate,
                    cancellationToken);

            return Ok(timesheets);
        }
        catch (TimesheetManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [Authorize(Policy = "HRM.Timesheet.View")]
    [HttpGet("{timesheetId:guid}")]
    public async Task<ActionResult<TimesheetResponse>> GetById(
        Guid timesheetId,
        CancellationToken cancellationToken)
    {
        try
        {
            var timesheet =
                await _timesheetService.GetByIdAsync(
                    GetCurrentUserId(),
                    timesheetId,
                    cancellationToken);

            return Ok(timesheet);
        }
        catch (TimesheetManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [Authorize(Policy = "HRM.Timesheet.Submit")]
    [HttpPost]
    public async Task<ActionResult<TimesheetResponse>> Create(
        CreateTimesheetRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var timesheet =
                await _timesheetService.CreateAsync(
                    GetCurrentUserId(),
                    request,
                    cancellationToken);

            return CreatedAtAction(
                nameof(GetById),
                new { timesheetId = timesheet.Id },
                timesheet);
        }
        catch (TimesheetManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [Authorize(Policy = "HRM.Timesheet.Submit")]
    [HttpPut("{timesheetId:guid}/submit")]
    public async Task<ActionResult<TimesheetResponse>> Submit(
        Guid timesheetId,
        SubmitTimesheetRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var timesheet =
                await _timesheetService.SubmitAsync(
                    GetCurrentUserId(),
                    timesheetId,
                    request,
                    cancellationToken);

            return Ok(timesheet);
        }
        catch (TimesheetManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [Authorize(Policy = "HRM.Timesheet.Approve")]
    [HttpPut("{timesheetId:guid}/review")]
    public async Task<ActionResult<TimesheetResponse>> Review(
        Guid timesheetId,
        ReviewTimesheetRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var timesheet =
                await _timesheetService.ReviewAsync(
                    GetCurrentUserId(),
                    timesheetId,
                    request,
                    cancellationToken);

            return Ok(timesheet);
        }
        catch (TimesheetManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }


    [Authorize(Policy = "HRM.Timesheet.Submit")]
    [HttpPut("{timesheetId:guid}/cancel")]
    public async Task<ActionResult<TimesheetResponse>> Cancel(
        Guid timesheetId,
        CancelTimesheetRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var timesheet =
                await _timesheetService.CancelAsync(
                    GetCurrentUserId(),
                    timesheetId,
                    request,
                    cancellationToken);

            return Ok(timesheet);
        }
        catch (TimesheetManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    // Generate
    [Authorize(Policy = "HRM.Timesheet.Submit")]
    [HttpPost("generate")]
    public async Task<ActionResult<TimesheetResponse>> Generate(
        GenerateTimesheetRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var result = await _timesheetService.GenerateAsync(
                GetCurrentUserId(),
                request,
                cancellationToken);

            return Ok(result);
        }
        catch (TimesheetManagementException ex)
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
            throw new TimesheetManagementException(
                "Authenticated user identifier is missing.");
        }

        return userId;
    }
}
