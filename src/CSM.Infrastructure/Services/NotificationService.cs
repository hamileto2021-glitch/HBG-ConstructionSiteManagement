using CSM.Application.Common.Exceptions;
using CSM.Application.Notifications;
using CSM.Application.Notifications.Dtos;
using CSM.Domain.Entities.Identity;
using CSM.Domain.Entities.Notifications;
using CSM.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CSM.Infrastructure.Services;

public sealed class NotificationService : INotificationService
{
    private readonly ApplicationDbContext _dbContext;

    public NotificationService(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<IReadOnlyCollection<NotificationResponse>> GetAllAsync(
        Guid currentUserId,
        bool? isRead,
        CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(
            currentUserId,
            cancellationToken);

        var query = _dbContext.Notifications
            .AsNoTracking()
            .Where(
                x =>
                    x.CompanyId == actor.CompanyId &&
                    x.UserId == currentUserId);

        if (isRead.HasValue)
        {
            query = query.Where(
                x => x.IsRead == isRead.Value);
        }

        return await query
            .OrderByDescending(x => x.CreatedAtUtc)
            .Select(
                x =>
                    new NotificationResponse(
                        x.Id,
                        x.UserId,
                        x.Title,
                        x.Message,
                        x.Type,
                        x.IsRead,
                        x.ReadAtUtc,
                        x.RelatedEntityType,
                        x.RelatedEntityId,
                        x.CreatedAtUtc))
            .ToListAsync(cancellationToken);
    }

    public async Task<int> GetUnreadCountAsync(
        Guid currentUserId,
        CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(
            currentUserId,
            cancellationToken);

        return await _dbContext.Notifications
            .AsNoTracking()
            .CountAsync(
                x =>
                    x.CompanyId == actor.CompanyId &&
                    x.UserId == currentUserId &&
                    !x.IsRead,
                cancellationToken);
    }

    public async Task<NotificationResponse> CreateAsync(
        Guid currentUserId,
        CreateNotificationRequest request,
        CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(
            currentUserId,
            cancellationToken);

        if (!actor.CompanyId.HasValue)
        {
            throw new NotificationManagementException(
                "Current user is not assigned to a company.");
        }

        var recipient = await _dbContext.Users
            .AsNoTracking()
            .SingleOrDefaultAsync(
                x =>
                    x.Id == request.UserId &&
                    x.CompanyId == actor.CompanyId &&
                    x.IsActive,
                cancellationToken);

        if (recipient is null)
        {
            throw new NotificationManagementException(
                "Notification recipient was not found in the current company.");
        }

        if (string.IsNullOrWhiteSpace(request.Title))
        {
            throw new NotificationManagementException(
                "Notification title is required.");
        }

        if (string.IsNullOrWhiteSpace(request.Message))
        {
            throw new NotificationManagementException(
                "Notification message is required.");
        }

        var notification = new Notification
        {
            CompanyId = actor.CompanyId.Value,
            UserId = recipient.Id,
            Title = request.Title.Trim(),
            Message = request.Message.Trim(),
            Type = request.Type,
            RelatedEntityType =
                string.IsNullOrWhiteSpace(request.RelatedEntityType)
                    ? null
                    : request.RelatedEntityType.Trim(),
            RelatedEntityId = request.RelatedEntityId,
            IsRead = false
        };

        _dbContext.Notifications.Add(notification);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return ToResponse(notification);
    }

    public async Task<NotificationResponse> MarkReadAsync(
        Guid currentUserId,
        Guid notificationId,
        MarkNotificationReadRequest request,
        CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(
            currentUserId,
            cancellationToken);

        var notification = await _dbContext.Notifications
            .SingleOrDefaultAsync(
                x =>
                    x.Id == notificationId &&
                    x.CompanyId == actor.CompanyId &&
                    x.UserId == currentUserId,
                cancellationToken);

        if (notification is null)
        {
            throw new NotificationManagementException(
                "Notification was not found.");
        }

        notification.IsRead = request.IsRead;
        notification.ReadAtUtc =
            request.IsRead
                ? DateTime.UtcNow
                : null;

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return ToResponse(notification);
    }

    private async Task<User> GetActorAsync(
        Guid currentUserId,
        CancellationToken cancellationToken)
    {
        return await _dbContext.Users
            .SingleOrDefaultAsync(
                x => x.Id == currentUserId,
                cancellationToken)
            ?? throw new NotificationManagementException(
                "Authenticated user was not found.");
    }

    private static NotificationResponse ToResponse(
        Notification notification)
    {
        return new NotificationResponse(
            notification.Id,
            notification.UserId,
            notification.Title,
            notification.Message,
            notification.Type,
            notification.IsRead,
            notification.ReadAtUtc,
            notification.RelatedEntityType,
            notification.RelatedEntityId,
            notification.CreatedAtUtc);
    }
}
