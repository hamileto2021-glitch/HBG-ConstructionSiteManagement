import '../../../../core/auth/app_policies.dart';

enum AdminNavPolicy {
  dashboard,
  projectManagement,
  companyManagement,
  userManagement,
  siteManagement,
  hrManagement,
  financeManagement,
  procurementManagement,
  inventoryManagement,
  reportManagement,
  complianceManagement,
}

class AdminNavItem {
  const AdminNavItem({
    required this.label,
    required this.route,
    required this.policy,
  });

  final String label;
  final String route;
  final AdminNavPolicy policy;

  static const List<AdminNavItem> all = [
    AdminNavItem(
      label: 'Dashboard',
      route: '/admin',
      policy: AdminNavPolicy.dashboard,
    ),
    AdminNavItem(
      label: 'Projects',
      route: '/admin/projects',
      policy: AdminNavPolicy.projectManagement,
    ),
    AdminNavItem(
      label: 'Company',
      route: '/admin/company',
      policy: AdminNavPolicy.companyManagement,
    ),
    AdminNavItem(
      label: 'Users',
      route: '/admin/users',
      policy: AdminNavPolicy.userManagement,
    ),
    AdminNavItem(
      label: 'Sites',
      route: '/admin/sites',
      policy: AdminNavPolicy.siteManagement,
    ),
    AdminNavItem(
      label: 'HR',
      route: '/admin/hr',
      policy: AdminNavPolicy.hrManagement,
    ),
    AdminNavItem(
      label: 'Finance',
      route: '/admin/finance',
      policy: AdminNavPolicy.financeManagement,
    ),
    AdminNavItem(
      label: 'Procurement',
      route: '/admin/procurement',
      policy: AdminNavPolicy.procurementManagement,
    ),
    AdminNavItem(
      label: 'Inventory',
      route: '/admin/inventory',
      policy: AdminNavPolicy.inventoryManagement,
    ),
    AdminNavItem(
      label: 'Compliance',
      route: '/admin/compliance',
      policy: AdminNavPolicy.complianceManagement,
    ),
    AdminNavItem(
      label: 'Reports',
      route: '/reports',
      policy: AdminNavPolicy.reportManagement,
    ),
  ];


  bool isAllowedBy(Set<String> roles) {
    switch (policy) {
      case AdminNavPolicy.dashboard:
        return true;

      case AdminNavPolicy.projectManagement:
        return roles.any(
          AppPolicies.projectManagementRoles.contains,
        );

      case AdminNavPolicy.companyManagement:
        return roles.any(
          AppPolicies.companyManagementRoles.contains,
        );

      case AdminNavPolicy.userManagement:
        return roles.any(
          AppPolicies.userManagementRoles.contains,
        );

      case AdminNavPolicy.siteManagement:
        return roles.any(
          AppPolicies.siteManagementRoles.contains,
        );

      case AdminNavPolicy.hrManagement:
        return roles.any(
          AppPolicies.hrManagementRoles.contains,
        );

      case AdminNavPolicy.financeManagement:
        return roles.any(
          AppPolicies.financeManagementRoles.contains,
        );

      case AdminNavPolicy.procurementManagement:
        return roles.any(
          AppPolicies.procurementManagementRoles.contains,
        );

      case AdminNavPolicy.inventoryManagement:
        return roles.any(
          AppPolicies.procurementManagementRoles.contains,
        );

      case AdminNavPolicy.reportManagement:
        return roles.any(
          AppPolicies.projectManagementRoles.contains,
        );
      case AdminNavPolicy.complianceManagement:
        return roles.any(
          AppPolicies.procurementManagementRoles.contains,
        );
    }
  }

  static List<AdminNavItem> forRoles(Set<String> roles) {
    return all.where(
      (item) => item.isAllowedBy(roles),
    ).toList();
  }
}
