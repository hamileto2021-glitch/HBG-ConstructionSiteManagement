using CSM.Application.Common.Exceptions;
using CSM.Application.Common.Security;
using CSM.Application.Users;
using CSM.Application.Users.Dtos;
using CSM.Domain.Constants;
using CSM.Domain.Entities.Identity;
using CSM.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CSM.Infrastructure.Services;

public sealed class UserService : IUserService
{
    private readonly ApplicationDbContext _dbContext;
    private readonly IPasswordHasher _passwordHasher;

    public UserService(
        ApplicationDbContext dbContext,
        IPasswordHasher passwordHasher)
    {
        _dbContext = dbContext;
        _passwordHasher = passwordHasher;
    }

    public async Task<IReadOnlyCollection<UserResponse>> GetAllAsync(
        Guid currentUserId,
        CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(
            currentUserId,
            cancellationToken);

        IQueryable<User> query = _dbContext.Users
            .AsNoTracking()
            .Include(x => x.UserRoles)
                .ThenInclude(x => x.Role);

        if (!IsSuperAdmin(actor))
        {
            EnsureCompanyAdmin(actor);

            query = query.Where(
                x => x.CompanyId == actor.CompanyId);
        }

        var users = await query
            .OrderBy(x => x.FirstName)
            .ThenBy(x => x.LastName)
            .ToListAsync(cancellationToken);

        return users
            .Select(Map)
            .ToArray();
    }

    public async Task<UserResponse> GetByIdAsync(
        Guid currentUserId,
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(
            currentUserId,
            cancellationToken);

        var target = await GetUserAsync(
            userId,
            cancellationToken);

        EnsureCanManage(actor, target);

        return Map(target);
    }

    public async Task<UserResponse> CreateAsync(
        Guid currentUserId,
        CreateUserRequest request,
        CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(
            currentUserId,
            cancellationToken);

        ValidateBasicInput(request);
        ValidatePassword(request.TemporaryPassword);

        var requestedRoles = NormalizeRoles(request.Roles);

        if (requestedRoles.Count == 0)
        {
            throw new UserManagementException(
                "At least one role is required.");
        }

        var actorIsSuperAdmin = IsSuperAdmin(actor);

        if (!actorIsSuperAdmin)
        {
            EnsureCompanyAdmin(actor);

            if (!actor.CompanyId.HasValue)
            {
                throw new UserManagementException(
                    "Company administrator is not assigned to a company.");
            }

            if (request.CompanyId != actor.CompanyId)
            {
                throw new UserManagementException(
                    "You can only create users in your own company.");
            }

            if (requestedRoles.Contains(
                    AppRoles.SuperAdmin,
                    StringComparer.OrdinalIgnoreCase))
            {
                throw new UserManagementException(
                    "Company administrators cannot assign the SuperAdmin role.");
            }
        }

        if (requestedRoles.Contains(
                AppRoles.SuperAdmin,
                StringComparer.OrdinalIgnoreCase) &&
            request.CompanyId.HasValue)
        {
            throw new UserManagementException(
                "SuperAdmin users must not belong to a company.");
        }

        if (!requestedRoles.Contains(
                AppRoles.SuperAdmin,
                StringComparer.OrdinalIgnoreCase) &&
            !request.CompanyId.HasValue)
        {
            throw new UserManagementException(
                "Non-SuperAdmin users must belong to a company.");
        }

        var normalizedEmail =
            NormalizeEmail(request.Email);

        var emailExists = await _dbContext.Users
            .IgnoreQueryFilters()
            .AnyAsync(
                x => x.NormalizedEmail == normalizedEmail,
                cancellationToken);

        if (emailExists)
        {
            throw new UserManagementException(
                "A user with this email already exists.");
        }

        var roles = await ResolveRolesAsync(
            requestedRoles,
            cancellationToken);

        if (request.EmployeeId.HasValue)
        {
            var employeeExists =
                await _dbContext.Employees.AnyAsync(
                    x => x.Id == request.EmployeeId.Value,
                    cancellationToken);

            if (!employeeExists)
            {
                throw new UserManagementException(
                    "The selected employee does not exist.");
            }
        }

        var user = new User
        {
            CompanyId = request.CompanyId,
            EmployeeId = request.EmployeeId,
            Email = request.Email.Trim(),
            NormalizedEmail = normalizedEmail,
            FirstName = request.FirstName.Trim(),
            LastName = request.LastName.Trim(),
            PasswordHash =
                _passwordHasher.Hash(
                    request.TemporaryPassword),
            IsActive = true,
            MustChangePassword = true
        };

        foreach (var role in roles)
        {
            user.UserRoles.Add(
                new UserRole
                {
                    RoleId = role.Id
                });
        }

        _dbContext.Users.Add(user);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return Map(user);
    }

