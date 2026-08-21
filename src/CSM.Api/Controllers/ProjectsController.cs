using System.Security.Claims;
using CSM.Application.Common.Exceptions;
using CSM.Application.Common.Security;
using CSM.Application.Projects;
using CSM.Application.Projects.Dtos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSM.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = AppPolicies.ProjectManagement)]
public sealed class ProjectsController : ControllerBase
{
    private readonly IProjectService _projectService;

    public ProjectsController(IProjectService projectService)
    {
        _projectService = projectService;
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyCollection<ProjectResponse>>> GetAll(
        [FromQuery] Guid? constructionSiteId,
        CancellationToken cancellationToken)
    {
        try
        {
            var projects = await _projectService.GetAllAsync(
                GetCurrentUserId(),
                constructionSiteId,
                cancellationToken);

            return Ok(projects);
        }
        catch (ProjectManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("{projectId:guid}")]
    public async Task<ActionResult<ProjectResponse>> GetById(
        Guid projectId,
        CancellationToken cancellationToken)
    {
        try
        {
            var project = await _projectService.GetByIdAsync(
                GetCurrentUserId(),
                projectId,
                cancellationToken);

            return Ok(project);
        }
        catch (ProjectManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost]
    public async Task<ActionResult<ProjectResponse>> Create(
        CreateProjectRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var project = await _projectService.CreateAsync(
                GetCurrentUserId(),
                request,
                cancellationToken);

            return CreatedAtAction(
                nameof(GetById),
                new { projectId = project.Id },
                project);
        }
        catch (ProjectManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("{projectId:guid}")]
    public async Task<ActionResult<ProjectResponse>> Update(
        Guid projectId,
        UpdateProjectRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var project = await _projectService.UpdateAsync(
                GetCurrentUserId(),
                projectId,
                request,
                cancellationToken);

            return Ok(project);
        }
        catch (ProjectManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("{projectId:guid}/status")]
    public async Task<ActionResult<ProjectResponse>> ChangeStatus(
        Guid projectId,
        ChangeProjectStatusRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var project = await _projectService.ChangeStatusAsync(
                GetCurrentUserId(),
                projectId,
                request,
                cancellationToken);

            return Ok(project);
        }
        catch (ProjectManagementException ex)
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
            throw new ProjectManagementException(
                "Authenticated user identifier is invalid.");
        }

        return userId;
    }
}