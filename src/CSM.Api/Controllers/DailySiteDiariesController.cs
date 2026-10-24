using CSM.Application.Projects.DailySiteDiaries;
using CSM.Application.Projects.DailySiteDiaries.Dtos;
using CSM.Application.Common.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSM.Api.Controllers;

[ApiController]
[Route("api/daily-site-diaries")]
[Authorize(Policy = AppPolicies.ProjectManagement)]
public class DailySiteDiaryController : CurrentUserControllerBase
{
    private readonly IDailySiteDiaryService _service;

    public DailySiteDiaryController(IDailySiteDiaryService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyCollection<DailySiteDiaryResponse>>> GetAll(
        [FromQuery] Guid? projectId,
        [FromQuery] Guid? siteId,
        CancellationToken cancellationToken)
    {
        var result = await _service.GetAllAsync(
            CurrentUserId,
            projectId,
            siteId,
            cancellationToken);

        return Ok(result);
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<DailySiteDiaryResponse>> GetById(
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
    public async Task<ActionResult<DailySiteDiaryResponse>> Create(
        CreateDailySiteDiaryRequest request,
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
    public async Task<ActionResult<DailySiteDiaryResponse>> Update(
        Guid id,
        UpdateDailySiteDiaryRequest request,
        CancellationToken cancellationToken)
    {
        var updated = await _service.UpdateAsync(
            CurrentUserId,
            id,
            request,
            cancellationToken);

        if (updated is null)
            return NotFound();

        return Ok(updated);
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

        if (!deleted)
            return NotFound();

        return NoContent();
    }
}