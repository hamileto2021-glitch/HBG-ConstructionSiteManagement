import 'package:flutter/material.dart';

import '../../../../core/auth/app_roles.dart';
import '../../../../core/auth/authorization_service.dart';
import '../data/models/executive_dashboard.dart';
import '../data/repositories/reports_repository.dart';
import 'tabs/equipment_report_tab.dart';
import 'tabs/executive_report_tab.dart';
import 'tabs/financial_report_tab.dart';
import 'tabs/hr_report_tab.dart';
import 'tabs/project_report_tab.dart';

class ReportsDashboardScreen extends StatefulWidget {
  const ReportsDashboardScreen({
    super.key,
    required this.roles,
  });

  final Set<String> roles;

  @override
  State<ReportsDashboardScreen> createState() =>
      _ReportsDashboardScreenState();
}

class _ReportsDashboardScreenState
    extends State<ReportsDashboardScreen> {
  final _repository = ReportsRepository();

  ExecutiveDashboard? _executive;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final executive =
      await _repository.getExecutiveDashboard();

      if (!mounted) return;

      setState(() {
        _executive = executive;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_executive == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reports')),
        body: const Center(
          child: Text('Unable to load dashboard'),
        ),
      );
    }

    final e = _executive!;
    final roles = widget.roles;

    final authorization = AuthorizationService(
      roles: roles,
    );

    final tabs = <Tab>[];
    final pages = <Widget>[];

    // Executive
    if (roles.contains(AppRoles.administrator) ||
        roles.contains(AppRoles.projectManager)) {
      tabs.add(const Tab(text: 'Executive'));
      pages.add(
        ExecutiveReportTab(
          executive: e,
        ),
      );
    }

    // Projects
    if (authorization.canAccessProjectManagement()) {
      tabs.add(const Tab(text: 'Projects'));
      pages.add(const ProjectReportTab());
    }

    // Financial
    if (authorization.canAccessFinanceManagement()) {
      tabs.add(const Tab(text: 'Financial'));
      pages.add(const FinancialReportTab());
    }

    // Equipment
    if (authorization.canAccessEquipmentManagement()) {
      tabs.add(const Tab(text: 'Equipment'));
      pages.add(const EquipmentReportTab());
    }

    // HR
    if (authorization.canAccessHrManagement()) {
      tabs.add(const Tab(text: 'HR'));
      pages.add(const HrReportTab());
    }

    // Storekeeper / Procurement
    if (roles.contains(AppRoles.storekeeper) ||
        roles.contains(AppRoles.procurementOfficer)) {
      tabs.add(const Tab(text: 'Inventory'));
      pages.add(const ProjectReportTab());
    }

    // Safety
    if (roles.contains(AppRoles.safetyOfficer)) {
      tabs.add(const Tab(text: 'Compliance'));
      pages.add(const ProjectReportTab());
    }

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reports & Analytics'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _load,
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: tabs,
          ),
        ),
        body: TabBarView(
          children: pages,
        ),
      ),
    );
  }
}