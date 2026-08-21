import 'app_policies.dart';

class AuthorizationService {
  const AuthorizationService({
    required this.roles,
  });

  final Set<String> roles;

  bool hasRole(String role) {
    return roles.contains(role);
  }

  bool hasAnyRole(Iterable<String> allowedRoles) {
    return allowedRoles.any(roles.contains);
  }

  bool canAccessUserManagement() {
    return hasAnyRole(
      AppPolicies.userManagementRoles,
    );
  }

  bool canAccessSiteManagement() {
    return hasAnyRole(
      AppPolicies.siteManagementRoles,
    );
  }

  bool canAccessHrManagement() {
    return hasAnyRole(
      AppPolicies.hrManagementRoles,
    );
  }

  bool canAccessFinanceManagement() {
    return hasAnyRole(
      AppPolicies.financeManagementRoles,
    );
  }

  bool canAccessProcurementManagement() {
    return hasAnyRole(
      AppPolicies.procurementManagementRoles,
    );
  }

  bool canAccessCompanyManagement() {
    return hasAnyRole(
      AppPolicies.companyManagementRoles,
    );
  }

  bool canAccessProjectManagement() {
    return hasAnyRole(
      AppPolicies.projectManagementRoles,
    );
  }
}
