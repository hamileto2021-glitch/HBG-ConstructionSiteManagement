namespace CSM.Domain.Constants;

public static class AppRoles
{
    public const string SuperAdmin = "SuperAdmin";
    public const string CompanyAdmin = "CompanyAdmin";
    public const string SiteManager = "SiteManager";
    public const string Accountant = "Accountant";
    public const string HROfficer = "HROfficer";
    public const string Supervisor = "Supervisor";
    public const string Employee = "Employee";

    public static readonly string[] All =
    [
        SuperAdmin,
        CompanyAdmin,
        SiteManager,
        Accountant,
        HROfficer,
        Supervisor,
        Employee
    ];
}