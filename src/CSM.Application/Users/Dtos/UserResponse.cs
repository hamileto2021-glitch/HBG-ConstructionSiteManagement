namespace CSM.Application.Users.Dtos;

public sealed record UserResponse(
    Guid Id,
    Guid? CompanyId,
    Guid? EmployeeId,
    string Email,
    string FirstName,
    string LastName,
    string FullName,
    bool IsActive,
    bool MustChangePassword,
    DateTime? LastLoginAtUtc,
    IReadOnlyCollection<string> Roles,
    DateTime CreatedAtUtc);