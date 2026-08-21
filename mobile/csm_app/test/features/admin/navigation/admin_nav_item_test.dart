import 'package:flutter_test/flutter_test.dart';

import 'package:csm_app/core/auth/app_roles.dart';
import 'package:csm_app/features/admin/navigation/admin_nav_item.dart';

void main() {
  group('AdminNavItem', () {
    test('SuperAdmin sees every Admin navigation item', () {
      final items = AdminNavItem.forRoles(
        {AppRoles.superAdmin},
      );

      expect(items.length, AdminNavItem.all.length);
    });

    test('CompanyAdmin sees company-related management areas except Company Management', () {
      final items = AdminNavItem.forRoles(
        {AppRoles.companyAdmin},
      );

      final routes = items.map((item) => item.route).toSet();

      expect(routes, contains('/admin'));
      expect(routes, contains('/admin/projects'));
      expect(routes, contains('/admin/users'));
      expect(routes, contains('/admin/sites'));
      expect(routes, contains('/admin/hr'));
      expect(routes, contains('/admin/finance'));
      expect(routes, contains('/admin/procurement'));
      expect(routes, isNot(contains('/admin/company')));
    });

    test('SiteManager sees project, site and procurement navigation', () {
      final items = AdminNavItem.forRoles(
        {AppRoles.siteManager},
      );

      final routes = items.map((item) => item.route).toSet();

      expect(routes, contains('/admin'));
      expect(routes, contains('/admin/projects'));
      expect(routes, contains('/admin/sites'));
      expect(routes, contains('/admin/procurement'));

      expect(routes, isNot(contains('/admin/company')));
      expect(routes, isNot(contains('/admin/users')));
      expect(routes, isNot(contains('/admin/hr')));
      expect(routes, isNot(contains('/admin/finance')));
    });

    test('Accountant sees Finance and Dashboard only', () {
      final items = AdminNavItem.forRoles(
        {AppRoles.accountant},
      );

      final routes = items.map((item) => item.route).toSet();

      expect(routes, {'/admin', '/admin/finance'});
    });

    test('HROfficer sees HR and Dashboard only', () {
      final items = AdminNavItem.forRoles(
        {AppRoles.hrOfficer},
      );

      final routes = items.map((item) => item.route).toSet();

      expect(routes, {'/admin', '/admin/hr'});
    });

    test('Supervisor sees Project, Site and Dashboard', () {
      final items = AdminNavItem.forRoles(
        {AppRoles.supervisor},
      );

      final routes = items.map((item) => item.route).toSet();

      expect(
        routes,
        {
          '/admin',
          '/admin/projects',
          '/admin/sites',
        },
      );
    });

    test('Employee sees Dashboard only', () {
      final items = AdminNavItem.forRoles(
        {AppRoles.employee},
      );

      final routes = items.map((item) => item.route).toSet();

      expect(routes, {'/admin'});
    });
  });
}
