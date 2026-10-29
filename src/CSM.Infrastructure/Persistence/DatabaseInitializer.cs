using CSM.Application.Common.Security;
using CSM.Domain.Constants;
using CSM.Domain.Entities.Identity;
using CSM.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace CSM.Infrastructure.Persistence;

public static class DatabaseInitializer
{
    public static async Task InitializeAsync(
        IServiceProvider serviceProvider,
        CancellationToken cancellationToken = default)
    {
        await using var scope = serviceProvider.CreateAsyncScope();

        var dbContext =
            scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

        var passwordHasher =
            scope.ServiceProvider.GetRequiredService<IPasswordHasher>();
        var configuration =
            scope.ServiceProvider.GetRequiredService<IConfiguration>();
        var logger = scope.ServiceProvider
            .GetRequiredService<ILoggerFactory>()
            .CreateLogger(nameof(DatabaseInitializer));

        try
        {
            var executionStrategy = dbContext.Database.CreateExecutionStrategy();

            await executionStrategy.ExecuteAsync(async () =>
            {
                await using var transaction = await dbContext.Database
                    .BeginTransactionAsync(cancellationToken);

                await SeedRolesAsync(dbContext, cancellationToken);

                await SeedSuperAdminAsync(
                    dbContext,
                    passwordHasher,
                    configuration["CSM_BOOTSTRAP_ADMIN_PASSWORD"],
                    cancellationToken);

                await SeedRolePermissionsAsync(dbContext, cancellationToken);
                await SeedGranularRolePermissionsAsync(dbContext, cancellationToken);

                await transaction.CommitAsync(cancellationToken);
            });
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            logger.LogInformation("Database initialization was canceled.");
            throw;
        }
        catch (Exception exception)
        {
            logger.LogError(exception, "Database initialization failed during startup.");
            throw;
        }
    }

