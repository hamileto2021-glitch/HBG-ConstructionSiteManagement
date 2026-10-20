import 'package:flutter_test/flutter_test.dart';

import 'package:csm_app/core/auth/app_roles.dart';
import 'package:csm_app/core/auth/authorization_service.dart';

void main() {
  group('AuthorizationService', () {
    test('Administrator can access all management policies', () {
      const authorization = AuthorizationService(
        roles: {AppRoles.administrator},
      );

      expect(authorization.canAccessProjectManagement(), isTrue);
      expect(authorization.canAccessCompanyManagement(), isTrue);
      expect(authorization.canAccessUserManagement(), isTrue);
      expect(authorization.canAccessSiteManagement(), isTrue);
      expect(authorization.canAccessHrManagement(), isTrue);
      expect(authorization.canAccessFinanceManagement(), isTrue);
      expect(authorization.canAccessProcurementManagement(), isTrue);
    });

    test('Project Manager has project and site access', () {
      const authorization = AuthorizationService(
        roles: {AppRoles.projectManager},
      );

      expect(authorization.canAccessProjectManagement(), isTrue);
      expect(authorization.canAccessCompanyManagement(), isFalse);
      expect(authorization.canAccessUserManagement(), isFalse);
      expect(authorization.canAccessSiteManagement(), isTrue);
      expect(authorization.canAccessHrManagement(), isFalse);
      expect(authorization.canAccessFinanceManagement(), isFalse);
      expect(authorization.canAccessProcurementManagement(), isFalse);
    });

    test('Site Engineer can access project and site management', () {
      const authorization = AuthorizationService(
        roles: {AppRoles.siteEngineer},
      );

      expect(authorization.canAccessProjectManagement(), isTrue);
      expect(authorization.canAccessSiteManagement(), isTrue);
      expect(authorization.canAccessCompanyManagement(), isFalse);
      expect(authorization.canAccessUserManagement(), isFalse);
      expect(authorization.canAccessHrManagement(), isFalse);
      expect(authorization.canAccessFinanceManagement(), isFalse);
      expect(authorization.canAccessProcurementManagement(), isFalse);
    });

    test('Finance Officer can access finance only', () {
      const authorization = AuthorizationService(
        roles: {AppRoles.financeOfficer},
      );

      expect(authorization.canAccessFinanceManagement(), isTrue);
      expect(authorization.canAccessProjectManagement(), isFalse);
      expect(authorization.canAccessCompanyManagement(), isFalse);
      expect(authorization.canAccessUserManagement(), isFalse);
      expect(authorization.canAccessSiteManagement(), isFalse);
      expect(authorization.canAccessHrManagement(), isFalse);
      expect(authorization.canAccessProcurementManagement(), isFalse);
    });

    test('HR Officer can access HR only', () {
      const authorization = AuthorizationService(
        roles: {AppRoles.hrOfficer},
      );

      expect(authorization.canAccessHrManagement(), isTrue);
      expect(authorization.canAccessProjectManagement(), isFalse);
      expect(authorization.canAccessCompanyManagement(), isFalse);
      expect(authorization.canAccessUserManagement(), isFalse);
      expect(authorization.canAccessSiteManagement(), isFalse);
      expect(authorization.canAccessFinanceManagement(), isFalse);
      expect(authorization.canAccessProcurementManagement(), isFalse);
    });

    test('Storekeeper can access procurement only', () {
      const authorization = AuthorizationService(
        roles: {AppRoles.storekeeper},
      );

      expect(authorization.canAccessProcurementManagement(), isTrue);
      expect(authorization.canAccessProjectManagement(), isFalse);
      expect(authorization.canAccessCompanyManagement(), isFalse);
      expect(authorization.canAccessUserManagement(), isFalse);
      expect(authorization.canAccessSiteManagement(), isFalse);
      expect(authorization.canAccessHrManagement(), isFalse);
      expect(authorization.canAccessFinanceManagement(), isFalse);
    });

    test('Procurement Officer can access procurement only', () {
      const authorization = AuthorizationService(
        roles: {AppRoles.procurementOfficer},
      );

      expect(authorization.canAccessProcurementManagement(), isTrue);
      expect(authorization.canAccessProjectManagement(), isFalse);
      expect(authorization.canAccessCompanyManagement(), isFalse);
      expect(authorization.canAccessUserManagement(), isFalse);
      expect(authorization.canAccessSiteManagement(), isFalse);
      expect(authorization.canAccessHrManagement(), isFalse);
      expect(authorization.canAccessFinanceManagement(), isFalse);
    });

    test('Equipment Manager has no legacy management access', () {
      const authorization = AuthorizationService(
        roles: {AppRoles.equipmentManager},
      );

      expect(authorization.canAccessProjectManagement(), isFalse);
      expect(authorization.canAccessCompanyManagement(), isFalse);
      expect(authorization.canAccessUserManagement(), isFalse);
      expect(authorization.canAccessSiteManagement(), isFalse);
      expect(authorization.canAccessHrManagement(), isFalse);
      expect(authorization.canAccessFinanceManagement(), isFalse);
      expect(authorization.canAccessProcurementManagement(), isFalse);
    });

    test('Safety Officer has no legacy management access', () {
      const authorization = AuthorizationService(
        roles: {AppRoles.safetyOfficer},
      );

      expect(authorization.canAccessProjectManagement(), isFalse);
      expect(authorization.canAccessCompanyManagement(), isFalse);
      expect(authorization.canAccessUserManagement(), isFalse);
      expect(authorization.canAccessSiteManagement(), isFalse);
      expect(authorization.canAccessHrManagement(), isFalse);
      expect(authorization.canAccessFinanceManagement(), isFalse);
      expect(authorization.canAccessProcurementManagement(), isFalse);
    });
  });
}