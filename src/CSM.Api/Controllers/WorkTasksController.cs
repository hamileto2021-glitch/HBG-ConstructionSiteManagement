using System.Security.Claims;
using CSM.Application.Common.Exceptions;
using CSM.Application.Common.Security;
using CSM.Application.Projects.Tasks;
using CSM.Application.Projects.Tasks.Dtos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSM.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = AppPolicies.ProjectManagement)]
public sealed class WorkTasksController : ControllerBase
{
    private readonly IWorkTaskService _workTaskService;

    public WorkTasksController(IWorkTaskService workTaskService)
    {
        _workTaskService = workTaskService;
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyCollection<WorkTaskResponse>>> GetAll(
        [FromQuery] Guid projectId,
        [FromQuery] Guid? projectPhaseId,
        CancellationToken cancellationToken)
    {
        try
        {
            var tasks = await _workTaskService.GetAllAsync(
                GetCurrentUserId(),
                projectId,
                projectPhaseId,
                cancellationToken);

            return Ok(tasks);
        }
        catch (WorkTaskManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("{taskId:guid}")]
    public async Task<ActionResult<WorkTaskResponse>> GetById(
        Guid taskId,
        CancellationToken cancellationToken)
    {
        try
        {
            var task = await _workTaskService.GetByIdAsync(
                GetCurrentUserId(),
                taskId,
                cancellationToken);

            return Ok(task);
        }
        catch (WorkTaskManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost]
    public async Task<ActionResult<WorkTaskResponse>> Create(
        CreateWorkTaskRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var task = await _workTaskService.CreateAsync(
                GetCurrentUserId(),
                request,
                cancellationToken);

            return CreatedAtAction(
                nameof(GetById),
                new { taskId = task.Id },
                task);
        }
        catch (WorkTaskManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("{taskId:guid}")]
    public async Task<ActionResult<WorkTaskResponse>> Update(
        Guid taskId,
        UpdateWorkTaskRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var task = await _workTaskService.UpdateAsync(
                GetCurrentUserId(),
                taskId,
                request,
                cancellationToken);

            return Ok(task);
        }
        catch (WorkTaskManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("{taskId:guid}/status")]
    public async Task<ActionResult<WorkTaskResponse>> ChangeStatus(
        Guid taskId,
        ChangeWorkTaskStatusRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var task = await _workTaskService.ChangeStatusAsync(
                GetCurrentUserId(),
                taskId,
                request,
                cancellationToken);

            return Ok(task);
        }
        catch (WorkTaskManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("{taskId:guid}/progress")]
    public async Task<ActionResult<WorkTaskResponse>> UpdateProgress(
        Guid taskId,
        UpdateWorkTaskProgressRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var task = await _workTaskService.UpdateProgressAsync(
                GetCurrentUserId(),
                taskId,
                request,
                cancellationToken);

            return Ok(task);
        }
        catch (WorkTaskManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("{taskId:guid}/dependencies")]
    public async Task<ActionResult<WorkTaskResponse>> AddDependency(
        Guid taskId,
        AddWorkTaskDependencyRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var task = await _workTaskService.AddDependencyAsync(
                GetCurrentUserId(),
                taskId,
                request,
                cancellationToken);

            return Ok(task);
        }
        catch (WorkTaskManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpDelete("{taskId:guid}/dependencies/{dependsOnTaskId:guid}")]
    public async Task<ActionResult<WorkTaskResponse>> RemoveDependency(
        Guid taskId,
        Guid dependsOnTaskId,
        CancellationToken cancellationToken)
    {
        try
        {
            var task = await _workTaskService.RemoveDependencyAsync(
                GetCurrentUserId(),
                taskId,
                dependsOnTaskId,
                cancellationToken);

            return Ok(task);
        }
        catch (WorkTaskManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    private Guid GetCurrentUserId()
    {
        var value = User.FindFirstValue(ClaimTypes.NameIdentifier);

        if (!Guid.TryParse(value, out var userId))
        {
            throw new WorkTaskManagementException(
                "Authenticated user identifier is invalid.");
        }

        return userId;
    }
}