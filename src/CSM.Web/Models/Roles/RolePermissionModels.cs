namespace CSM.Web.Models.Roles;

public class RoleSummaryModel
{
    public Guid Id { get; set; }
    public string Name { get; set; } = "";
}

public class RolePermissionModel
{
    // The API sends the GranularPermission name as text
    // (for example "HRM_Payroll_View"). Keeping it as a string means a
    // permission added on the API side shows up here automatically,
    // with no matching enum to keep in sync.
    public string Permission { get; set; } = "";

    public bool Granted { get; set; }
}

public class UpdateRolePermissionsModel
{
    public List<string> Permissions { get; set; } = [];
}
