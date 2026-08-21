using CSM.Application.Common.Exceptions;
using CSM.Application.Common.Security;
using CSM.Application.Compliance.Documents;
using CSM.Application.Compliance.Documents.Dtos;
using CSM.Domain.Constants;
using CSM.Domain.Entities.Compliance;
using CSM.Domain.Entities.Identity;
using CSM.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CSM.Infrastructure.Services;

public sealed class DocumentService : IDocumentService
{
    private readonly ApplicationDbContext _dbContext;

    public DocumentService(
        ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<IReadOnlyCollection<DocumentResponse>> GetAllAsync(
        Guid currentUserId,
        CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(
            currentUserId,
            cancellationToken);

        EnsureCanManage(actor);

        var query = _dbContext.Documents
            .AsNoTracking()
            .Where(x => !x.IsDeleted)
            .AsQueryable();

        if (!IsSuperAdmin(actor))
        {
            query = query.Where(
                x => x.CompanyId == GetActorCompanyId(actor));
        }

        return await query
            .OrderBy(x => x.DocumentNumber)
            .Select(x => new DocumentResponse
            {
                Id = x.Id,
                CompanyId = x.CompanyId,
                DocumentNumber = x.DocumentNumber,
                Name = x.Name,
                DocumentType = x.DocumentType,
                FileName = x.FileName,
                StoragePath = x.StoragePath,
                ContentType = x.ContentType,
                FileSizeBytes = x.FileSizeBytes,
                ConstructionSiteId = x.ConstructionSiteId,
                ProjectId = x.ProjectId,
                EmployeeId = x.EmployeeId,
                RelatedEntityId = x.RelatedEntityId,
                RelatedEntityType = x.RelatedEntityType,
                IssueDate = x.IssueDate,
                ExpiryDate = x.ExpiryDate,
                IsConfidential = x.IsConfidential,
                Description = x.Description,
                CreatedAtUtc = x.CreatedAtUtc,
                UpdatedAtUtc = x.UpdatedAtUtc
            })
            .ToListAsync(cancellationToken);
    }

    public async Task<DocumentResponse> GetByIdAsync(
        Guid currentUserId,
        Guid documentId,
        CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(
            currentUserId,
            cancellationToken);

        EnsureCanManage(actor);

        var document = await _dbContext.Documents
            .AsNoTracking()
            .SingleOrDefaultAsync(
                x =>
                    x.Id == documentId &&
                    !x.IsDeleted,
                cancellationToken)
            ?? throw new DocumentManagementException(
                "Document was not found.");

        EnsureCompanyAccess(
            actor,
            document.CompanyId);

        return Map(document);
    }

    public async Task<DocumentResponse> CreateAsync(
        Guid currentUserId,
        CreateDocumentRequest request,
        CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(
            currentUserId,
            cancellationToken);

        EnsureCanManage(actor);

        var companyId = GetActorCompanyId(actor);

        Validate(
            request.DocumentNumber,
            request.Name,
            request.FileName,
            request.StoragePath,
            request.FileSizeBytes,
            request.IssueDate,
            request.ExpiryDate);

        var normalizedNumber =
            request.DocumentNumber.Trim();

        var duplicate = await _dbContext.Documents
            .AnyAsync(
                x =>
                    !x.IsDeleted &&
                    x.CompanyId == companyId &&
                    x.DocumentNumber == normalizedNumber,
                cancellationToken);

        if (duplicate)
        {
            throw new DocumentManagementException(
                "A document with this document number already exists in the company.");
        }

        var document = new Document
        {
            CompanyId = companyId,
            DocumentNumber = normalizedNumber,
            Name = request.Name.Trim(),
            DocumentType = request.DocumentType,
            FileName = request.FileName.Trim(),
            StoragePath = request.StoragePath.Trim(),
            ContentType = Clean(request.ContentType),
            FileSizeBytes = request.FileSizeBytes,
            ConstructionSiteId = request.ConstructionSiteId,
            ProjectId = request.ProjectId,
            EmployeeId = request.EmployeeId,
            RelatedEntityId = request.RelatedEntityId,
            RelatedEntityType = Clean(request.RelatedEntityType),
            IssueDate = request.IssueDate,
            ExpiryDate = request.ExpiryDate,
            IsConfidential = request.IsConfidential,
            Description = Clean(request.Description)
        };

        _dbContext.Documents.Add(document);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return Map(document);
    }

    public async Task<DocumentResponse> UpdateAsync(
        Guid currentUserId,
        Guid documentId,
        UpdateDocumentRequest request,
        CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(
            currentUserId,
            cancellationToken);

        EnsureCanManage(actor);

        var document = await _dbContext.Documents
            .SingleOrDefaultAsync(
                x =>
                    x.Id == documentId &&
                    !x.IsDeleted,
                cancellationToken)
            ?? throw new DocumentManagementException(
                "Document was not found.");

        EnsureCompanyAccess(
            actor,
            document.CompanyId);

        Validate(
            request.DocumentNumber,
            request.Name,
            request.FileName,
            request.StoragePath,
            request.FileSizeBytes,
            request.IssueDate,
            request.ExpiryDate);

        var normalizedNumber =
            request.DocumentNumber.Trim();

        var duplicate = await _dbContext.Documents
            .AnyAsync(
                x =>
                    x.Id != document.Id &&
                    !x.IsDeleted &&
                    x.CompanyId == document.CompanyId &&
                    x.DocumentNumber == normalizedNumber,
                cancellationToken);

        if (duplicate)
        {
            throw new DocumentManagementException(
                "A document with this document number already exists in the company.");
        }

        document.DocumentNumber = normalizedNumber;
        document.Name = request.Name.Trim();
        document.DocumentType = request.DocumentType;
        document.FileName = request.FileName.Trim();
        document.StoragePath = request.StoragePath.Trim();
        document.ContentType = Clean(request.ContentType);
        document.FileSizeBytes = request.FileSizeBytes;
        document.ConstructionSiteId = request.ConstructionSiteId;
        document.ProjectId = request.ProjectId;
        document.EmployeeId = request.EmployeeId;
        document.RelatedEntityId = request.RelatedEntityId;
        document.RelatedEntityType = Clean(request.RelatedEntityType);
        document.IssueDate = request.IssueDate;
        document.ExpiryDate = request.ExpiryDate;
        document.IsConfidential = request.IsConfidential;
        document.Description = Clean(request.Description);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return Map(document);
    }

    private async Task<User> GetActorAsync(
        Guid currentUserId,
        CancellationToken cancellationToken)
    {
        return await _dbContext.Users
            .Include(x => x.UserRoles)
                .ThenInclude(x => x.Role)
            .SingleOrDefaultAsync(
                x => x.Id == currentUserId,
                cancellationToken)
            ?? throw new DocumentManagementException(
                "Authenticated user was not found.");
    }

    private static void EnsureCanManage(
        User actor)
    {
        if (IsSuperAdmin(actor) ||
            HasRole(actor, AppRoles.CompanyAdmin) ||
            HasRole(actor, AppRoles.SiteManager))
        {
            return;
        }

        throw new DocumentManagementException(
            "You are not authorized to manage documents.");
    }

    private static void EnsureCompanyAccess(
        User actor,
        Guid companyId)
    {
        if (IsSuperAdmin(actor))
        {
            return;
        }

        if (!actor.CompanyId.HasValue ||
            actor.CompanyId.Value != companyId)
        {
            throw new DocumentManagementException(
                "You are not authorized to access this document.");
        }
    }

    private static Guid GetActorCompanyId(
        User actor)
    {
        if (!actor.CompanyId.HasValue)
        {
            throw new DocumentManagementException(
                "Current user is not assigned to a company.");
        }

        return actor.CompanyId.Value;
    }

    private static bool IsSuperAdmin(
        User actor)
    {
        return HasRole(
            actor,
            AppRoles.SuperAdmin);
    }

    private static bool HasRole(
        User actor,
        string roleName)
    {
        return actor.UserRoles.Any(
            x =>
                !x.IsDeleted &&
                !x.Role.IsDeleted &&
                string.Equals(
                    x.Role.Name,
                    roleName,
                    StringComparison.OrdinalIgnoreCase));
    }

    private static void Validate(
        string documentNumber,
        string name,
        string fileName,
        string storagePath,
        long fileSizeBytes,
        DateOnly? issueDate,
        DateOnly? expiryDate)
    {
        if (string.IsNullOrWhiteSpace(documentNumber))
        {
            throw new DocumentManagementException(
                "Document number is required.");
        }

        if (documentNumber.Trim().Length > 50)
        {
            throw new DocumentManagementException(
                "Document number cannot exceed 50 characters.");
        }

        if (string.IsNullOrWhiteSpace(name))
        {
            throw new DocumentManagementException(
                "Document name is required.");
        }

        if (name.Trim().Length > 250)
        {
            throw new DocumentManagementException(
                "Document name cannot exceed 250 characters.");
        }

        if (string.IsNullOrWhiteSpace(fileName))
        {
            throw new DocumentManagementException(
                "File name is required.");
        }

        if (fileName.Trim().Length > 255)
        {
            throw new DocumentManagementException(
                "File name cannot exceed 255 characters.");
        }

        if (string.IsNullOrWhiteSpace(storagePath))
        {
            throw new DocumentManagementException(
                "Storage path is required.");
        }

        if (storagePath.Trim().Length > 1000)
        {
            throw new DocumentManagementException(
                "Storage path cannot exceed 1000 characters.");
        }

        if (fileSizeBytes < 0)
        {
            throw new DocumentManagementException(
                "File size cannot be negative.");
        }

        if (issueDate.HasValue &&
            expiryDate.HasValue &&
            expiryDate.Value < issueDate.Value)
        {
            throw new DocumentManagementException(
                "Expiry date cannot be earlier than issue date.");
        }
    }

    private static string? Clean(
        string? value)
    {
        return string.IsNullOrWhiteSpace(value)
            ? null
            : value.Trim();
    }

    private static DocumentResponse Map(
        Document document)
    {
        return new DocumentResponse
        {
            Id = document.Id,
            CompanyId = document.CompanyId,
            DocumentNumber = document.DocumentNumber,
            Name = document.Name,
            DocumentType = document.DocumentType,
            FileName = document.FileName,
            StoragePath = document.StoragePath,
            ContentType = document.ContentType,
            FileSizeBytes = document.FileSizeBytes,
            ConstructionSiteId = document.ConstructionSiteId,
            ProjectId = document.ProjectId,
            EmployeeId = document.EmployeeId,
            RelatedEntityId = document.RelatedEntityId,
            RelatedEntityType = document.RelatedEntityType,
            IssueDate = document.IssueDate,
            ExpiryDate = document.ExpiryDate,
            IsConfidential = document.IsConfidential,
            Description = document.Description,
            CreatedAtUtc = document.CreatedAtUtc,
            UpdatedAtUtc = document.UpdatedAtUtc
        };
    }
}
