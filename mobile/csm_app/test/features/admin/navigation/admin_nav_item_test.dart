import 'package:flutter_test/flutter_test.dart';

import 'package:csm_app/core/auth/app_roles.dart';
import 'package:csm_app/features/admin/navigation/admin_nav_item.dart';

void main() {
  group('AdminNavItem', () {
    test('Administrator sees every navigation item', () {
      final items = AdminNavItem.forRoles(
        {AppRoles.administrator},
      );

      expect(items.length, AdminNavItem.all.length);
    });

    test('Project Manager sees project modules', () {
      final items = AdminNavItem.forRoles(
        {AppRoles.projectManager},
      );

      final routes = items.map((e) => e.route).toSet();

      expect(routes, contains('/admin'));
      expect(routes, contains('/admin/projects'));
      expect(routes, contains('/admin/sites'));
      expect(routes, contains('/admin/finance'));
      expect(routes, contains('/reports'));

      expect(routes, isNot(contains('/admin/users')));
      expect(routes, isNot(contains('/admin/company')));
    });

    test('Site Engineer sees project and site modules', () {
      final items = AdminNavItem.forRoles(
        {AppRoles.siteEngineer},
      );

      final routes = items.map((e) => e.route).toSet();

      expect(routes, contains('/admin'));
      expect(routes, contains('/admin/projects'));
      expect(routes, contains('/admin/sites'));
      expect(routes, contains('/reports'));

      expect(routes, isNot(contains('/admin/users')));
      expect(routes, isNot(contains('/admin/finance')));
    });

    test('Storekeeper sees inventory, procurement and reports', () {
      final items = AdminNavItem.forRoles(
        {AppRoles.storekeeper},
      );

      final routes = items.map((e) => e.route).toSet();

      expect(
        routes,
        {
          '/admin',
          '/admin/procurement',
          '/admin/inventory',
          '/reports',
        },
      );
    });

    test('Procurement Officer sees procurement and reports', () {
      final items = AdminNavItem.forRoles(
        {AppRoles.procurementOfficer},
      );

      final routes = items.map((e) => e.route).toSet();

      expect(
        routes,
        {
          '/admin',
          '/admin/procurement',
          '/reports',
        },
      );
    });

    test('Finance Officer sees finance and reports', () {
      final items = AdminNavItem.forRoles(
        {AppRoles.financeOfficer},
      );

      final routes = items.map((e) => e.route).toSet();

      expect(
        routes,
        {
          '/admin',
          '/admin/finance',
          '/reports',
        },
      );
    });

    test('HR Officer sees HR and reports', () {
      final items = AdminNavItem.forRoles(
        {AppRoles.hrOfficer},
      );

      final routes = items.map((e) => e.route).toSet();

      expect(
        routes,
        {
          '/admin',
          '/admin/hr',
          '/reports',
        },
      );
    });

    test('Equipment Manager sees equipment and reports', () {
      final items = AdminNavItem.forRoles(
        {AppRoles.equipmentManager},
      );

      final routes = items.map((e) => e.route).toSet();

      expect(
        routes,
        {
          '/admin',
          '/admin/equipment',
          '/reports',
        },
      );
    });

    test('Safety Officer sees compliance and reports', () {
      final items = AdminNavItem.forRoles(
        {AppRoles.safetyOfficer},
      );

      final routes = items.map((e) => e.route).toSet();

      expect(
        routes,
        {
          '/admin',
          '/admin/compliance',
          '/reports',
        },
      );
    });
  });
}