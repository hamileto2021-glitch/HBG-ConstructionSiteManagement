using CSM.Domain.Constants;

namespace CSM.Application.Common.Security;

public static class AppPolicies
{
    public const string UserManagement = "UserManagement";
    public const string SiteManagement = "SiteManagement";
    public const string HRManagement = "HRManagement";
    public const string FinanceManagement = "FinanceManagement";
    public const string ProcurementManagement = "ProcurementManagement";
    public const string CompanyManagement = "CompanyManagement";
    public const string ProjectManagement = "ProjectManagement";

    public static readonly string[] ProjectManagementRoles =
    [
        AppRoles.SuperAdmin,
        AppRoles.CompanyAdmin,
        AppRoles.SiteManager,
        AppRoles.Supervisor
    ];

    public static readonly string[] CompanyManagementRoles =
    [
        AppRoles.SuperAdmin
    ];

    public static readonly string[] UserManagementRoles =
    [
        AppRoles.SuperAdmin,
        AppRoles.CompanyAdmin
    ];

    public static readonly string[] SiteManagementRoles =
    [
        AppRoles.SuperAdmin,
        AppRoles.CompanyAdmin,
        AppRoles.SiteManager,
        AppRoles.Supervisor
    ];

    public static readonly string[] HRManagementRoles =
    [
        AppRoles.SuperAdmin,
        AppRoles.CompanyAdmin,
        AppRoles.HROfficer
    ];

    public static readonly string[] FinanceManagementRoles =
    [
        AppRoles.SuperAdmin,
        AppRoles.CompanyAdmin,
        AppRoles.Accountant
    ];

    public static readonly string[] ProcurementManagementRoles =
    [
        AppRoles.SuperAdmin,
        AppRoles.CompanyAdmin,
        AppRoles.SiteManager
    ];
}