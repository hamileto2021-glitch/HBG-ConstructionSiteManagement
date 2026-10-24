using CSM.Application.Projects.DailyProgressPhotos;
using CSM.Application.Projects.DailyProgressPhotos.Dtos;
using CSM.Domain.Entities.Projects;
using CSM.Infrastructure.Persistence;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;

namespace CSM.Infrastructure.Services;

public sealed class DailyProgressPhotoService : IDailyProgressPhotoService
{
    private const int MaxFileSizeBytes = 25_000_000;
    private readonly ApplicationDbContext _context;
    private readonly string _uploadFolder;
    private readonly string _legacyUploadFolder;

    public DailyProgressPhotoService(
        ApplicationDbContext context,
        IWebHostEnvironment environment)
    {
        _context = context;
        _uploadFolder = Path.Combine(
            environment.ContentRootPath,
            "App_Data",
            "daily-progress");
        _legacyUploadFolder = Path.Combine(
            environment.WebRootPath ??
                Path.Combine(environment.ContentRootPath, "wwwroot"),
            "uploads",
            "daily-progress");
    }

    public async Task<IReadOnlyCollection<DailyProgressPhotoResponse>> GetByDiaryAsync(
        Guid currentUserId,
        Guid diaryId,
        CancellationToken cancellationToken = default)
    {
        var scope = await ProjectDataAccess.GetScopeAsync(
            _context,
            currentUserId,
            cancellationToken);
        await EnsureDiaryAccessAsync(
            scope,
            diaryId,
            cancellationToken);

        return await _context.DailyProgressPhotos
            .AsNoTracking()
            .Where(x =>
                x.DailySiteDiaryId == diaryId &&
                x.CompanyId == scope.CompanyId &&
                !x.IsDeleted)
            .OrderByDescending(x => x.UploadedAtUtc)
            .Select(x => new DailyProgressPhotoResponse(
                x.Id,
                x.DailySiteDiaryId,
                x.FileName,
                $"/api/daily-progress-photos/{x.Id}/content",
                x.Caption,
                x.UploadedAtUtc))
            .ToListAsync(cancellationToken);
    }

    public async Task<DailyProgressPhotoResponse> UploadAsync(
        Guid currentUserId,
        Guid diaryId,
        Stream fileStream,
        string? caption,
        CancellationToken cancellationToken = default)
    {
        var scope = await ProjectDataAccess.GetScopeAsync(
            _context,
            currentUserId,
            cancellationToken);
        var diary = await EnsureDiaryAccessAsync(
            scope,
            diaryId,
            cancellationToken);

        await using var buffer = new MemoryStream();
        await fileStream.CopyToAsync(buffer, cancellationToken);
        if (buffer.Length is 0 or > MaxFileSizeBytes)
        {
            throw new InvalidDataException(
                "Photo must be smaller than 25 MB.");
        }

        var extension = GetImageExtension(buffer.GetBuffer(), buffer.Length);
        if (extension is null)
        {
            throw new InvalidDataException(
                "Only valid JPEG, PNG, and WebP images are supported.");
        }

        Directory.CreateDirectory(_uploadFolder);
        var uniqueName = $"{Guid.NewGuid():N}{extension}";
        var fullPath = Path.Combine(_uploadFolder, uniqueName);
        var photoId = Guid.NewGuid();
        var photo = new DailyProgressPhoto
        {
            Id = photoId,
            CompanyId = scope.CompanyId,
            DailySiteDiaryId = diary.Id,
            FileName = uniqueName,
            FilePath = $"/api/daily-progress-photos/{photoId}/content",
            Caption = caption,
            UploadedByUserId = currentUserId,
            UploadedAtUtc = DateTime.UtcNow
        };

        var saved = false;
        try
        {
            buffer.Position = 0;
            await using (var output = File.Create(fullPath))
            {
                await buffer.CopyToAsync(output, cancellationToken);
            }

            _context.DailyProgressPhotos.Add(photo);
            await _context.SaveChangesAsync(cancellationToken);
            saved = true;
        }
        finally
        {
            if (!saved && File.Exists(fullPath))
                File.Delete(fullPath);
        }

        return new DailyProgressPhotoResponse(
            photo.Id,
            photo.DailySiteDiaryId,
            photo.FileName,
            photo.FilePath,
            photo.Caption,
            photo.UploadedAtUtc);
    }

