using CSM.Application.Inventory.StockAdjustments;
using CSM.Application.Procurement.RebarSpecs;
using CSM.Application.Procurement.GoodsReceipts;
using CSM.Application.Inventory.StockReturns;
using CSM.Application.Inventory.StockMovements;
using CSM.Application.Inventory.StockIssues;
using CSM.Application.Inventory.DailyMaterialUsage;
using CSM.Application.Procurement.PurchaseOrders;
using CSM.Application.Procurement.Vendors;
using CSM.Application.Procurement.MaterialRequests;
using CSM.Application.Procurement.Materials;
using CSM.Application.Procurement.Equipment;
using CSM.Application.Procurement.EquipmentAssignments;
using CSM.Application.Procurement.EquipmentMaintenance;
using CSM.Application.Procurement.EquipmentDowntime;
using CSM.Application.HRM.Contractors;
using CSM.Application.Finance.CostCodes;
using CSM.Application.Finance.Budgets;
using CSM.Application.Finance.BudgetLines;
using CSM.Application.Finance.Expenses;
using CSM.Application.Finance.Invoices;
using CSM.Application.Finance.InvoiceLines;
using CSM.Application.Finance.Payments;
using CSM.Application.Reporting;
using CSM.Application.Notifications;
using System.Security.Claims;
using System.Text;
using CSM.Application.Common.Security;
using CSM.Application.Compliance.SafetyIncidents;
using CSM.Infrastructure.Persistence;
using CSM.Infrastructure.Security;

using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.Tokens;

using CSM.Application.Auth;
using CSM.Application.Users;
using CSM.Infrastructure.Services;
using CSM.Application.Companies;
using CSM.Application.Compliance.DocumentCategories;
using CSM.Application.Compliance.Documents;
using CSM.Application.Compliance.Permits;
using CSM.Application.Compliance.Inspections;
using CSM.Application.Sites;
using CSM.Application.Projects;
using CSM.Application.Projects.Phases;
using CSM.Application.Projects.Milestones;
using CSM.Application.Projects.Tasks;
using CSM.Application.Projects.DailyProgress;
using CSM.Application.HRM.Shifts;
using CSM.Application.HRM.Employees;
using CSM.Application.HRM.SiteAssignments;
using CSM.Application.HRM.Attendances;
using CSM.Application.HRM.Leaves;
using CSM.Application.HRM.Timesheets;
using CSM.Application.HRM.Payroll;
using CSM.Application.Inventory.StockTransfers;
using CSM.Application.Inventory.StockBalances;




namespace CSM.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var connectionString =
            configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException(
                "Connection string 'DefaultConnection' was not found.");

        services.AddDbContext<ApplicationDbContext>(options =>
            options.UseSqlServer(
                connectionString,
                sqlOptions =>
                {
                    sqlOptions.EnableRetryOnFailure(
                        maxRetryCount: 5,
                        maxRetryDelay: TimeSpan.FromSeconds(10),
                        errorNumbersToAdd: null);
                }));

        services.Configure<JwtSettings>(
            configuration.GetSection(JwtSettings.SectionName));

        var jwtSettings =
            configuration
                .GetSection(JwtSettings.SectionName)
                .Get<JwtSettings>()
            ?? throw new InvalidOperationException(
                "JWT configuration was not found.");

        if (string.IsNullOrWhiteSpace(jwtSettings.SecretKey) ||
            jwtSettings.SecretKey.Length < 32)
        {
            throw new InvalidOperationException(
                "JWT SecretKey must contain at least 32 characters.");
        }

        services.AddScoped<IPasswordHasher, PasswordHasher>();
        services.AddScoped<ITokenService, TokenService>();
        services.AddScoped<IPasswordHasher, PasswordHasher>();
        services.AddScoped<ITokenService, TokenService>();
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IUserService, UserService>();
        services.AddScoped<ICompanyService, CompanyService>();
        services.AddScoped<ISiteService, SiteService>();
        services.AddScoped<IProjectService, ProjectService>();
        services.AddScoped<
            IDailyProgressLogService,
            DailyProgressLogService>();
        services.AddScoped<IProjectPhaseService, ProjectPhaseService>();
        services.AddScoped<IMilestoneService, MilestoneService>();
        services.AddScoped<IWorkTaskService, WorkTaskService>();
        services.AddScoped<IShiftService, ShiftService>();

        services.AddScoped<
            ISiteAssignmentService,
            SiteAssignmentService>();
        services.AddScoped<
            IAttendanceService,
            AttendanceService>();
        services.AddScoped<
            ILeaveService,
            LeaveService>();
        services.AddScoped<ITimesheetService, TimesheetService>();
        services.AddScoped<IPayrollService, PayrollService>();
        services.AddScoped<IMaterialService, MaterialService>();
        services.AddScoped<IEquipmentService, EquipmentService>();
        services.AddScoped<IEquipmentAssignmentService, EquipmentAssignmentService>();
        services.AddScoped<IEquipmentMaintenanceService, EquipmentMaintenanceService>();
        services.AddScoped<
            IEquipmentDowntimeService,
            EquipmentDowntimeService>();
        services.AddScoped<IRebarSpecService, RebarSpecService>();
        services.AddScoped<IVendorService, VendorService>();