    public async Task<UserResponse> UpdateAsync(
        Guid currentUserId,
        Guid userId,
        UpdateUserRequest request,
        CancellationToken cancellationToken = default)
    {
        var actor = await GetActorAsync(
            currentUserId,
            cancellationToken);

        var target = await GetUserAsync(
            userId,
            cancellationToken);

        EnsureCanManage(actor, target);

        if (string.IsNullOrWhiteSpace(request.FirstName) ||
            string.IsNullOrWhiteSpace(request.LastName))
        {
            throw new UserManagementException(
                "First name and last name are required.");
        }

        if (request.EmployeeId.HasValue)
        {
            var employeeExists =
                await _dbContext.Employees.AnyAsync(
                    x => x.Id == request.EmployeeId.Value,
                    cancellationToken);

            if (!employeeExists)
            {
                throw new UserManagementException(
                    "The selected employee does not exist.");
            }
        }

        target.FirstName = request.FirstName.Trim();
        target.LastName = request.LastName.Trim();
        target.EmployeeId = request.EmployeeId;

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return Map(target);
    }

   public async Task SetRolesAsync(
       Guid currentUserId,
       Guid userId,
       SetUserRolesRequest request,
       CancellationToken cancellationToken)
   {
       var currentUser = await _dbContext.Users
           .AsNoTracking()
           .SingleOrDefaultAsync(x => x.Id == currentUserId, cancellationToken)
           ?? throw new UserManagementException("Current user not found.");

       var user = await _dbContext.Users
           .AsNoTracking()
           .SingleOrDefaultAsync(x => x.Id == userId, cancellationToken)
           ?? throw new UserManagementException("User not found.");

       if (currentUser.CompanyId != null &&
           user.CompanyId != currentUser.CompanyId)
       {
           throw new UserManagementException(
               "You can only manage users in your own company.");
       }

       var requestedNames = request.Roles
           .Distinct(StringComparer.OrdinalIgnoreCase)
           .ToList();

        var requestedRoleIds = await _dbContext.Roles
            .Where(r => requestedNames.Contains(r.Name))
            .Select(r => r.Id)
            .ToListAsync(cancellationToken);

        if (requestedRoleIds.Count != requestedNames.Count)
        {
            throw new UserManagementException(
                "One or more selected roles are invalid.");
        }

        var executionStrategy = _dbContext.Database.CreateExecutionStrategy();

        await executionStrategy.ExecuteAsync(
            async () =>
            {
                await using var transaction =
                    await _dbContext.Database.BeginTransactionAsync(
                        System.Data.IsolationLevel.Serializable,
                        cancellationToken);

                var existingLinks = await _dbContext.UserRoles
                    .IgnoreQueryFilters()
                    .Where(x => x.UserId == userId)
                    .ToListAsync(cancellationToken);

                var existingRoleIds = existingLinks
                    .Where(x => !x.IsDeleted)
                    .Select(x => x.RoleId)
                    .ToHashSet();

                var linksToRemove = existingLinks
                    .Where(x => !x.IsDeleted && !requestedRoleIds.Contains(x.RoleId))
                    .ToList();

                if (linksToRemove.Count > 0)
                {
                    _dbContext.UserRoles.RemoveRange(linksToRemove);
                }

                foreach (var roleId in requestedRoleIds)
                {
                    var existingLink = existingLinks
                        .SingleOrDefault(x => x.RoleId == roleId);

                    if (existingLink?.IsDeleted == true)
                    {
                        existingLink.IsDeleted = false;
                        existingLink.DeletedAtUtc = null;
                        existingLink.DeletedBy = null;
                    }
                    else if (!existingRoleIds.Contains(roleId))
                    {
                        _dbContext.UserRoles.Add(new UserRole
                        {
                            Id = Guid.NewGuid(),
                            UserId = userId,
                            RoleId = roleId
                        });
                    }
                }

                await _dbContext.SaveChangesAsync(cancellationToken);
                await transaction.CommitAsync(cancellationToken);
            });
   }
    public async Task SetActiveStatusAsync(
        Guid currentUserId,
        Guid userId,
        bool isActive,
        CancellationToken cancellationToken)
    {
        var currentUser = await _dbContext.Users
            .AsNoTracking()
            .SingleOrDefaultAsync(
                x => x.Id == currentUserId,
                cancellationToken)
            ?? throw new UserManagementException("Current user not found.");

        var user = await _dbContext.Users
            .SingleOrDefaultAsync(
                x => x.Id == userId,
                cancellationToken)
            ?? throw new UserManagementException("User not found.");

        if (currentUser.CompanyId != null &&
            user.CompanyId != currentUser.CompanyId)
        {
            throw new UserManagementException(
                "You can only manage users in your own company.");
        }

        user.IsActive = isActive;
        user.UpdatedAtUtc = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    private async Task<User> GetActorAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var user = await GetUserAsync(
            userId,
            cancellationToken);

        if (!user.IsActive)
        {
            throw new UserManagementException(
                "Current user account is inactive.");
        }

        return user;
    }

