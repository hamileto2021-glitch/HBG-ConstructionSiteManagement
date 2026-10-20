enum UserRole {
  admin,
  projectManager,
  siteEngineer,
  hr,
  storeKeeper,
  accountant,
  unknown,
}

class RolePermissions {
  static UserRole parse(List<String> roles) {
    final normalized = roles.map((e) => e.toLowerCase()).toList();

    if (normalized.contains('admin')) return UserRole.admin;
    if (normalized.contains('projectmanager')) {
      return UserRole.projectManager;
    }
    if (normalized.contains('siteengineer')) {
      return UserRole.siteEngineer;
    }
    if (normalized.contains('hr')) return UserRole.hr;
    if (normalized.contains('storekeeper')) {
      return UserRole.storeKeeper;
    }
    if (normalized.contains('accountant')) {
      return UserRole.accountant;
    }

    return UserRole.unknown;
  }

  static bool canEditProject(UserRole role) =>
      role == UserRole.admin ||
          role == UserRole.projectManager ||
          role == UserRole.siteEngineer;

  static bool canManagePayroll(UserRole role) =>
      role == UserRole.admin ||
          role == UserRole.hr ||
          role == UserRole.accountant;

  static bool canManageInventory(UserRole role) =>
      role == UserRole.admin ||
          role == UserRole.storeKeeper;
}