services.AddScoped<IDocumentCategoryService, DocumentCategoryService>();
services.AddScoped<IDocumentService, DocumentService>();
services.AddScoped<IDocumentVersionService, DocumentVersionService>();
services.AddScoped<IPermitService, PermitService>();
services.AddScoped<IInspectionService, InspectionService>();
services.AddScoped<ISafetyIncidentService, SafetyIncidentService>();
        services.AddScoped<IPurchaseOrderService, PurchaseOrderService>();
        services.AddScoped<IMaterialRequestService, MaterialRequestService>();
        services.AddScoped<IGoodsReceiptService, GoodsReceiptService>();
    services.AddScoped<IStockReturnService, StockReturnService>();
    services.AddScoped<IStockMovementService, StockMovementService>();
    services.AddScoped<IStockIssueService, StockIssueService>();
    services.AddScoped<
        IDailyMaterialUsageService,
        DailyMaterialUsageService>();
        services.AddScoped<IContractorService, ContractorService>();
        services.AddScoped<IEmployeeService, EmployeeService>();
        services.AddScoped<IStockTransferService, StockTransferService>();
        services.AddScoped<IStockAdjustmentService, StockAdjustmentService>();
        services.AddScoped<IStockBalanceService, StockBalanceService>();
        services.AddScoped<ICostCodeService, CostCodeService>();
        services.AddScoped<IBudgetService, BudgetService>();
        services.AddScoped<IBudgetLineService, BudgetLineService>();
        services.AddScoped<IExpenseService, ExpenseService>();
        services.AddScoped<IInvoiceService, InvoiceService>();
        services.AddScoped<IInvoiceLineService, InvoiceLineService>();
        services.AddScoped<IPaymentService, PaymentService>();
        services.AddScoped<IReportingService, ReportingService>();
        services.AddScoped<INotificationService, NotificationService>();

        services
            .AddAuthentication(options =>
            {
                options.DefaultAuthenticateScheme =
                    JwtBearerDefaults.AuthenticationScheme;

                options.DefaultChallengeScheme =
                    JwtBearerDefaults.AuthenticationScheme;
            })
            .AddJwtBearer(options =>
            {
                options.MapInboundClaims = false;

                options.TokenValidationParameters =
                    new TokenValidationParameters
                    {
                        ValidateIssuer = true,
                        ValidIssuer = jwtSettings.Issuer,

                        ValidateAudience = true,
                        ValidAudience = jwtSettings.Audience,

                        ValidateIssuerSigningKey = true,
                        IssuerSigningKey =
                            new SymmetricSecurityKey(
                                Encoding.UTF8.GetBytes(
                                    jwtSettings.SecretKey)),

                        ValidateLifetime = true,
                        ClockSkew = TimeSpan.FromSeconds(30),

                        NameClaimType = ClaimTypes.Name,
                        RoleClaimType = ClaimTypes.Role
                    };
            });

        services.AddAuthorization(options =>
        {
            options.AddPolicy(
                AppPolicies.UserManagement,
                policy => policy.RequireRole(
                    AppPolicies.UserManagementRoles));

            options.AddPolicy(
                AppPolicies.SiteManagement,
                policy => policy.RequireRole(
                    AppPolicies.SiteManagementRoles));

            options.AddPolicy(
                AppPolicies.HRManagement,
                policy => policy.RequireRole(
                    AppPolicies.HRManagementRoles));

            options.AddPolicy(
                AppPolicies.FinanceManagement,
                policy => policy.RequireRole(
                    AppPolicies.FinanceManagementRoles));

            options.AddPolicy(
                AppPolicies.ProcurementManagement,
                policy => policy.RequireRole(
                    AppPolicies.ProcurementManagementRoles));

                   options.AddPolicy(
                       AppPolicies.CompanyManagement,
                       policy => policy.RequireRole(
                           AppPolicies.CompanyManagementRoles));
           options.AddPolicy(
               AppPolicies.ProjectManagement,
               policy => policy.RequireRole(
                   AppPolicies.ProjectManagementRoles));
        });


        return services;
    }
}









































