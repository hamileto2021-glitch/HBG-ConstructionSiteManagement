namespace CSM.Application.Projects.Dtos;

public sealed record UpdateProjectRequest(
    string Name,
    string? Description,
    DateOnly? PlannedStartDate,
    DateOnly? PlannedEndDate,
    decimal ContractValue);