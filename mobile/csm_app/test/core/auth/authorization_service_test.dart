import 'package:flutter_test/flutter_test.dart';

import 'package:csm_app/core/auth/app_roles.dart';
import 'package:csm_app/core/auth/authorization_service.dart';

void main() {
  group('AuthorizationService', () {
    test('SuperAdmin can access all management policies', () {
      const authorization = AuthorizationService(
        roles: {AppRoles.superAdmin},
      );

      expect(authorization.canAccessProjectManagement(), isTrue);
      expect(authorization.canAccessCompanyManagement(), isTrue);
      expect(authorization.canAccessUserManagement(), isTrue);
      expect(authorization.canAccessSiteManagement(), isTrue);
      expect(authorization.canAccessHrManagement(), isTrue);
      expect(authorization.canAccessFinanceManagement(), isTrue);
      expect(authorization.canAccessProcurementManagement(), isTrue);
    });

    test('CompanyAdmin has verified company management access', () {
      const authorization = AuthorizationService(
        roles: {AppRoles.companyAdmin},
      );

      expect(authorization.canAccessProjectManagement(), isTrue);
      expect(authorization.canAccessCompanyManagement(), isFalse);
      expect(authorization.canAccessUserManagement(), isTrue);
      expect(authorization.canAccessSiteManagement(), isTrue);
      expect(authorization.canAccessHrManagement(), isTrue);
      expect(authorization.canAccessFinanceManagement(), isTrue);
      expect(authorization.canAccessProcurementManagement(), isTrue);
    });

    test('SiteManager can access site, procurement and project management',
        () {
      const authorization = AuthorizationService(
        roles: {AppRoles.siteManager},
      );

      expect(authorization.canAccessProjectManagement(), isTrue);
      expect(authorization.canAccessSiteManagement(), isTrue);
      expect(authorization.canAccessProcurementManagement(), isTrue);
      expect(authorization.canAccessCompanyManagement(), isFalse);
      expect(authorization.canAccessUserManagement(), isFalse);
      expect(authorization.canAccessHrManagement(), isFalse);
      expect(authorization.canAccessFinanceManagement(), isFalse);
    });

    test('Accountant can access finance management only', () {
      const authorization = AuthorizationService(
        roles: {AppRoles.accountant},
      );

      expect(authorization.canAccessFinanceManagement(), isTrue);
      expect(authorization.canAccessProjectManagement(), isFalse);
      expect(authorization.canAccessCompanyManagement(), isFalse);
      expect(authorization.canAccessUserManagement(), isFalse);
      expect(authorization.canAccessSiteManagement(), isFalse);
      expect(authorization.canAccessHrManagement(), isFalse);
      expect(authorization.canAccessProcurementManagement(), isFalse);
    });

    test('HROfficer can access HR management only', () {
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

    test('Supervisor can access site and project management', () {
      const authorization = AuthorizationService(
        roles: {AppRoles.supervisor},
      );

      expect(authorization.canAccessProjectManagement(), isTrue);
      expect(authorization.canAccessSiteManagement(), isTrue);
      expect(authorization.canAccessCompanyManagement(), isFalse);
      expect(authorization.canAccessUserManagement(), isFalse);
      expect(authorization.canAccessHrManagement(), isFalse);
      expect(authorization.canAccessFinanceManagement(), isFalse);
      expect(authorization.canAccessProcurementManagement(), isFalse);
    });

    test('Employee has no management policy access', () {
      const authorization = AuthorizationService(
        roles: {AppRoles.employee},
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
