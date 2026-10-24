using System.Linq.Expressions;
using CSM.Application.Projects.WbsTasks;
using CSM.Application.Projects.WbsTasks.Dtos;
using CSM.Domain.Entities.Projects;
using CSM.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CSM.Infrastructure.Services;

public sealed class WbsTaskService : IWbsTaskService
{
    private readonly ApplicationDbContext _context;

    public WbsTaskService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<IReadOnlyCollection<WbsTaskResponse>> GetAllAsync(
        Guid currentUserId,
        CancellationToken cancellationToken = default)
    {
        var scope = await ProjectDataAccess.GetScopeAsync(
            _context,
            currentUserId,
            cancellationToken);

        return await _context.WbsTasks
            .AsNoTracking()
            .Where(x =>
                x.CompanyId == scope.CompanyId &&
                (scope.CanAccessAllSites ||
                 scope.AccessibleSiteIds.Contains(
                     x.Project.ConstructionSiteId)))
            .OrderBy(x => x.TaskCode)
            .Select(MapToResponse)
            .ToListAsync(cancellationToken);
    }

    public async Task<WbsTaskResponse?> GetByIdAsync(
        Guid currentUserId,
        Guid taskId,
        CancellationToken cancellationToken = default)
    {
        var scope = await ProjectDataAccess.GetScopeAsync(
            _context,
            currentUserId,
            cancellationToken);

        return await _context.WbsTasks
            .AsNoTracking()
            .Where(x =>
                x.Id == taskId &&
                x.CompanyId == scope.CompanyId &&
                (scope.CanAccessAllSites ||
                 scope.AccessibleSiteIds.Contains(
                     x.Project.ConstructionSiteId)))
            .Select(MapToResponse)
            .FirstOrDefaultAsync(cancellationToken);
    }

    public async Task<WbsTaskResponse> CreateAsync(
        Guid currentUserId,
        CreateWbsTaskRequest request,
        CancellationToken cancellationToken = default)
    {
        var scope = await ProjectDataAccess.GetScopeAsync(
            _context,
            currentUserId,
            cancellationToken);
        await ProjectDataAccess.EnsureProjectAccessAsync(
            _context,
            scope,
            request.ProjectId,
            cancellationToken);

        if (request.MilestoneId != Guid.Empty &&
            !await _context.Milestones.AnyAsync(
                milestone =>
                    milestone.Id == request.MilestoneId &&
                    milestone.ProjectId == request.ProjectId &&
                    milestone.CompanyId == scope.CompanyId,
                cancellationToken))
        {
            throw new UnauthorizedAccessException(
                "The milestone is not available in this project.");
        }

        if (request.AssignedEmployeeId.HasValue &&
            !await _context.Employees.AnyAsync(
                employee =>
                    employee.Id == request.AssignedEmployeeId.Value &&
                    employee.CompanyId == scope.CompanyId,
                cancellationToken))
        {
            throw new UnauthorizedAccessException(
                "The employee is not available in this company.");
        }

        var task = new WbsTask
        {
            CompanyId = scope.CompanyId,

            ProjectId = request.ProjectId,
            MilestoneId = request.MilestoneId == Guid.Empty
                ? null
                : request.MilestoneId,
            AssignedEmployeeId = request.AssignedEmployeeId,

            TaskCode = request.TaskCode,
            Name = request.Name,
            Description = request.Description,

            PlannedStartDate = request.PlannedStartDate,
            PlannedFinishDate = request.PlannedFinishDate,
            ActualStartDate = request.ActualStartDate,
            ActualFinishDate = request.ActualFinishDate,

            Status = request.Status,
            Priority = request.Priority,

            ProgressPercentage = request.ProgressPercentage,
            EstimatedHours = request.EstimatedHours,
            ActualHours = request.ActualHours
        };

        _context.WbsTasks.Add(task);
        await _context.SaveChangesAsync(cancellationToken);

        return MapToResponse.Compile()(task);
    }

    private static readonly Expression<Func<WbsTask, WbsTaskResponse>>
        MapToResponse = task => new WbsTaskResponse
        {
            Id = task.Id,
            CompanyId = task.CompanyId,

            ProjectId = task.ProjectId,
            MilestoneId = task.MilestoneId,
            AssignedEmployeeId = task.AssignedEmployeeId,

            TaskCode = task.TaskCode,
            Name = task.Name,
            Description = task.Description,

            PlannedStartDate = task.PlannedStartDate,
            PlannedFinishDate = task.PlannedFinishDate,
            ActualStartDate = task.ActualStartDate,
            ActualFinishDate = task.ActualFinishDate,

            Status = task.Status,
            Priority = task.Priority,

            ProgressPercentage = task.ProgressPercentage,
            EstimatedHours = task.EstimatedHours,
            ActualHours = task.ActualHours
        };
}