    private async Task<User> GetUserAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        return await _dbContext.Users
            .Include(x => x.UserRoles)
                .ThenInclude(x => x.Role)
            .SingleOrDefaultAsync(
                x => x.Id == userId,
                cancellationToken)
            ?? throw new UserManagementException(
                "User was not found.");
    }

    private void EnsureCanManage(
        User actor,
        User target)
    {
        if (IsSuperAdmin(actor))
        {
            return;
        }

        EnsureCompanyAdmin(actor);

        if (!actor.CompanyId.HasValue ||
            actor.CompanyId != target.CompanyId)
        {
            throw new UserManagementException(
                "You cannot manage users outside your company.");
        }

        if (IsSuperAdmin(target))
        {
            throw new UserManagementException(
                "Company administrators cannot manage SuperAdmin users.");
        }
    }

    private static void EnsureCompanyAdmin(User user)
    {
        if (!HasRole(user, AppRoles.CompanyAdmin))
        {
            throw new UserManagementException(
                "You are not authorized to manage users.");
        }
    }

    private static bool IsSuperAdmin(User user) =>
        HasRole(user, AppRoles.SuperAdmin);

    private static bool HasRole(
        User user,
        string roleName)
    {
        return user.UserRoles.Any(
            x =>
                !x.IsDeleted &&
                !x.Role.IsDeleted &&
                string.Equals(
                    x.Role.Name,
                    roleName,
                    StringComparison.OrdinalIgnoreCase));
    }

    private async Task<List<Role>> ResolveRolesAsync(
        IReadOnlyCollection<string> roleNames,
        CancellationToken cancellationToken)
    {
        var normalized =
            roleNames
                .Select(x => x.ToUpperInvariant())
                .ToArray();

        var roles = await _dbContext.Roles
            .Where(x =>
                normalized.Contains(x.NormalizedName))
            .ToListAsync(cancellationToken);

        if (roles.Count != normalized.Length)
        {
            throw new UserManagementException(
                "One or more selected roles are invalid.");
        }

        return roles;
    }

    private static List<string> NormalizeRoles(
        IReadOnlyCollection<string>? roles)
    {
        if (roles is null)
        {
            return [];
        }

        return roles
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .Select(x => x.Trim())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();
    }

    private static string NormalizeEmail(string email)
    {
        if (string.IsNullOrWhiteSpace(email))
        {
            throw new UserManagementException(
                "Email is required.");
        }

        return email.Trim().ToUpperInvariant();
    }

    private static void ValidateBasicInput(
        CreateUserRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.FirstName))
        {
            throw new UserManagementException(
                "First name is required.");
        }

        if (string.IsNullOrWhiteSpace(request.LastName))
        {
            throw new UserManagementException(
                "Last name is required.");
        }
    }

    private static void ValidatePassword(string password)
    {
        if (string.IsNullOrWhiteSpace(password) ||
            password.Length < 12 ||
            !password.Any(char.IsUpper) ||
            !password.Any(char.IsLower) ||
            !password.Any(char.IsDigit) ||
            !password.Any(
                x => !char.IsLetterOrDigit(x)))
        {
            throw new UserManagementException(
                "Temporary password must be at least 12 characters and contain uppercase, lowercase, number, and special characters.");
        }
    }

    private static UserResponse Map(User user)
    {
        var roles = user.UserRoles
            .Where(x =>
                !x.IsDeleted &&
                !x.Role.IsDeleted)
            .Select(x => x.Role.Name)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .OrderBy(x => x)
            .ToArray();

        return new UserResponse(
            user.Id,
            user.CompanyId,
            user.EmployeeId,
            user.Email,
            user.FirstName,
            user.LastName,
            $"{user.FirstName} {user.LastName}".Trim(),
            user.IsActive,
            user.MustChangePassword,
            user.LastLoginAtUtc,
            roles,
            user.CreatedAtUtc);
    }
}