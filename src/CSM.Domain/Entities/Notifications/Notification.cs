using CSM.Domain.Common;
using CSM.Domain.Entities.Identity;
using CSM.Domain.Enums;

namespace CSM.Domain.Entities.Notifications;

public class Notification : TenantEntity
{
    public Guid UserId { get; set; }

    public string Title { get; set; } = string.Empty;

    public string Message { get; set; } = string.Empty;

    public NotificationType Type { get; set; } = NotificationType.Info;

    public bool IsRead { get; set; }

    public DateTime? ReadAtUtc { get; set; }

    public string? RelatedEntityType { get; set; }

    public Guid? RelatedEntityId { get; set; }

    public User User { get; set; } = null!;
}
