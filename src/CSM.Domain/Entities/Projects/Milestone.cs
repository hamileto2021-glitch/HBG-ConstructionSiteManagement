using CSM.Domain.Common;

namespace CSM.Domain.Entities.Projects;

public class Milestone : TenantEntity
{
    public Guid ProjectId { get; set; }

    public Guid? ProjectPhaseId { get; set; }

    public string Name { get; set; } = string.Empty;

    public string? Description { get; set; }

    public string MilestoneNumber { get; set; } = string.Empty;

    public DateOnly PlannedDate { get; set; }

    public DateOnly? CompletedDate { get; set; }

    public bool IsCompleted { get; set; }

    public Project Project { get; set; } = null!;

    public ProjectPhase? ProjectPhase { get; set; }
}