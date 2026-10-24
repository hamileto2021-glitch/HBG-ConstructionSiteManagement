using CSM.Application.Projects.DailySiteDiaries;
using CSM.Application.Projects.DailySiteDiaries.Dtos;
using CSM.Domain.Entities.Projects;
using CSM.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CSM.Infrastructure.Services;

public sealed class DailySiteDiaryService : IDailySiteDiaryService
{
    private readonly ApplicationDbContext _context;

    public DailySiteDiaryService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<IReadOnlyCollection<DailySiteDiaryResponse>> GetAllAsync(
        Guid currentUserId,
        Guid? projectId,
        Guid? siteId,
        CancellationToken cancellationToken = default)
    {
        var scope = await ProjectDataAccess.GetScopeAsync(
            _context,
            currentUserId,
            cancellationToken);

        var query = _context.DailySiteDiaries
            .AsNoTracking()
            .Where(x =>
                x.CompanyId == scope.CompanyId &&
                (scope.CanAccessAllSites ||
                 scope.AccessibleSiteIds.Contains(x.SiteId)));

        if (projectId.HasValue)
        {
            await ProjectDataAccess.EnsureProjectAccessAsync(
                _context,
                scope,
                projectId.Value,
                cancellationToken);
            query = query.Where(x => x.ProjectId == projectId.Value);
        }

        if (siteId.HasValue)
        {
            await ProjectDataAccess.EnsureSiteAccessAsync(
                _context,
                scope,
                siteId.Value,
                cancellationToken);
            query = query.Where(x => x.SiteId == siteId.Value);
        }

        var diaries = await query
            .OrderByDescending(x => x.DiaryDate)
            .ToListAsync(cancellationToken);

        return diaries
            .Select(MapToResponse.Compile())
            .ToList();
    }

    public async Task<DailySiteDiaryResponse?> GetByIdAsync(
        Guid currentUserId,
        Guid diaryId,
        CancellationToken cancellationToken = default)
    {
        var scope = await ProjectDataAccess.GetScopeAsync(
            _context,
            currentUserId,
            cancellationToken);

        return await _context.DailySiteDiaries
            .AsNoTracking()
            .Where(x =>
                x.Id == diaryId &&
                x.CompanyId == scope.CompanyId &&
                (scope.CanAccessAllSites ||
                 scope.AccessibleSiteIds.Contains(x.SiteId)))
            .Select(MapToResponse)
            .FirstOrDefaultAsync(cancellationToken);
    }

    public async Task<DailySiteDiaryResponse> CreateAsync(
        Guid currentUserId,
        CreateDailySiteDiaryRequest request,
        CancellationToken cancellationToken = default)
    {
        var scope = await ProjectDataAccess.GetScopeAsync(
            _context,
            currentUserId,
            cancellationToken);
        await ProjectDataAccess.EnsureSiteAccessAsync(
            _context,
            scope,
            request.SiteId,
            cancellationToken);
        if (request.ProjectId.HasValue)
        {
            var projectSiteId =
                await ProjectDataAccess.EnsureProjectAccessAsync(
                    _context,
                    scope,
                    request.ProjectId.Value,
                    cancellationToken);
            if (projectSiteId != request.SiteId)
            {
                throw new UnauthorizedAccessException(
                    "The project does not belong to the selected site.");
            }
        }

        var diary = new DailySiteDiary
        {
            CompanyId = scope.CompanyId,
            SiteId = request.SiteId,
            ProjectId = request.ProjectId,
            DiaryDate = request.DiaryDate,
            Weather = request.Weather,
            Temperature = request.Temperature,
            WorkforceCount = request.WorkforceCount,
            EquipmentInUse = request.EquipmentInUse,
            WorkPerformed = request.WorkPerformed,
            DelayReason = request.DelayReason,
            SafetyObservation = request.SafetyObservation
        };

        _context.DailySiteDiaries.Add(diary);
        await _context.SaveChangesAsync(cancellationToken);

        return MapToResponse.Compile()(diary);
    }

    public async Task<DailySiteDiaryResponse?> UpdateAsync(
        Guid currentUserId,
        Guid diaryId,
        UpdateDailySiteDiaryRequest request,
        CancellationToken cancellationToken = default)
    {
        var scope = await ProjectDataAccess.GetScopeAsync(
            _context,
            currentUserId,
            cancellationToken);

        var diary = await _context.DailySiteDiaries
            .FirstOrDefaultAsync(
                x => x.Id == diaryId &&
                     x.CompanyId == scope.CompanyId &&
                     (scope.CanAccessAllSites ||
                      scope.AccessibleSiteIds.Contains(x.SiteId)),
                cancellationToken);

        if (diary is null)
            return null;

        await ProjectDataAccess.EnsureSiteAccessAsync(
            _context,
            scope,
            request.SiteId,
            cancellationToken);
        if (request.ProjectId.HasValue)
        {
            var projectSiteId =
                await ProjectDataAccess.EnsureProjectAccessAsync(
                    _context,
                    scope,
                    request.ProjectId.Value,
                    cancellationToken);
            if (projectSiteId != request.SiteId)
            {
                throw new UnauthorizedAccessException(
                    "The project does not belong to the selected site.");
            }
        }

        diary.SiteId = request.SiteId;
        diary.ProjectId = request.ProjectId;
        diary.DiaryDate = request.DiaryDate;
        diary.Weather = request.Weather;
        diary.Temperature = request.Temperature;
        diary.WorkforceCount = request.WorkforceCount;
        diary.EquipmentInUse = request.EquipmentInUse;
        diary.WorkPerformed = request.WorkPerformed;
        diary.DelayReason = request.DelayReason;
        diary.SafetyObservation = request.SafetyObservation;

        await _context.SaveChangesAsync(cancellationToken);

        return await GetByIdAsync(currentUserId, diaryId, cancellationToken);
    }

   public async Task<bool> DeleteAsync(
       Guid currentUserId,
       Guid diaryId,
       CancellationToken cancellationToken = default)
   {
       var scope = await ProjectDataAccess.GetScopeAsync(
           _context,
           currentUserId,
           cancellationToken);

       var rows = await _context.DailySiteDiaries
           .Where(x =>
               x.Id == diaryId &&
               x.CompanyId == scope.CompanyId &&
               (scope.CanAccessAllSites ||
                scope.AccessibleSiteIds.Contains(x.SiteId)))
           .ExecuteDeleteAsync(cancellationToken);

       return rows > 0;
   }

    private static readonly System.Linq.Expressions.Expression<
        Func<DailySiteDiary, DailySiteDiaryResponse>> MapToResponse =
        diary => new DailySiteDiaryResponse
        {
            Id = diary.Id,
            TenantId = diary.CompanyId,
            SiteId = diary.SiteId,
            ProjectId = diary.ProjectId,
            DiaryDate = diary.DiaryDate,
            Weather = diary.Weather,
            Temperature = diary.Temperature,
            WorkforceCount = diary.WorkforceCount,
            EquipmentInUse = diary.EquipmentInUse,
            WorkPerformed = diary.WorkPerformed,
            DelayReason = diary.DelayReason,
            SafetyObservation = diary.SafetyObservation
        };
}