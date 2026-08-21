using CSM.Domain.Enums;

namespace CSM.Application.Notifications.Dtos;

public sealed record NotificationResponse(
    Guid Id,
    Guid UserId,
    string Title,
    string Message,
    NotificationType Type,
    bool IsRead,
    DateTime? ReadAtUtc,
    string? RelatedEntityType,
    Guid? RelatedEntityId,
    DateTime CreatedAtUtc);
