using CSM.Application.Common.Security;
using CSM.Domain.Constants;
using CSM.Domain.Entities.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace CSM.Infrastructure.Persistence;

public static class DatabaseInitializer
{
    public static async Task InitializeAsync(
        IServiceProvider serviceProvider,
        CancellationToken cancellationToken = default)
    {
        using var scope = serviceProvider.CreateScope();

        var dbContext =
            scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

        var passwordHasher =
            scope.ServiceProvider.GetRequiredService<IPasswordHasher>();

        await SeedRolesAsync(
            dbContext,
            cancellationToken);

        await SeedSuperAdminAsync(
            dbContext,
            passwordHasher,
            cancellationToken);
    }

    private static async Task SeedRolesAsync(
        ApplicationDbContext dbContext,
        CancellationToken cancellationToken)
    {
        foreach (var roleName in AppRoles.All)
        {
            var normalizedName =
                roleName.ToUpperInvariant();

            var exists =
                await dbContext.Roles.AnyAsync(
                    x => x.NormalizedName == normalizedName,
                    cancellationToken);

            if (exists)
            {
                continue;
            }

            dbContext.Roles.Add(
                new Role
                {
                    Name = roleName,
                    NormalizedName = normalizedName,
                    Description =
                        $"{roleName} system role",
                    IsSystemRole = true
                });
        }

        await dbContext.SaveChangesAsync(
            cancellationToken);
    }

    private static async Task SeedSuperAdminAsync(
        ApplicationDbContext dbContext,
        IPasswordHasher passwordHasher,
        CancellationToken cancellationToken)
    {
        const string email =
            "admin@csm.local";

        var normalizedEmail =
            email.ToUpperInvariant();

        var user =
            await dbContext.Users
                .Include(x => x.UserRoles)
                .SingleOrDefaultAsync(
                    x => x.NormalizedEmail == normalizedEmail,
                    cancellationToken);

        if (user is null)
        {
            user = new User
            {
                CompanyId = null,
                EmployeeId = null,

                Email = email,
                NormalizedEmail = normalizedEmail,

                FirstName = "System",
                LastName = "Administrator",

                PasswordHash =
                    passwordHasher.Hash(
                        "ChangeMe123!"),

                IsActive = true,
                MustChangePassword = true
            };

            dbContext.Users.Add(user);

            await dbContext.SaveChangesAsync(
                cancellationToken);
        }

        var superAdminRole =
            await dbContext.Roles
                .SingleAsync(
                    x => x.NormalizedName ==
                         AppRoles.SuperAdmin.ToUpperInvariant(),
                    cancellationToken);

        var alreadyAssigned =
            await dbContext.UserRoles.AnyAsync(
                x =>
                    x.UserId == user.Id &&
                    x.RoleId == superAdminRole.Id,
                cancellationToken);

        if (!alreadyAssigned)
        {
            dbContext.UserRoles.Add(
                new UserRole
                {
                    UserId = user.Id,
                    RoleId = superAdminRole.Id
                });

            await dbContext.SaveChangesAsync(
                cancellationToken);
        }
    }
}