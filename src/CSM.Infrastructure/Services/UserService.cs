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
                .ThenInclude(x => x.Role)
            .Include(x => x.SiteAccesses)
                .ThenInclude(x => x.Site);

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
        var actor = await GetActorAsync(
            currentUserId,
            cancellationToken);
        var target = await GetUserAsync(
            userId,
            cancellationToken);
        EnsureCanManage(actor, target);

        var requestedNames = NormalizeRoles(request.Roles);
        if (requestedNames.Count == 0)
        {
            throw new UserManagementException(
                "At least one role is required.");
        }

        if (!IsSuperAdmin(actor) &&
            requestedNames.Contains(
                AppRoles.SuperAdmin,
                StringComparer.OrdinalIgnoreCase))
        {
            throw new UserManagementException(
                "Company administrators cannot assign the SuperAdmin role.");
        }

        var roles = await ResolveRolesAsync(
            requestedNames,
            cancellationToken);
        var requestedRoleIds = roles.Select(x => x.Id).ToHashSet();

        var executionStrategy =
            _dbContext.Database.CreateExecutionStrategy();

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
                    .Where(x =>
                        !x.IsDeleted &&
                        !requestedRoleIds.Contains(x.RoleId))
                    .ToList();

                _dbContext.UserRoles.RemoveRange(linksToRemove);

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

        await WriteAuditAsync(
            currentUserId,
            userId,
            "Update Roles",
            $"{requestedNames.Count} assigned role(s)",
            cancellationToken);
    }
    public async Task SetActiveStatusAsync(
        Guid currentUserId,
        Guid userId,
        bool isActive,
        CancellationToken cancellationToken)
    {
        var actor = await GetActorAsync(
            currentUserId,
            cancellationToken);
        var target = await GetUserAsync(
            userId,
            cancellationToken);
        EnsureCanManage(actor, target);

        if (!isActive && actor.Id == target.Id)
        {
            throw new UserManagementException(
                "You cannot deactivate your own account.");
        }

        target.IsActive = isActive;

        await _dbContext.SaveChangesAsync(cancellationToken);

        await WriteAuditAsync(
            currentUserId,
            target.Id,
            isActive ? "Activate User" : "Deactivate User",
            string.Empty,
            cancellationToken);
    }

    public async Task SetSitesAsync(
        Guid currentUserId,
        Guid userId,
        SetUserSitesRequest request,
        CancellationToken cancellationToken)
    {
        var actor = await GetActorAsync(
            currentUserId,
            cancellationToken);
        var target = await GetUserAsync(
            userId,
            cancellationToken);
        EnsureCanManage(actor, target);

        if (!target.CompanyId.HasValue || request.SiteIds is null)
        {
            throw new UserManagementException(
                "Site access can only be assigned to company users.");
        }

        var siteIds = request.SiteIds.Distinct().ToArray();
        if (siteIds.Contains(Guid.Empty) ||
            (request.DefaultSiteId.HasValue &&
             !siteIds.Contains(request.DefaultSiteId.Value)))
        {
            throw new UserManagementException(
                "The default site must be included in the assigned sites.");
        }

        var validSiteIds = await _dbContext.ConstructionSites
            .Where(site =>
                site.CompanyId == target.CompanyId.Value &&
                site.IsActive &&
                siteIds.Contains(site.Id))
            .Select(site => site.Id)
            .ToListAsync(cancellationToken);

        if (validSiteIds.Count != siteIds.Length)
        {
            throw new UserManagementException(
                "One or more selected sites are invalid or belong to another company.");
        }

        target.DefaultSiteId = request.DefaultSiteId;
        await _dbContext.UserSiteAccesses
            .Where(access => access.UserId == target.Id)
            .ExecuteDeleteAsync(cancellationToken);

        foreach (var siteId in siteIds)
        {
            _dbContext.UserSiteAccesses.Add(new UserSiteAccess
            {
                CompanyId = target.CompanyId.Value,
                UserId = target.Id,
                SiteId = siteId,
                IsDefault = siteId == request.DefaultSiteId,
                IsActive = true
            });
        }

        await _dbContext.SaveChangesAsync(cancellationToken);

        await WriteAuditAsync(
            currentUserId,
            userId,
            "Update Sites",
            $"{siteIds.Length} assigned site(s)",
            cancellationToken);
    }

    public async Task DeleteAsync(
        Guid currentUserId,
        Guid userId,
        CancellationToken cancellationToken)
    {
        var actor = await GetActorAsync(
            currentUserId,
            cancellationToken);
        var target = await GetUserAsync(
            userId,
            cancellationToken);
        EnsureCanManage(actor, target);

        if (actor.Id == target.Id)
        {
            throw new UserManagementException(
                "You cannot delete your own account.");
        }

        target.IsDeleted = true;
        target.IsActive = false;
        await _dbContext.SaveChangesAsync(cancellationToken);

        await WriteAuditAsync(
            currentUserId,
            target.Id,
            "Delete User",
            "Soft deleted",
            cancellationToken);
    }

    public async Task<UserProfileResponse> GetProfileAsync(
        Guid currentUserId,
        Guid userId,
        CancellationToken cancellationToken)
    {
        var actor = await GetActorAsync(
            currentUserId,
            cancellationToken);
        var user = await _dbContext.Users
            .AsNoTracking()
            .Include(x => x.UserRoles)
                .ThenInclude(x => x.Role)
            .Include(x => x.SiteAccesses)
                .ThenInclude(x => x.Site)
            .Include(x => x.Employee)
            .SingleOrDefaultAsync(
                x => x.Id == userId,
                cancellationToken)
            ?? throw new UserManagementException(
                "User was not found.");

        EnsureCanManage(actor, user);

        var sites = user.SiteAccesses
            .Where(x => x.IsActive && !x.IsDeleted && x.Site.IsActive)
            .Select(x => new SiteSummaryDto(
                x.SiteId,
                x.Site.Name,
                x.SiteId == user.DefaultSiteId))
            .ToArray();
        var defaultSiteName = sites
            .FirstOrDefault(x => x.Id == user.DefaultSiteId)?.Name;

        return new UserProfileResponse(
            user.Id,
            user.Employee?.EmployeeNumber ?? string.Empty,
            user.FirstName,
            user.LastName,
            user.Email,
            user.PhoneNumber,
            user.JobTitle,
            user.IsActive,
            user.DefaultSiteId,
            defaultSiteName,
            user.CreatedAtUtc,
            user.LastLoginAtUtc,
            user.UserRoles
                .Where(x => !x.IsDeleted && !x.Role.IsDeleted)
                .Select(x => x.Role.Name)
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .OrderBy(x => x)
                .ToArray(),
            sites);
    }

    public async Task ActivateAsync(
        Guid currentUserId,
        Guid userId,
        CancellationToken cancellationToken)
    {
        await SetActiveStatusAsync(
            currentUserId,
            userId,
            true,
            cancellationToken);
    }

    public async Task DeactivateAsync(
        Guid currentUserId,
        Guid userId,
        CancellationToken cancellationToken)
    {
        await SetActiveStatusAsync(
            currentUserId,
            userId,
            false,
            cancellationToken);
    }

    public async Task<IReadOnlyCollection<UserAuditResponse>> GetAuditAsync(
        Guid currentUserId,
        CancellationToken cancellationToken)
    {
        var actor = await GetActorAsync(
            currentUserId,
            cancellationToken);

        IQueryable<UserAudit> query = _dbContext.UserAudits
            .AsNoTracking()
            .Include(x => x.ActorUser)
            .Include(x => x.TargetUser);

        if (!IsSuperAdmin(actor))
        {
            EnsureCompanyAdmin(actor);
            if (!actor.CompanyId.HasValue)
            {
                throw new UserManagementException(
                    "Company administrator is not assigned to a company.");
            }

            query = query.Where(
                audit => audit.TargetUser.CompanyId == actor.CompanyId);
        }

        return await query
            .OrderByDescending(x => x.PerformedAtUtc)
            .Take(500)
            .Select(x => new UserAuditResponse(
                x.Id,
                x.PerformedAtUtc,
                x.ActorUser.FirstName + " " + x.ActorUser.LastName,
                x.Action,
                x.TargetUser.FirstName + " " + x.TargetUser.LastName,
                x.Details))
            .ToListAsync(cancellationToken);
    }

    private async Task WriteAuditAsync(
        Guid actorUserId,
        Guid targetUserId,
        string action,
        string details,
        CancellationToken cancellationToken)
    {
        _dbContext.UserAudits.Add(new UserAudit
        {
            ActorUserId = actorUserId,
            TargetUserId = targetUserId,
            Action = action,
            Details = details
        });

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
            .Include(x => x.SiteAccesses)
                .ThenInclude(x => x.Site)
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
            user.PhoneNumber,
            user.JobTitle,
            user.IsActive,
            user.MustChangePassword,
            user.DefaultSiteId,
            user.LastLoginAtUtc,
            roles,
            user.SiteAccesses
                .Where(x => x.IsActive && !x.IsDeleted)
                .Select(x => x.SiteId)
                .Distinct()
                .ToArray(),
            user.SiteAccesses
                .Where(x => x.IsActive && !x.IsDeleted)
                .Select(x => x.Site.Name)
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .OrderBy(x => x)
                .ToArray(),
            user.CreatedAtUtc);
    }
}