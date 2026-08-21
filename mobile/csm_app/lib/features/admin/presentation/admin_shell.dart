import 'package:flutter/material.dart';

import '../../../core/auth/authorization_service.dart';
import '../../../core/sync/sync_manager.dart';
import '../navigation/admin_nav_item.dart';
import 'admin_dashboard.dart';
import '../projects/data/repositories/project_repository.dart';
import '../projects/presentation/project_list_screen.dart';

import '../hrm/presentation/hr_dashboard_screen.dart';
import '../financial/presentation/financial_dashboard_screen.dart';
import '../procurement/presentation/procurement_dashboard_screen.dart';
import '../inventory/presentation/inventory_dashboard_screen.dart';
import '../users/data/repositories/user_repository.dart';
import '../users/presentation/user_list_screen.dart';
import '../sites/data/repositories/site_repository.dart';
import '../sites/presentation/site_list_screen.dart';
import '../reports/presentation/reports_dashboard_screen.dart';
import '../compliance/data/repositories/document_repository.dart';
import '../compliance/presentation/document_list_screen.dart';



class AdminShell extends StatefulWidget {
  const AdminShell({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.roles,
    this.syncManager,
    this.onLogout,
  });

  final String userName;
  final String userEmail;
  final Set<String> roles;
  final SyncManager? syncManager;
  final VoidCallback? onLogout;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  late final AuthorizationService _authorization;
  late List<AdminNavItem> _items;

  @override
  void initState() {
    super.initState();

    _authorization = AuthorizationService(
      roles: widget.roles,
    );

    _items = AdminNavItem.forRoles(widget.roles);
  }

  @override
  Widget build(BuildContext context) {
    final selectedItem = _items[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedItem.label),
        actions: [
          if (widget.syncManager != null)
            ListenableBuilder(
              listenable: widget.syncManager!,
              builder: (context, _) {
                final status = widget.syncManager!.status;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Center(
                    child: Tooltip(
                      message: status.errorMessage ??
                          'Pending: ${status.pendingCount}',
                      child: Icon(
                        status.isSyncing
                            ? Icons.sync
                            : status.hasError
                                ? Icons.sync_problem
                                : Icons.cloud_done_outlined,
                      ),
                    ),
                  ),
                );
              },
            ),
          PopupMenuButton<String>(
            tooltip: 'Account',
            onSelected: (value) {
              if (value == 'logout') {
                widget.onLogout?.call();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                enabled: false,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(widget.userName),
                  subtitle: Text(widget.userEmail),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Text('Sign out'),
              ),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _buildContent(context, selectedItem),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(widget.userName),
              accountEmail: Text(widget.userEmail),
              currentAccountPicture: const CircleAvatar(
                child: Icon(Icons.construction),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];

                  return ListTile(
                    selected: index == _selectedIndex,
                    leading: Icon(_iconFor(item.policy)),
                    title: Text(item.label),
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });

                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                widget.roles.join(', '),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AdminNavItem item,
  ) {
    if (item.policy == AdminNavPolicy.dashboard) {
      return AdminDashboard(
        userName: widget.userName,
        userEmail: widget.userEmail,
        roles: widget.roles,
        syncManager: widget.syncManager,
      );
    }

    if (item.policy == AdminNavPolicy.projectManagement) {
      return ProjectListScreen(
        repository: ProjectRepository(),
      );
    }
    if (item.policy == AdminNavPolicy.siteManagement) {
      return SiteListScreen(
        repository: SiteRepository(),
      );
    }
    if (item.policy == AdminNavPolicy.userManagement) {
      return UserListScreen(
        repository: UserRepository(),
      );
    }

    if (item.policy == AdminNavPolicy.hrManagement) {
      return const HrDashboardScreen();
    }
    if (item.policy == AdminNavPolicy.financeManagement) {
      return const FinancialDashboardScreen();
    }

    if (item.policy == AdminNavPolicy.procurementManagement) {
      return const ProcurementDashboardScreen();
    }
    if (item.policy == AdminNavPolicy.inventoryManagement) {
      return const InventoryDashboardScreen();
    }
    if (item.policy == AdminNavPolicy.complianceManagement) {
      return DocumentListScreen(
        repository: DocumentRepository(),
      );
    }
    if (item.policy == AdminNavPolicy.reportManagement) {
      return const ReportsDashboardScreen();
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _iconFor(item.policy),
                    size: 56,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.label,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.policy == AdminNavPolicy.dashboard
                        ? 'CSM Administration Dashboard'
                        : '${item.label} module',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (item.policy != AdminNavPolicy.dashboard)
                    Text(
                      'Module implementation will be added '
                      'incrementally.',
                      style:
                          Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  if (item.policy == AdminNavPolicy.dashboard)
                    _buildDashboardSummary(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardSummary(BuildContext context) {
    final cards = <String>[
      if (_authorization.canAccessProjectManagement())
        'Projects',
      if (_authorization.canAccessSiteManagement())
        'Sites',
      if (_authorization.canAccessUserManagement())
        'Users',
      if (_authorization.canAccessHrManagement())
        'HR',
      if (_authorization.canAccessFinanceManagement())
        'Finance',
      if (_authorization.canAccessProcurementManagement())
        'Procurement',
      if (_authorization.canAccessCompanyManagement())
        'Company',
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: cards
          .map(
            (label) => Chip(
              avatar: const Icon(Icons.check_circle_outline),
              label: Text(label),
            ),
          )
          .toList(),
    );
  }

  IconData _iconFor(AdminNavPolicy policy) {
    switch (policy) {
      case AdminNavPolicy.dashboard:
        return Icons.dashboard_outlined;
      case AdminNavPolicy.projectManagement:
        return Icons.assignment_outlined;
      case AdminNavPolicy.companyManagement:
        return Icons.business_outlined;
      case AdminNavPolicy.userManagement:
        return Icons.people_outline;
      case AdminNavPolicy.siteManagement:
        return Icons.location_city_outlined;
      case AdminNavPolicy.hrManagement:
        return Icons.badge_outlined;
      case AdminNavPolicy.financeManagement:
        return Icons.account_balance_outlined;
      case AdminNavPolicy.procurementManagement:
        return Icons.shopping_cart_outlined;
      case AdminNavPolicy.inventoryManagement:
        return Icons.inventory_2_outlined;
      case AdminNavPolicy.complianceManagement:
        return Icons.folder_outlined;
      case AdminNavPolicy.reportManagement:
        return Icons.bar_chart;

    }
  }
}


