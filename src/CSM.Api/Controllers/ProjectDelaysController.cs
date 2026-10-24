using CSM.Application.Projects.ProjectDelays;
using CSM.Application.Projects.ProjectDelays.Dtos;
using CSM.Application.Common.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSM.Api.Controllers;

[ApiController]
[Route("api/project-delays")]
[Authorize(Policy = AppPolicies.ProjectManagement)]
public sealed class ProjectDelaysController : CurrentUserControllerBase
{
    private readonly IProjectDelayService _service;

    public ProjectDelaysController(IProjectDelayService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll(
        [FromQuery] Guid? projectId,
        CancellationToken cancellationToken)
    {
        var result = await _service.GetAllAsync(
            CurrentUserId,
            projectId,
            null,
            cancellationToken);

        return Ok(result);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(
        Guid id,
        CancellationToken cancellationToken)
    {
        var result = await _service.GetByIdAsync(
            CurrentUserId,
            id,
            cancellationToken);

        return result is null ? NotFound() : Ok(result);
    }

    [HttpPost]
    public async Task<IActionResult> Create(
        CreateProjectDelayRequest request,
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

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(
        Guid id,
        UpdateProjectDelayRequest request,
        CancellationToken cancellationToken)
    {
        var updated = await _service.UpdateAsync(
            CurrentUserId,
            id,
            request,
            cancellationToken);

        return updated is null ? NotFound() : Ok(updated);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(
        Guid id,
        CancellationToken cancellationToken)
    {
        var deleted = await _service.DeleteAsync(
            CurrentUserId,
            id,
            cancellationToken);

        return deleted ? NoContent() : NotFound();
    }
}