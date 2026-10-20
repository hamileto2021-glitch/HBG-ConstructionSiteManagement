class UserRoles {
  static const administrator = 'Administrator';
  static const projectManager = 'ProjectManager';
  static const siteEngineer = 'SiteEngineer';
  static const storekeeper = 'Storekeeper';
  static const procurementOfficer = 'ProcurementOfficer';
  static const hrOfficer = 'HrOfficer';
  static const equipmentManager = 'EquipmentManager';
  static const safetyOfficer = 'SafetyOfficer';

  static const all = <String>[
    administrator,
    projectManager,
    siteEngineer,
    storekeeper,
    procurementOfficer,
    hrOfficer,
    equipmentManager,
    safetyOfficer,
  ];

  static bool hasRole(Set<String> roles, String role) {
    return roles.any(
          (r) => r.toLowerCase() == role.toLowerCase(),
    );
  }
}