    public async Task<DailyProgressPhotoContent?> GetContentAsync(
        Guid currentUserId,
        Guid photoId,
        CancellationToken cancellationToken = default)
    {
        var scope = await ProjectDataAccess.GetScopeAsync(
            _context,
            currentUserId,
            cancellationToken);
        var photo = await _context.DailyProgressPhotos
            .AsNoTracking()
            .SingleOrDefaultAsync(
                x => x.Id == photoId &&
                     x.CompanyId == scope.CompanyId &&
                     !x.IsDeleted,
                cancellationToken);

        if (photo is null)
            return null;

        await EnsureDiaryAccessAsync(
            scope,
            photo.DailySiteDiaryId,
            cancellationToken);

        var safeFileName = Path.GetFileName(photo.FileName);
        var extension = Path.GetExtension(safeFileName).ToLowerInvariant();
        var contentType = extension switch
        {
            ".jpg" or ".jpeg" => "image/jpeg",
            ".png" => "image/png",
            ".webp" => "image/webp",
            ".gif" => "image/gif",
            ".bmp" => "image/bmp",
            _ => "application/octet-stream"
        };
        var fullPath = Path.Combine(_uploadFolder, safeFileName);
        if (!File.Exists(fullPath))
        {
            var legacyPath = Path.Combine(
                _legacyUploadFolder,
                safeFileName);
            if (File.Exists(legacyPath))
            {
                Directory.CreateDirectory(_uploadFolder);
                File.Move(legacyPath, fullPath, overwrite: true);
            }
        }

        if (!File.Exists(fullPath))
            return null;

        return new DailyProgressPhotoContent(
            File.OpenRead(fullPath),
            contentType,
            safeFileName);
    }

    public async Task DeleteAsync(
        Guid currentUserId,
        Guid photoId,
        CancellationToken cancellationToken = default)
    {
        var scope = await ProjectDataAccess.GetScopeAsync(
            _context,
            currentUserId,
            cancellationToken);
        var photo = await _context.DailyProgressPhotos
            .SingleOrDefaultAsync(
                x => x.Id == photoId &&
                     x.CompanyId == scope.CompanyId &&
                     !x.IsDeleted,
                cancellationToken);

        if (photo is null)
            return;

        await EnsureDiaryAccessAsync(
            scope,
            photo.DailySiteDiaryId,
            cancellationToken);

        var fullPath = Path.Combine(
            _uploadFolder,
            Path.GetFileName(photo.FileName));
        if (File.Exists(fullPath))
            File.Delete(fullPath);

        var legacyPath = Path.Combine(
            _legacyUploadFolder,
            Path.GetFileName(photo.FileName));
        if (File.Exists(legacyPath))
            File.Delete(legacyPath);

        _context.DailyProgressPhotos.Remove(photo);
        await _context.SaveChangesAsync(cancellationToken);
    }

    private async Task<DailySiteDiary> EnsureDiaryAccessAsync(
        ProjectDataScope scope,
        Guid diaryId,
        CancellationToken cancellationToken)
    {
        var diary = await _context.DailySiteDiaries
            .SingleOrDefaultAsync(
                x => x.Id == diaryId &&
                     x.CompanyId == scope.CompanyId &&
                     !x.IsDeleted,
                cancellationToken)
            ?? throw new UnauthorizedAccessException(
                "You are not authorized to access this diary.");

        await ProjectDataAccess.EnsureSiteAccessAsync(
            _context,
            scope,
            diary.SiteId,
            cancellationToken);

        return diary;
    }

    private static string? GetImageExtension(
        byte[] bytes,
        long length)
    {
        if (length >= 3 &&
            bytes[0] == 0xFF &&
            bytes[1] == 0xD8 &&
            bytes[2] == 0xFF)
        {
            return ".jpg";
        }

        if (length >= 8 &&
            bytes.AsSpan(0, 8).SequenceEqual(
                new byte[] { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A }))
        {
            return ".png";
        }

        if (length >= 12 &&
            bytes.AsSpan(0, 4).SequenceEqual("RIFF"u8) &&
            bytes.AsSpan(8, 4).SequenceEqual("WEBP"u8))
        {
            return ".webp";
        }

        return null;
    }
}
