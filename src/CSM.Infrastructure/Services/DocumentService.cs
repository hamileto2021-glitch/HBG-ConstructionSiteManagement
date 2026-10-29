using CSM.Application.Common.Exceptions;
using CSM.Application.Common.Security;
using CSM.Application.Compliance.Documents;
using CSM.Application.Compliance.Documents.Dtos;
using CSM.Domain.Constants;
using CSM.Domain.Entities.Compliance;
using CSM.Domain.Entities.Identity;
using CSM.Domain.Enums;
using CSM.Infrastructure.Persistence;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;

namespace CSM.Infrastructure.Services;

public sealed class DocumentService : IDocumentService
{
    private readonly ApplicationDbContext _dbContext;

    public DocumentService(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<IReadOnlyCollection<DocumentResponse>> GetAllAsync(
        Guid currentUserId,
        CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(currentUserId, cancellationToken);

        EnsureCanView(actor);

        var query = _dbContext.Documents
            .AsNoTracking()
            .Where(x => !x.IsDeleted)
            .AsQueryable();

        if (!IsSuperAdmin(actor))
        {
            query = query.Where(x => x.CompanyId == GetActorCompanyId(actor));
            var siteIds = await GetAuthorizedSiteIdsAsync(actor, cancellationToken);
            if (siteIds.Count > 0)
            {
                query = query.Where(document =>
                    (document.ConstructionSiteId.HasValue &&
                     siteIds.Contains(document.ConstructionSiteId.Value)) ||
                    (document.ProjectId.HasValue &&
                     _dbContext.Projects.Any(project =>
                         project.Id == document.ProjectId.Value &&
                         siteIds.Contains(project.ConstructionSiteId))));
            }
        }

        return await (
            from d in query
            join s in _dbContext.ConstructionSites
                on d.ConstructionSiteId equals s.Id into sites
            from site in sites.DefaultIfEmpty()
            orderby d.CreatedAtUtc descending
            select new DocumentResponse
            {
                Id = d.Id,
                CompanyId = d.CompanyId,

                ConstructionSiteId = d.ConstructionSiteId,
                ConstructionSiteName = site != null ? site.Name : null,

                DocumentNumber = d.DocumentNumber,
                Name = d.Name,
                DocumentType = d.DocumentType,

                DrawingNumber = d.DrawingNumber,
                SheetNumber = d.SheetNumber,
                Discipline = d.Discipline,
                DrawingStatus = d.DrawingStatus,
                CurrentRevision = d.CurrentRevision,

                FileName = d.FileName,
                StoragePath = d.StoragePath,
                ContentType = d.ContentType,
                FileSizeBytes = d.FileSizeBytes,

                ProjectId = d.ProjectId,
                EmployeeId = d.EmployeeId,
                RelatedEntityId = d.RelatedEntityId,
                RelatedEntityType = d.RelatedEntityType,

                IssueDate = d.IssueDate,
                ExpiryDate = d.ExpiryDate,
                IsConfidential = d.IsConfidential,
                Description = d.Description,

                CreatedAtUtc = d.CreatedAtUtc,
                UpdatedAtUtc = d.UpdatedAtUtc
            }).ToListAsync(cancellationToken);
    }

    public async Task<DocumentResponse> GetByIdAsync(
        Guid currentUserId,
        Guid documentId,
        CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(currentUserId, cancellationToken);

        EnsureCanView(actor);

        var document = await _dbContext.Documents

            .AsNoTracking()
            .SingleOrDefaultAsync(
                x => x.Id == documentId && !x.IsDeleted,
                cancellationToken)
            ?? throw new DocumentManagementException("Document was not found.");

        EnsureCompanyAccess(actor, document.CompanyId);
        await EnsureDocumentSiteScopeAsync(
            actor, document.ConstructionSiteId, document.ProjectId, cancellationToken);

        return Map(document);
    }

    public async Task<DocumentResponse> CreateAsync(
        Guid currentUserId,
        CreateDocumentRequest request,
        CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(currentUserId, cancellationToken);

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

        await EnsureDocumentSiteScopeAsync(
            actor, request.ConstructionSiteId, request.ProjectId, cancellationToken);

        var normalizedNumber = request.DocumentNumber.Trim();

        var duplicate = await _dbContext.Documents.AnyAsync(
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

            DrawingNumber = request.DrawingNumber,
            SheetNumber = request.SheetNumber,
            Discipline = request.Discipline,
            DrawingStatus = request.DrawingStatus,
            CurrentRevision = request.CurrentRevision,

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

        await _dbContext.SaveChangesAsync(cancellationToken);

        var created = await _dbContext.Documents

            .AsNoTracking()
            .SingleAsync(
                x => x.Id == document.Id,
                cancellationToken);

        return Map(created);
    }

    public async Task<DocumentResponse> UpdateAsync(
        Guid currentUserId,
        Guid documentId,
        UpdateDocumentRequest request,
        CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(currentUserId, cancellationToken);

        EnsureCanManage(actor);

        var document = await _dbContext.Documents
            .SingleOrDefaultAsync(
                x => x.Id == documentId && !x.IsDeleted,
                cancellationToken)
            ?? throw new DocumentManagementException("Document was not found.");

        EnsureCompanyAccess(actor, document.CompanyId);
        await EnsureDocumentSiteScopeAsync(
            actor, document.ConstructionSiteId, document.ProjectId, cancellationToken);
        await EnsureDocumentSiteScopeAsync(
            actor, request.ConstructionSiteId, request.ProjectId, cancellationToken);

        Validate(
            request.DocumentNumber,
            request.Name,
            request.FileName,
            request.StoragePath,
            request.FileSizeBytes,
            request.IssueDate,
            request.ExpiryDate);

        var normalizedNumber = request.DocumentNumber.Trim();

        var duplicate = await _dbContext.Documents.AnyAsync(
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

        document.DrawingNumber = request.DrawingNumber;
        document.SheetNumber = request.SheetNumber;
        document.Discipline = request.Discipline;
        document.DrawingStatus = request.DrawingStatus;
        document.CurrentRevision = request.CurrentRevision;

        document.FileName = request.FileName.Trim();
        var fileName = Path.GetFileName(request.StoragePath);

        document.StoragePath = $"/uploads/documents/{fileName}";
        document.ContentType = Clean(request.ContentType);
        document.FileSizeBytes = request.FileSizeBytes;


        document.ProjectId = request.ProjectId;
        document.EmployeeId = request.EmployeeId;
        document.RelatedEntityId = request.RelatedEntityId;
        document.RelatedEntityType = Clean(request.RelatedEntityType);

        document.IssueDate = request.IssueDate;
        document.ExpiryDate = request.ExpiryDate;

        document.IsConfidential = request.IsConfidential;
        document.Description = Clean(request.Description);

        await _dbContext.SaveChangesAsync(cancellationToken);

        var updated = await _dbContext.Documents

            .AsNoTracking()
            .SingleAsync(
                x => x.Id == document.Id,
                cancellationToken);

        return Map(updated);
    }


public async Task<DocumentVersionResponse> UploadVersionAsync(
    Guid currentUserId,
    Guid documentId,
    Stream fileStream,
    string fileName,
    string? contentType,
    long fileSizeBytes,
    string? revisionNotes,
    CancellationToken cancellationToken = default)
{
    var actor = await GetActorAsync(currentUserId, cancellationToken);

    EnsureCanManage(actor);

    var document = await _dbContext.Documents
        .SingleOrDefaultAsync(
            x => x.Id == documentId && !x.IsDeleted,
            cancellationToken)
        ?? throw new DocumentManagementException("Document not found.");

    EnsureCompanyAccess(actor, document.CompanyId);
    await EnsureDocumentSiteScopeAsync(
        actor, document.ConstructionSiteId, document.ProjectId, cancellationToken);

    var uploads = Path.Combine(
        Directory.GetCurrentDirectory(),
        "wwwroot",
        "uploads",
        "documents");

    Directory.CreateDirectory(uploads);

    var storedName =
        $"{Guid.NewGuid()}{Path.GetExtension(fileName)}";

    var fullPath = Path.Combine(uploads, storedName);

    await using var stream = File.Create(fullPath);
    await fileStream.CopyToAsync(stream, cancellationToken);

    var nextVersion = await _dbContext.DocumentVersions
        .Where(x => x.DocumentId == documentId)
        .CountAsync(cancellationToken) + 1;

    var currentVersions = await _dbContext.DocumentVersions
        .Where(x => x.DocumentId == documentId && x.IsCurrent)
        .ToListAsync(cancellationToken);

    foreach (var v in currentVersions)
        v.IsCurrent = false;

    var version = new DocumentVersion
    {
        DocumentId = documentId,
        VersionNumber = nextVersion,
        FileName = fileName,
        StoragePath = $"/uploads/documents/{storedName}",
        ContentType = contentType,
        FileSizeBytes = fileSizeBytes,
        RevisionNotes = revisionNotes,
        IsCurrent = true,
        CreatedAtUtc = DateTime.UtcNow
    };

    _dbContext.DocumentVersions.Add(version);

    document.CurrentRevision = version.VersionNumber.ToString();
    document.UpdatedAtUtc = DateTime.UtcNow;

    await _dbContext.SaveChangesAsync(cancellationToken);

    return new DocumentVersionResponse
    {
        Id = version.Id,
        VersionNumber = version.VersionNumber,
        FileName = version.FileName,
        StoragePath = version.StoragePath,
        ContentType = version.ContentType,
        FileSizeBytes = version.FileSizeBytes,
        RevisionNotes = version.RevisionNotes,
        IsCurrent = version.IsCurrent,
        CreatedAtUtc = version.CreatedAtUtc
    };
}

    private async Task<User> GetActorAsync(
        Guid currentUserId,
        CancellationToken cancellationToken)
    {
        return await _dbContext.Users
            .Include(x => x.UserRoles)
                .ThenInclude(x => x.Role)
                    .ThenInclude(role => role.GranularPermissions)
            .SingleOrDefaultAsync(
                x => x.Id == currentUserId,
                cancellationToken)
            ?? throw new DocumentManagementException(
                "Authenticated user was not found.");
    }

    private static void EnsureCanView(User actor)
    {
        if (HasCompliancePermission(actor, GranularPermission.Compliance_View) ||
            HasCompliancePermission(actor, GranularPermission.Compliance_Manage))
        {
            return;
        }

        throw new DocumentManagementException(
            "You are not authorized to view documents.");
    }

    private static void EnsureCanManage(User actor)
    {
        if (HasCompliancePermission(actor, GranularPermission.Compliance_Manage))
        {
            return;
        }

        throw new DocumentManagementException(
            "You are not authorized to manage documents.");
    }

    private static void EnsureCompanyAccess(User actor, Guid companyId)
    {
        if (IsSuperAdmin(actor))
            return;

        if (!actor.CompanyId.HasValue ||
            actor.CompanyId.Value != companyId)
        {
            throw new DocumentManagementException(
                "You are not authorized to access this document.");
        }
    }

    private static Guid GetActorCompanyId(User actor)
    {
        if (!actor.CompanyId.HasValue)
        {
            throw new DocumentManagementException(
                "Current user is not assigned to a company.");
        }

        return actor.CompanyId.Value;
    }

    private async Task EnsureDocumentSiteScopeAsync(
        User actor,
        Guid? siteId,
        Guid? projectId,
        CancellationToken cancellationToken)
    {
        if (IsSuperAdmin(actor)) return;
        var assignedSiteIds = await GetAuthorizedSiteIdsAsync(actor, cancellationToken);
        if (assignedSiteIds.Count == 0) return;

        var effectiveSiteId = siteId;
        if (!effectiveSiteId.HasValue && projectId.HasValue)
        {
            effectiveSiteId = await _dbContext.Projects
                .Where(project => project.Id == projectId.Value &&
                                  project.CompanyId == actor.CompanyId)
                .Select(project => (Guid?)project.ConstructionSiteId)
                .SingleOrDefaultAsync(cancellationToken);
        }

        if (!effectiveSiteId.HasValue || !assignedSiteIds.Contains(effectiveSiteId.Value))
        {
            throw new DocumentManagementException(
                "Company-level documents and documents outside your assigned sites are not accessible.");
        }
    }

    private Task<List<Guid>> GetAuthorizedSiteIdsAsync(
        User actor,
        CancellationToken cancellationToken)
    {
        if (!actor.CompanyId.HasValue)
            return Task.FromResult(new List<Guid>());

        return _dbContext.UserSiteAccesses
            .AsNoTracking()
            .Where(access => access.UserId == actor.Id &&
                             access.CompanyId == actor.CompanyId.Value &&
                             access.IsActive && !access.IsDeleted)
            .Select(access => access.SiteId)
            .Distinct()
            .ToListAsync(cancellationToken);
    }

    private static bool HasCompliancePermission(User actor, GranularPermission permission) =>
        actor.UserRoles.Any(userRole => !userRole.IsDeleted && !userRole.Role.IsDeleted &&
            userRole.Role.GranularPermissions.Any(rolePermission =>
                rolePermission.Permission == permission));

    private static bool IsSuperAdmin(User actor)
        => HasRole(actor, AppRoles.SuperAdmin);

    private static bool HasRole(User actor, string roleName)
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
            throw new DocumentManagementException("Document number is required.");

        if (documentNumber.Trim().Length > 50)
            throw new DocumentManagementException("Document number cannot exceed 50 characters.");

        if (string.IsNullOrWhiteSpace(name))
            throw new DocumentManagementException("Document name is required.");

        if (name.Trim().Length > 250)
            throw new DocumentManagementException("Document name cannot exceed 250 characters.");

        if (string.IsNullOrWhiteSpace(fileName))
            throw new DocumentManagementException("File name is required.");

        if (fileName.Trim().Length > 255)
            throw new DocumentManagementException("File name cannot exceed 255 characters.");

        if (string.IsNullOrWhiteSpace(storagePath))
            throw new DocumentManagementException("Storage path is required.");

        if (storagePath.Trim().Length > 1000)
            throw new DocumentManagementException("Storage path cannot exceed 1000 characters.");

        if (fileSizeBytes < 0)
            throw new DocumentManagementException("File size cannot be negative.");

        if (issueDate.HasValue &&
            expiryDate.HasValue &&
            expiryDate.Value < issueDate.Value)
        {
            throw new DocumentManagementException(
                "Expiry date cannot be earlier than issue date.");
        }
    }

    private static string? Clean(string? value)
    {
        return string.IsNullOrWhiteSpace(value)
            ? null
            : value.Trim();
    }

    private static DocumentResponse Map(Document document)
    {
        return new DocumentResponse
        {
            Id = document.Id,
            CompanyId = document.CompanyId,
            ConstructionSiteName = null,
            DocumentNumber = document.DocumentNumber,
            Name = document.Name,
            DocumentType = document.DocumentType,

            DrawingNumber = document.DrawingNumber,
            SheetNumber = document.SheetNumber,
            Discipline = document.Discipline,
            DrawingStatus = document.DrawingStatus,
            CurrentRevision = document.CurrentRevision,

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