    private static async Task SeedRolesAsync(
        ApplicationDbContext dbContext,
        CancellationToken cancellationToken)
    {
        foreach (var roleName in AppRoles.All)
        {
            var normalizedName = roleName.ToUpperInvariant();

            var exists = await dbContext.Roles.AnyAsync(
                x => x.NormalizedName == normalizedName,
                cancellationToken);

            if (exists)
                continue;

            dbContext.Roles.Add(new Role
            {
                Name = roleName,
                NormalizedName = normalizedName,
                Description = $"{roleName} system role",
                IsSystemRole = true
            });
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private static async Task SeedSuperAdminAsync(
        ApplicationDbContext dbContext,
        IPasswordHasher passwordHasher,
        string? bootstrapPassword,
        CancellationToken cancellationToken)
    {
        const string email = "admin@csm.local";
        var normalizedEmail = email.ToUpperInvariant();

        var user = await dbContext.Users
            .Include(x => x.UserRoles)
            .SingleOrDefaultAsync(
                x => x.NormalizedEmail == normalizedEmail,
                cancellationToken);

        if (user is null)
        {
            if (string.IsNullOrWhiteSpace(bootstrapPassword))
            {
                throw new InvalidOperationException(
                    "Set CSM_BOOTSTRAP_ADMIN_PASSWORD before initializing a new database.");
            }

            user = new User
            {
                Email = email,
                NormalizedEmail = normalizedEmail,
                FirstName = "System",
                LastName = "Administrator",
                PasswordHash = passwordHasher.Hash(bootstrapPassword),
                IsActive = true,
                MustChangePassword = true
            };

            dbContext.Users.Add(user);
            await dbContext.SaveChangesAsync(cancellationToken);
        }

        var superAdminRole = await dbContext.Roles.SingleAsync(
            x => x.NormalizedName == AppRoles.SuperAdmin.ToUpperInvariant(),
            cancellationToken);

        var assigned = await dbContext.UserRoles.AnyAsync(
            x => x.UserId == user.Id && x.RoleId == superAdminRole.Id,
            cancellationToken);

        if (!assigned)
        {
            dbContext.UserRoles.Add(new UserRole
            {
                UserId = user.Id,
                RoleId = superAdminRole.Id
            });

            await dbContext.SaveChangesAsync(cancellationToken);
        }
    }

    private static async Task SeedRolePermissionsAsync(
        ApplicationDbContext dbContext,
        CancellationToken cancellationToken)
    {
        var roles = await dbContext.Roles
            .ToDictionaryAsync(x => x.Name, cancellationToken);
        var existingPermissions = await dbContext.RolePermissions
            .Select(x => new { x.RoleId, x.Permission })
            .ToHashSetAsync(cancellationToken);

        void Grant(string roleName, params Permission[] permissions)
        {
            if (!roles.TryGetValue(roleName, out var role))
                return;

            foreach (var permission in permissions.Distinct())
            {
                if (!existingPermissions.Add(new { RoleId = role.Id, Permission = permission }))
                    continue;

                dbContext.RolePermissions.Add(new RolePermission
                {
                    RoleId = role.Id,
                    Permission = permission
                });
            }
        }

        Grant(AppRoles.Administrator, Enum.GetValues<Permission>());

        Grant(AppRoles.ProjectManager,
            Permission.UsersView,
            Permission.SitesView,
            Permission.SitesManage,
            Permission.HRView,
            Permission.FinanceView,
            Permission.FinanceApprove,
            Permission.ProcurementView,
            Permission.ProcurementManage,
            Permission.ComplianceView,
            Permission.ReportsView);

        Grant(AppRoles.SiteEngineer,
            Permission.SitesView,
            Permission.ProcurementView,
            Permission.ComplianceView,
            Permission.ReportsView);

        Grant(AppRoles.Storekeeper,
            Permission.ProcurementView,
            Permission.ProcurementManage);

        Grant(AppRoles.ProcurementOfficer,
            Permission.ProcurementView,
            Permission.ProcurementManage,
            Permission.ReportsView);

        Grant(AppRoles.HrOfficer,
            Permission.HRView,
            Permission.HRManage,
            Permission.ReportsView);

        Grant(AppRoles.FinanceOfficer,
            Permission.FinanceView,
            Permission.FinanceApprove,
            Permission.ReportsView);

        Grant(AppRoles.EquipmentManager,
            Permission.ReportsView,
            Permission.SitesView);

        Grant(AppRoles.SafetyOfficer,
            Permission.ComplianceView,
            Permission.ComplianceManage,
            Permission.ReportsView);

        Grant("Viewer",
            Permission.UsersView,
            Permission.SitesView,
            Permission.ReportsView);

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private static async Task SeedGranularRolePermissionsAsync(
        ApplicationDbContext dbContext,
        CancellationToken cancellationToken)
    {
        var roles = await dbContext.Roles
            .ToDictionaryAsync(x => x.Name, cancellationToken);
        var existingPermissions = await dbContext.RoleGranularPermissions
            .Select(x => new { x.RoleId, x.Permission })
            .ToHashSetAsync(cancellationToken);

        void Grant(
            string roleName,
            params GranularPermission[] permissions)
        {
            if (!roles.TryGetValue(roleName, out var role))
                return;

            foreach (var permission in permissions.Distinct())
            {
                if (!existingPermissions.Add(new { RoleId = role.Id, Permission = permission }))
                    continue;

                dbContext.RoleGranularPermissions.Add(
                    new RoleGranularPermission
                    {
                        RoleId = role.Id,
                        Permission = permission
                    });
            }
        }

        Grant(
            AppRoles.SuperAdmin,
            Enum.GetValues<GranularPermission>());

        Grant(
            AppRoles.Administrator,
            Enum.GetValues<GranularPermission>());

        Grant(
            AppRoles.CompanyAdmin,
            Enum.GetValues<GranularPermission>());

        Grant(
            AppRoles.ProjectManager,
            GranularPermission.Sites_View,
            GranularPermission.Sites_Manage,
            GranularPermission.Projects_View,
            GranularPermission.Projects_Manage,
            GranularPermission.Projects_DailyProgress_View,
            GranularPermission.Projects_DailyProgress_Create,
            GranularPermission.HRM_Employee_View,
            GranularPermission.HRM_SiteAssignment_View,
            GranularPermission.HRM_Attendance_View,
            GranularPermission.HRM_Attendance_Submit,
            GranularPermission.HRM_Leave_View,
            GranularPermission.HRM_Leave_Submit,
            GranularPermission.HRM_Leave_Approve,
            GranularPermission.Finance_Budget_View,
            GranularPermission.Finance_CostCode_View,
            GranularPermission.Finance_Expense_View,
            GranularPermission.Finance_Expense_Submit,
            GranularPermission.Finance_Expense_Approve,
            GranularPermission.Procurement_Vendor_View,
            GranularPermission.Finance_Invoice_View,
            GranularPermission.Finance_Payment_View,
            GranularPermission.Finance_PettyCash_View,
            GranularPermission.Procurement_MaterialRequest_View,
            GranularPermission.Procurement_MaterialRequest_Submit,
            GranularPermission.Procurement_PurchaseOrder_View,
            GranularPermission.Procurement_PurchaseOrder_Manage,
            GranularPermission.Procurement_Inventory_View,
            GranularPermission.Procurement_Inventory_Adjust,
            GranularPermission.Compliance_View,
            GranularPermission.Compliance_Manage,
            GranularPermission.Notifications_View,
            GranularPermission.Equipment_View,
            GranularPermission.Equipment_Manage);

        Grant(
            AppRoles.SiteManager,
            GranularPermission.Sites_View,
            GranularPermission.Sites_Manage,
            GranularPermission.Projects_View,
            GranularPermission.Projects_Manage,
            GranularPermission.Projects_DailyProgress_View,
            GranularPermission.Projects_DailyProgress_Create,
            GranularPermission.HRM_Employee_View,
            GranularPermission.HRM_SiteAssignment_View,
            GranularPermission.HRM_Attendance_View,
            GranularPermission.HRM_Attendance_Submit,
            GranularPermission.HRM_Leave_View,
            GranularPermission.HRM_Leave_Submit,
            GranularPermission.HRM_Leave_Approve,
            GranularPermission.Finance_Budget_View,
            GranularPermission.Finance_CostCode_View,
            GranularPermission.Finance_Expense_View,
            GranularPermission.Finance_Expense_Submit,
            GranularPermission.Finance_Expense_Approve,
            GranularPermission.Procurement_Vendor_View,
            GranularPermission.Finance_Invoice_View,
            GranularPermission.Finance_Payment_View,
            GranularPermission.Finance_PettyCash_View,
            GranularPermission.Procurement_MaterialRequest_View,
            GranularPermission.Procurement_MaterialRequest_Submit,
            GranularPermission.Procurement_PurchaseOrder_View,
            GranularPermission.Procurement_PurchaseOrder_Manage,
            GranularPermission.Procurement_Inventory_View,
            GranularPermission.Procurement_Inventory_Adjust,
            GranularPermission.Compliance_View,
            GranularPermission.Compliance_Manage,
            GranularPermission.Notifications_View,
            GranularPermission.Equipment_View,
            GranularPermission.Equipment_Manage);

        Grant(
            AppRoles.SiteEngineer,
            GranularPermission.Sites_View,
            GranularPermission.Projects_View,
            GranularPermission.Projects_DailyProgress_View,
            GranularPermission.Projects_DailyProgress_Create,
            GranularPermission.Procurement_Inventory_View,
            GranularPermission.Compliance_View,
            GranularPermission.Notifications_View);

        Grant(
            AppRoles.Storekeeper,
            GranularPermission.Procurement_Vendor_View,
            GranularPermission.Procurement_MaterialRequest_View,
            GranularPermission.Procurement_MaterialRequest_Submit,
            GranularPermission.Procurement_PurchaseOrder_View,
            GranularPermission.Procurement_PurchaseOrder_Manage,
            GranularPermission.Procurement_Inventory_View,
            GranularPermission.Procurement_Inventory_Adjust,
            GranularPermission.Notifications_View);

        Grant(
            AppRoles.ProcurementOfficer,
            GranularPermission.Procurement_Vendor_View,
            GranularPermission.Procurement_MaterialRequest_View,
            GranularPermission.Procurement_MaterialRequest_Submit,
            GranularPermission.Procurement_PurchaseOrder_View,
            GranularPermission.Procurement_PurchaseOrder_Manage,
            GranularPermission.Procurement_Inventory_View,
            GranularPermission.Procurement_Inventory_Adjust,
            GranularPermission.Notifications_View,
            GranularPermission.Reports_View);

        Grant(
            AppRoles.Accountant,
            GranularPermission.Sites_View,
            GranularPermission.Projects_View,
            GranularPermission.HRM_Payroll_View,
            GranularPermission.Finance_Budget_View,
            GranularPermission.Finance_Budget_Manage,
            GranularPermission.Finance_Expense_View,
            GranularPermission.Finance_Expense_Approve,
            GranularPermission.Finance_Invoice_View,
            GranularPermission.Finance_Invoice_Manage,
            GranularPermission.Finance_Payment_View,
            GranularPermission.Finance_PettyCash_View,
            GranularPermission.Finance_PettyCash_Manage,
            GranularPermission.Finance_Payment_Manage,
            GranularPermission.Procurement_Inventory_View,
            GranularPermission.Procurement_Vendor_View,
            GranularPermission.Compliance_View,
            GranularPermission.Notifications_View,
            GranularPermission.Reports_View,
            GranularPermission.Reports_FinancialSummary_View,
            GranularPermission.Reports_Export);

        Grant(
            AppRoles.FinanceOfficer,
            GranularPermission.Sites_View,
            GranularPermission.Projects_View,
            GranularPermission.Finance_Budget_View,
            GranularPermission.Finance_Budget_Manage,
            GranularPermission.Finance_Expense_View,
            GranularPermission.Finance_Expense_Approve,
            GranularPermission.Finance_Invoice_View,
            GranularPermission.Finance_Invoice_Manage,
            GranularPermission.Finance_Payment_View,
            GranularPermission.Finance_PettyCash_View,
            GranularPermission.Finance_PettyCash_Manage,
            GranularPermission.Finance_Payment_Manage,
            GranularPermission.Reports_View,
            GranularPermission.Reports_FinancialSummary_View,
            GranularPermission.Notifications_View);

        Grant(
            AppRoles.HROfficer,
            GranularPermission.HRM_Employee_View,
            GranularPermission.HRM_Employee_Manage,
            GranularPermission.HRM_Contractor_View,
            GranularPermission.HRM_Contractor_Manage,
            GranularPermission.HRM_Payroll_View,
            GranularPermission.HRM_Payroll_Approve,
            GranularPermission.HRM_Attendance_View,
            GranularPermission.HRM_Attendance_Submit,
            GranularPermission.HRM_Attendance_Override,
            GranularPermission.HRM_Attendance_Approve,
            GranularPermission.HRM_Shift_View,
            GranularPermission.HRM_Shift_Submit,
            GranularPermission.HRM_Leave_View,
            GranularPermission.HRM_Leave_Submit,
            GranularPermission.HRM_Leave_Approve,
            GranularPermission.HRM_SiteAssignment_View,
            GranularPermission.Sites_View,
            GranularPermission.HRM_SiteAssignment_Manage,
            GranularPermission.HRM_Timesheet_View,
            GranularPermission.HRM_Timesheet_Submit,
            GranularPermission.HRM_Timesheet_Approve,
            GranularPermission.Compliance_View,
            GranularPermission.Notifications_View,
            GranularPermission.Reports_View);

        Grant(
            AppRoles.EquipmentManager,
            GranularPermission.Equipment_View,
            GranularPermission.Equipment_Manage,
            GranularPermission.Notifications_View,
            GranularPermission.Sites_View);

        Grant(
            AppRoles.SafetyOfficer,
            GranularPermission.Sites_View,
            GranularPermission.Compliance_View,
            GranularPermission.Compliance_Manage,
            GranularPermission.Notifications_View,
            GranularPermission.Reports_View);

        Grant(
            AppRoles.Supervisor,
            GranularPermission.Sites_View,
            GranularPermission.Projects_View,
            GranularPermission.Projects_DailyProgress_View,
            GranularPermission.Projects_DailyProgress_Create,
            GranularPermission.HRM_Employee_View,
            GranularPermission.HRM_Payroll_View,
            GranularPermission.HRM_Attendance_View,
            GranularPermission.HRM_Attendance_Submit,
            GranularPermission.HRM_Leave_View,
            GranularPermission.HRM_Leave_Submit,
            GranularPermission.Procurement_Inventory_View,
            GranularPermission.Compliance_View,
            GranularPermission.Notifications_View);

        Grant(
            AppRoles.Employee,
            GranularPermission.HRM_Employee_View,
            GranularPermission.HRM_Payroll_View,
            GranularPermission.HRM_Attendance_View,
            GranularPermission.HRM_Attendance_Submit,
            GranularPermission.HRM_Leave_View,
            GranularPermission.HRM_Leave_Submit,
            GranularPermission.Notifications_View);

        var reportingPermissions = new[]
        {
            GranularPermission.Reports_View,
            GranularPermission.Reports_FinancialSummary_View,
            GranularPermission.Reports_Export
        };

        var reportingRoles = new[]
        {
            AppRoles.SuperAdmin,
            AppRoles.Administrator,
            AppRoles.CompanyAdmin,
            AppRoles.ProjectManager,
            AppRoles.SiteEngineer,
            AppRoles.Storekeeper,
            AppRoles.ProcurementOfficer,
            AppRoles.FinanceOfficer,
            AppRoles.HrOfficer,
            AppRoles.EquipmentManager,
            AppRoles.SafetyOfficer,
            AppRoles.Accountant
        };

        var staleReportingPermissions = await dbContext.RoleGranularPermissions
            .Include(x => x.Role)
            .Where(x =>
                reportingPermissions.Contains(x.Permission) &&
                !reportingRoles.Contains(x.Role.Name))
            .ToListAsync(cancellationToken);

        dbContext.RoleGranularPermissions.RemoveRange(staleReportingPermissions);

        await dbContext.SaveChangesAsync(cancellationToken);
    }
}
