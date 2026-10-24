using CSM.Application.Projects.DailyProgressPhotos.Dtos;

namespace CSM.Application.Projects.DailyProgressPhotos;

public interface IDailyProgressPhotoService
{
    Task<IReadOnlyCollection<DailyProgressPhotoResponse>> GetByDiaryAsync(
        Guid companyId,
        Guid diaryId,
        CancellationToken cancellationToken = default);

    Task<DailyProgressPhotoResponse> UploadAsync(
        Guid currentUserId,
        Guid diaryId,
        Stream fileStream,
        string? caption,
        CancellationToken cancellationToken = default);

    Task DeleteAsync(
        Guid currentUserId,
        Guid photoId,
        CancellationToken cancellationToken = default);

    Task<DailyProgressPhotoContent?> GetContentAsync(
        Guid currentUserId,
        Guid photoId,
        CancellationToken cancellationToken = default);
}