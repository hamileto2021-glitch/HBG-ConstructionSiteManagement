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
  static const String equipmentManagement = 'EquipmentManagement';
  static const String complianceManagement = 'ComplianceManagement';
  static const String reportManagement = 'ReportManagement';

  static const List<String> projectManagementRoles = [
    AppRoles.administrator,
    AppRoles.projectManager,
    AppRoles.siteEngineer,
  ];

  static const List<String> companyManagementRoles = [
    AppRoles.administrator,
  ];

  static const List<String> userManagementRoles = [
    AppRoles.administrator,
  ];

  static const List<String> siteManagementRoles = [
    AppRoles.administrator,
    AppRoles.projectManager,
    AppRoles.siteEngineer,
  ];

  static const List<String> hrManagementRoles = [
    AppRoles.administrator,
    AppRoles.hrOfficer,
  ];

  static const List<String> financeManagementRoles = [
    AppRoles.administrator,
    AppRoles.financeOfficer,
  ];

  static const List<String> procurementManagementRoles = [
    AppRoles.administrator,
    AppRoles.procurementOfficer,
    AppRoles.storekeeper,
  ];

  static const List<String> equipmentManagementRoles = [
    AppRoles.administrator,
    AppRoles.equipmentManager,
  ];

  static const List<String> complianceManagementRoles = [
    AppRoles.administrator,
    AppRoles.safetyOfficer,
  ];

  static const List<String> reportManagementRoles = [
    AppRoles.administrator,
    AppRoles.projectManager,
    AppRoles.siteEngineer,
    AppRoles.storekeeper,
    AppRoles.procurementOfficer,
    AppRoles.financeOfficer,
    AppRoles.hrOfficer,
    AppRoles.equipmentManager,
    AppRoles.safetyOfficer,
  ];
}