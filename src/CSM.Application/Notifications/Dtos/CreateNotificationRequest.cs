using CSM.Domain.Enums;

namespace CSM.Application.Notifications.Dtos;

public sealed record CreateNotificationRequest(
    Guid UserId,
    string Title,
    string Message,
    NotificationType Type,
    string? RelatedEntityType,
    Guid? RelatedEntityId);
