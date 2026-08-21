using System.Security.Claims;
using CSM.Application.Common.Exceptions;
using CSM.Application.Common.Security;
using CSM.Application.Compliance.Documents;
using CSM.Application.Compliance.Documents.Dtos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CSM.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = AppPolicies.ProcurementManagement)]
public sealed class DocumentsController : ControllerBase
{
    private readonly IDocumentService _documentService;

    public DocumentsController(
        IDocumentService documentService)
    {
        _documentService = documentService;
    }

    [HttpGet]
    public async Task<
        ActionResult<IReadOnlyCollection<DocumentResponse>>> GetAll(
        CancellationToken cancellationToken)
    {
        try
        {
            var result =
                await _documentService.GetAllAsync(
                    GetCurrentUserId(),
                    cancellationToken);

            return Ok(result);
        }
        catch (DocumentManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("{documentId:guid}")]
    public async Task<ActionResult<DocumentResponse>> GetById(
        Guid documentId,
        CancellationToken cancellationToken)
    {
        try
        {
            var result =
                await _documentService.GetByIdAsync(
                    GetCurrentUserId(),
                    documentId,
                    cancellationToken);

            return Ok(result);
        }
        catch (DocumentManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost]
    public async Task<ActionResult<DocumentResponse>> Create(
        [FromBody] CreateDocumentRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var result =
                await _documentService.CreateAsync(
                    GetCurrentUserId(),
                    request,
                    cancellationToken);

            return CreatedAtAction(
                nameof(GetById),
                new { documentId = result.Id },
                result);
        }
        catch (DocumentManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("{documentId:guid}")]
    public async Task<ActionResult<DocumentResponse>> Update(
        Guid documentId,
        [FromBody] UpdateDocumentRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var result =
                await _documentService.UpdateAsync(
                    GetCurrentUserId(),
                    documentId,
                    request,
                    cancellationToken);

            return Ok(result);
        }
        catch (DocumentManagementException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    private Guid GetCurrentUserId()
    {
        var userId =
            User.FindFirstValue(
                ClaimTypes.NameIdentifier);

        if (!Guid.TryParse(
                userId,
                out var parsedUserId))
        {
            throw new DocumentManagementException(
                "Authenticated user identifier is invalid.");
        }

        return parsedUserId;
    }
}
