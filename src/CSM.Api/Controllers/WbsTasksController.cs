using CSM.Application.Projects.WbsTasks;
using CSM.Application.Projects.WbsTasks.Dtos;
using CSM.Application.Common.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSM.Api.Controllers;

[ApiController]
[Route("api/wbs-tasks")]
[Authorize(Policy = AppPolicies.ProjectManagement)]
public class WbsTasksController : CurrentUserControllerBase
{
    private readonly IWbsTaskService _service;

    public WbsTasksController(IWbsTaskService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyCollection<WbsTaskResponse>>> GetAll(
        CancellationToken cancellationToken)
    {
        var result = await _service.GetAllAsync(
            CurrentUserId,
            cancellationToken);

        return Ok(result);
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<WbsTaskResponse>> GetById(
        Guid id,
        CancellationToken cancellationToken)
    {
        var result = await _service.GetByIdAsync(
            CurrentUserId,
            id,
            cancellationToken);

        if (result is null)
            return NotFound();

        return Ok(result);
    }

    [HttpPost]
    public async Task<ActionResult<WbsTaskResponse>> Create(
        CreateWbsTaskRequest request,
        CancellationToken cancellationToken)
    {
        var created = await _service.CreateAsync(
            CurrentUserId,
            request,
            cancellationToken);

        return CreatedAtAction(
            nameof(GetById),
            new { id = created.Id },
            created);
    }
}