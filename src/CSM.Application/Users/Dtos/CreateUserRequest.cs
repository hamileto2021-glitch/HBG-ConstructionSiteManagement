namespace CSM.Application.Users.Dtos;

public sealed record CreateUserRequest(
    Guid? CompanyId,
    Guid? EmployeeId,
    string Email,
    string FirstName,
    string LastName,
    string TemporaryPassword,
    IReadOnlyCollection<string> Roles);