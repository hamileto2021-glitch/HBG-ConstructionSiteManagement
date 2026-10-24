using CSM.Application.Projects.DailyProgressPhotos;
using CSM.Application.Common.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSM.Api.Controllers;

[ApiController]
[Route("api/daily-progress-photos")]
[Authorize(Policy = AppPolicies.ProjectManagement)]
public sealed class DailyProgressPhotosController : CurrentUserControllerBase
{
    private readonly IDailyProgressPhotoService _service;

    public DailyProgressPhotosController(
        IDailyProgressPhotoService service)
    {
        _service = service;
    }

    [HttpGet("{diaryId:guid}")]
    public async Task<IActionResult> GetByDiary(
        Guid diaryId,
        CancellationToken cancellationToken)
    {
        var result = await _service.GetByDiaryAsync(
            CurrentUserId,
            diaryId,
            cancellationToken);

        return Ok(result);
    }

    [HttpGet("{photoId:guid}/content")]
    public async Task<IActionResult> GetContent(
        Guid photoId,
        CancellationToken cancellationToken)
    {
        var content = await _service.GetContentAsync(
            CurrentUserId,
            photoId,
            cancellationToken);

        if (content is null)
            return NotFound();

        Response.Headers.CacheControl = "private, no-store";
        Response.Headers.XContentTypeOptions = "nosniff";

        return File(
            content.Content,
            content.ContentType,
            content.FileName,
            enableRangeProcessing: true);
    }

    [HttpPost("{diaryId:guid}")]
    [RequestSizeLimit(25_000_000)]
    public async Task<IActionResult> Upload(
        Guid diaryId,
        IFormFile file,
        [FromForm] string? caption,
        CancellationToken cancellationToken)
    {
        if (file is null || file.Length == 0 || file.Length > 25_000_000)
            return BadRequest(new { message = "Select an image smaller than 25 MB." });

        await using var stream = file.OpenReadStream();

        try
        {
            var photo = await _service.UploadAsync(
                CurrentUserId,
                diaryId,
                stream,
                caption,
                cancellationToken);

            return Ok(photo);
        }
        catch (InvalidDataException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpDelete("{photoId:guid}")]
    public async Task<IActionResult> Delete(
        Guid photoId,
        CancellationToken cancellationToken)
    {
        await _service.DeleteAsync(
            CurrentUserId,
            photoId,
            cancellationToken);

        return NoContent();
    }
}