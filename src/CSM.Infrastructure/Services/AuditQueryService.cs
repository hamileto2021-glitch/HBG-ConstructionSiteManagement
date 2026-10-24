using CSM.Application.Common.Audit;
using CSM.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CSM.Infrastructure.Services;

public sealed class AuditQueryService : IAuditQueryService
{
    private readonly ApplicationDbContext _context;

    public AuditQueryService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<IReadOnlyCollection<AuditLogDto>> GetLogsAsync(
        Guid companyId,
        string? module,
        DateTime? fromUtc,
        DateTime? toUtc,
        CancellationToken cancellationToken)
    {
        var query = _context.AuditLogs
            .AsNoTracking()
            .Where(x => x.CompanyId == companyId);

        if (!string.IsNullOrWhiteSpace(module))
        {
            query = query.Where(x => x.Module == module);
        }

        if (fromUtc.HasValue)
        {
            query = query.Where(x => x.CreatedAtUtc >= fromUtc.Value);
        }

        if (toUtc.HasValue)
        {
            query = query.Where(x => x.CreatedAtUtc <= toUtc.Value);
        }

        return await query
            .OrderByDescending(x => x.CreatedAtUtc)
            .Select(x => new AuditLogDto
            {
                Id = x.Id,
                UserName = x.UserName,
                Module = x.Module,
                Action = x.Action,
                EntityName = x.EntityName,
                Description = x.Description,
                CreatedAtUtc = x.CreatedAtUtc
            })
            .ToListAsync(cancellationToken);
    }
}