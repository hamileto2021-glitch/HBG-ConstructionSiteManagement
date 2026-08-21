import 'app_roles.dart';

class AppPolicies {
  AppPolicies._();

  static const String userManagement = 'UserManagement';
  static const String siteManagement = 'SiteManagement';
  static const String hrManagement = 'HRManagement';
  static const String financeManagement = 'FinanceManagement';
  static const String procurementManagement = 'ProcurementManagement';
  static const String companyManagement = 'CompanyManagement';
  static const String projectManagement = 'ProjectManagement';

  static const List<String> projectManagementRoles = [
    AppRoles.superAdmin,
    AppRoles.companyAdmin,
    AppRoles.siteManager,
    AppRoles.supervisor,
  ];

  static const List<String> companyManagementRoles = [
    AppRoles.superAdmin,
  ];

  static const List<String> userManagementRoles = [
    AppRoles.superAdmin,
    AppRoles.companyAdmin,
  ];

  static const List<String> siteManagementRoles = [
    AppRoles.superAdmin,
    AppRoles.companyAdmin,
    AppRoles.siteManager,
    AppRoles.supervisor,
  ];

  static const List<String> hrManagementRoles = [
    AppRoles.superAdmin,
    AppRoles.companyAdmin,
    AppRoles.hrOfficer,
  ];

  static const List<String> financeManagementRoles = [
    AppRoles.superAdmin,
    AppRoles.companyAdmin,
    AppRoles.accountant,
  ];

  static const List<String> procurementManagementRoles = [
    AppRoles.superAdmin,
    AppRoles.companyAdmin,
    AppRoles.siteManager,
  ];
}
