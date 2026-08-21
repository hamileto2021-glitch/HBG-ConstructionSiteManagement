namespace CSM.Application.Users.Dtos;

public sealed record UpdateUserRequest(
    string FirstName,
    string LastName,
    Guid? EmployeeId);