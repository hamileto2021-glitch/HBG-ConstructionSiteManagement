using CSM.Application.Projects.ProjectDelays;
using CSM.Application.Projects.ProjectDelays.Dtos;
using CSM.Domain.Entities.Projects;
using CSM.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using System.Linq.Expressions;
using CSM.Domain.Enums;

namespace CSM.Infrastructure.Services;

public sealed class ProjectDelayService : IProjectDelayService
{
    private readonly ApplicationDbContext _context;

    public ProjectDelayService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<IReadOnlyCollection<ProjectDelayResponse>> GetAllAsync(
        Guid currentUserId,
        Guid? projectId,
        Guid? siteId,
        CancellationToken cancellationToken = default)
    {
        var scope = await ProjectDataAccess.GetScopeAsync(
            _context,
            currentUserId,
            cancellationToken);

        var query = _context.ProjectDelays
            .AsNoTracking()
            .Where(x =>
                !x.IsDeleted &&
                x.CompanyId == scope.CompanyId &&
                (scope.CanAccessAllSites ||
                 scope.AccessibleSiteIds.Contains(
                     x.Project.ConstructionSiteId)));

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
            query = query.Where(
                x => x.Project.ConstructionSiteId == siteId.Value);
        }

        return await query
            .OrderByDescending(x => x.DelayDate)
            .Select(MapToResponse)
            .ToListAsync(cancellationToken);
    }

    public async Task<ProjectDelayResponse?> GetByIdAsync(
        Guid currentUserId,
        Guid delayId,
        CancellationToken cancellationToken = default)
    {
        var scope = await ProjectDataAccess.GetScopeAsync(
            _context,
            currentUserId,
            cancellationToken);

        return await _context.ProjectDelays
            .AsNoTracking()
            .Where(x =>
                x.Id == delayId &&
                !x.IsDeleted &&
                x.CompanyId == scope.CompanyId &&
                (scope.CanAccessAllSites ||
                 scope.AccessibleSiteIds.Contains(
                     x.Project.ConstructionSiteId)))
            .Select(MapToResponse)
            .FirstOrDefaultAsync(cancellationToken);
    }

    public async Task<ProjectDelayResponse> CreateAsync(
        Guid currentUserId,
        CreateProjectDelayRequest request,
        CancellationToken cancellationToken = default)
    {
        var scope = await ProjectDataAccess.GetScopeAsync(
            _context,
            currentUserId,
            cancellationToken);
        var siteId = await ProjectDataAccess.EnsureProjectAccessAsync(
            _context,
            scope,
            request.ProjectId,
            cancellationToken);

        var delay = new ProjectDelay
        {
            CompanyId = scope.CompanyId,
            ProjectId = request.ProjectId,
            DelayDate = request.DelayDate.ToDateTime(TimeOnly.MinValue),
            Category = request.Category.ToString(),
            Title = request.Title,
            Description = request.Description,
            DelayDays = request.TimeImpactDays,
            ActionTaken = request.MitigationAction,
            IsResolved = false
        };

        _context.ProjectDelays.Add(delay);
        await _context.SaveChangesAsync(cancellationToken);

        return Map(delay, siteId);
    }

    public async Task<ProjectDelayResponse?> UpdateAsync(
        Guid currentUserId,
        Guid delayId,
        UpdateProjectDelayRequest request,
        CancellationToken cancellationToken = default)
    {
        var scope = await ProjectDataAccess.GetScopeAsync(
            _context,
            currentUserId,
            cancellationToken);

        var delay = await _context.ProjectDelays
            .Include(x => x.Project)
            .FirstOrDefaultAsync(
                x => x.Id == delayId &&
                     !x.IsDeleted &&
                     x.CompanyId == scope.CompanyId &&
                     (scope.CanAccessAllSites ||
                      scope.AccessibleSiteIds.Contains(
                          x.Project.ConstructionSiteId)),
                cancellationToken);

        if (delay is null)
            return null;

        delay.DelayDate = request.DelayDate.ToDateTime(TimeOnly.MinValue);
        delay.Category = request.Category.ToString();
        delay.Title = request.Title;
        delay.Description = request.Description;
        delay.DelayDays = request.TimeImpactDays;
        delay.ActionTaken = request.MitigationAction;
        delay.IsResolved = request.IsResolved;
        delay.ResolvedDate = request.IsResolved
            ? DateTime.UtcNow
            : null;

        await _context.SaveChangesAsync(cancellationToken);

        return Map(delay, delay.Project.ConstructionSiteId);
    }

    public async Task<bool> DeleteAsync(
        Guid currentUserId,
        Guid delayId,
        CancellationToken cancellationToken = default)
    {
        var scope = await ProjectDataAccess.GetScopeAsync(
            _context,
            currentUserId,
            cancellationToken);

        var delay = await _context.ProjectDelays
            .FirstOrDefaultAsync(
                x => x.Id == delayId &&
                     !x.IsDeleted &&
                     x.CompanyId == scope.CompanyId &&
                     (scope.CanAccessAllSites ||
                      scope.AccessibleSiteIds.Contains(
                          x.Project.ConstructionSiteId)),
                cancellationToken);

        if (delay is null)
            return false;

        _context.ProjectDelays.Remove(delay);
        await _context.SaveChangesAsync(cancellationToken);

        return true;
    }

    private static ProjectDelayResponse Map(
        ProjectDelay delay,
        Guid siteId) =>
        new(
            delay.Id,
            delay.ProjectId,
            siteId,
            DateOnly.FromDateTime(delay.DelayDate),
            Enum.TryParse<CSM.Domain.Enums.DelayCategory>(
                delay.Category,
                out var category)
                ? category
                : CSM.Domain.Enums.DelayCategory.Other,
            delay.Title,
            delay.Description,
            delay.DelayDays,
            0m,
            delay.ActionTaken,
            delay.IsResolved);

    private static readonly Expression<Func<ProjectDelay, ProjectDelayResponse>>
        MapToResponse =
            delay => new ProjectDelayResponse(
                delay.Id,
                delay.ProjectId,
                delay.Project.ConstructionSiteId,
                DateOnly.FromDateTime(delay.DelayDate),
                delay.Category == "Weather" ? DelayCategory.Weather :
                delay.Category == "Material" ? DelayCategory.Material :
                delay.Category == "Labor" ? DelayCategory.Labor :
                delay.Category == "Equipment" ? DelayCategory.Equipment :
                delay.Category == "Client" ? DelayCategory.Client :
                delay.Category == "Design" ? DelayCategory.Design :
                delay.Category == "Permit" ? DelayCategory.Permit :
                DelayCategory.Other,
                delay.Title,
                delay.Description,
                delay.DelayDays,
                0m,
                delay.ActionTaken,
                delay.IsResolved);
}