import 'package:flutter/material.dart';

import '../../../core/auth/authorization_service.dart';
import '../../../core/sync/sync_manager.dart';

import '../navigation/admin_nav_item.dart';

import '../projects/data/repositories/project_repository.dart';
import '../projects/presentation/project_list_screen.dart';
import '../../../core/network/api_client.dart';
import '../hrm/presentation/hr_dashboard_screen.dart';
import '../financial/presentation/financial_dashboard_screen.dart';
import '../procurement/presentation/procurement_dashboard_screen.dart';
import '../inventory/presentation/inventory_dashboard_screen.dart';
import '../users/data/repositories/user_repository.dart';
import '../users/presentation/user_list_screen.dart';
import '../sites/data/repositories/site_repository.dart';
import '../sites/presentation/site_list_screen.dart';
import '../reports/presentation/reports_dashboard_screen.dart';
import '../compliance/presentation/compliance_home_screen.dart';

import '../../common/notifications/data/notification_repository.dart';
import '../../common/notifications/presentation/notification_center_screen.dart';

import '../company/presentation/company_settings_screen.dart';
import '../../../core/auth/authorization_guard.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/connectivity_service.dart';
import '../../../core/sync/sync_queue_service.dart';
import '../../../core/sync/sync_engine.dart';

import '../../../core/sync/default_sync_operation_handler.dart';

import '../hrm/data/repositories/attendance_repository.dart';
import '../projects/data/repositories/daily_progress_repository.dart';
import '../equipment/data/repositories/equipment_hour_repository.dart';
import 'package:csm_app/features/admin/procurement/equipment_fuel_logs/data/repositories/equipment_fuel_log_repository.dart';
import 'package:csm_app/features/admin/projects/data/repositories/project_delay_repository.dart';
import '../../../responsive/responsive_scaffold.dart';
import '../../../responsive/breakpoints.dart';
import '../procurement/presentation/equipment_list_screen.dart';
import '../dashboard/presentation/executive_dashboard_screen.dart';



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
  late final NotificationRepository _notificationRepository;

  late final AppDatabase _database;
  late final ConnectivityService _connectivity;
  late final AttendanceRepository _attendanceRepository;
  late final SyncQueueService _syncQueue;
  late final SyncEngine _syncEngine;
  late final SyncManager _syncManager;

  late final List<AdminNavItem> _items;
  late final DailyProgressRepository _dailyProgressRepository;
  late final EquipmentHourRepository _equipmentHourRepository;
  late final EquipmentFuelLogRepository _equipmentFuelRepository;
  late final ProjectDelayRepository _projectDelayRepository;


  @override
  void initState() {
    super.initState();

    _authorization = AuthorizationService(roles: widget.roles);
    _notificationRepository = NotificationRepository(
      ApiClient(),
    );

    _database = AppDatabase();
    _connectivity = ConnectivityService();

    _attendanceRepository = AttendanceRepository(
      database: _database,
      connectivity: _connectivity,
    );
    _dailyProgressRepository = DailyProgressRepository(
      database: _database,
      connectivity: _connectivity,
    );

    _equipmentHourRepository = EquipmentHourRepository(
      database: _database,
      connectivity: _connectivity,
    );

    _equipmentFuelRepository = EquipmentFuelLogRepository();

    _projectDelayRepository = ProjectDelayRepository();



    _syncQueue = SyncQueueService(database: _database);

    _syncEngine = SyncEngine(
      queue: _syncQueue,
      handler: DefaultSyncOperationHandler(
        attendanceRepository: _attendanceRepository,
        dailyProgressRepository: _dailyProgressRepository,
        equipmentHourRepository: _equipmentHourRepository,
        equipmentFuelRepository: _equipmentFuelRepository,
        projectDelayRepository: _projectDelayRepository,
      ),
    );

    _syncManager = SyncManager(
      queue: _syncQueue,
      engine: _syncEngine,
      connectivity: _connectivity,
    );

    _items = [
      if (_authorization.canAccessReportManagement())
        AdminNavItem(
          label: 'Dashboard',
          route: '/dashboard',
          policy: AdminNavPolicy.dashboard,
        ),

      if (_authorization.canAccessProjectManagement())
        AdminNavItem(
          label: 'Projects',
          route: '/projects',
          policy: AdminNavPolicy.projectManagement,
        ),

      if (_authorization.canAccessSiteManagement())
        AdminNavItem(
          label: 'Sites',
          route: '/sites',
          policy: AdminNavPolicy.siteManagement,
        ),

      if (_authorization.canAccessUserManagement())
        AdminNavItem(
          label: 'Users',
          route: '/users',
          policy: AdminNavPolicy.userManagement,
        ),

      if (_authorization.canAccessHrManagement())
        AdminNavItem(
          label: 'HR',
          route: '/hr',
          policy: AdminNavPolicy.hrManagement,
        ),

      if (_authorization.canAccessFinanceManagement())
        AdminNavItem(
          label: 'Finance',
          route: '/finance',
          policy: AdminNavPolicy.financeManagement,
        ),

      if (_authorization.canAccessProcurementManagement())
        AdminNavItem(
          label: 'Procurement',
          route: '/procurement',
          policy: AdminNavPolicy.procurementManagement,
        ),

      if (_authorization.canAccessProcurementManagement())
        AdminNavItem(
          label: 'Inventory',
          route: '/inventory',
          policy: AdminNavPolicy.inventoryManagement,
        ),

      if (_authorization.canAccessComplianceManagement())
        AdminNavItem(
          label: 'Compliance',
          route: '/compliance',
          policy: AdminNavPolicy.complianceManagement,
        ),

      if (_authorization.canAccessReportManagement())
        AdminNavItem(
          label: 'Reports',
          route: '/reports',
          policy: AdminNavPolicy.reportManagement,
        ),

      if (_authorization.canAccessCompanyManagement())
        AdminNavItem(
          label: 'Company',
          route: '/company',
          policy: AdminNavPolicy.companyManagement,
        ),


    ];

    _syncManager.startConnectivityMonitoring();
    _syncManager.refreshPendingCount();
  }

  @override
  void dispose() {
    _syncManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No application modules are assigned to your account. Contact your administrator for access.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final selectedItem = _items[_selectedIndex];

    return ResponsiveScaffold(
      title: selectedItem.label,
      selectedIndex: _selectedIndex,
      onSelected: (index) {
        setState(() => _selectedIndex = index);
      },

      appBarActions: [
        FutureBuilder<int>(
          future: _notificationRepository.getUnreadCount(),
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;

            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationCenterScreen(),
                      ),
                    );
                    setState(() {});
                  },
                ),
                if (count > 0)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),

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

      drawer: AppBreakpoints.isDesktop(context)
          ? null
          : _buildDrawer(context),

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
              accountEmail: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.userEmail),
                  const SizedBox(height: 4),
                  Text(
                    widget.roles.join(' • '),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
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
      return const ExecutiveDashboardScreen();
    }

    if (item.policy == AdminNavPolicy.projectManagement) {
      return ProjectListScreen(
        repository: ProjectRepository(),
      );
    }
    if (item.policy == AdminNavPolicy.companyManagement) {
      return AuthorizationGuard(
        roles: widget.roles,
        canAccess: (auth) => auth.canAccessCompanyManagement(),
        message: 'Your role does not have permission to access Company Settings.',
        child: const CompanySettingsScreen(),
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
      return AuthorizationGuard(
        roles: widget.roles,
        canAccess: (auth) => auth.canAccessHrManagement(),
        message: 'Your role does not have permission to access HR Management.',
        child: const HrDashboardScreen(),
      );
    }
    if (item.policy == AdminNavPolicy.financeManagement) {
      return AuthorizationGuard(
        roles: widget.roles,
        canAccess: (auth) => auth.canAccessFinanceManagement(),
        message: 'Your role does not have permission to access Finance.',
        child: const FinancialDashboardScreen(),
      );
    }

    if (item.policy == AdminNavPolicy.procurementManagement) {
      return AuthorizationGuard(
        roles: widget.roles,
        canAccess: (auth) => auth.canAccessProcurementManagement(),
        message: 'Your role does not have permission to access Procurement.',
        child: const ProcurementDashboardScreen(),
      );
    }
    if (item.policy == AdminNavPolicy.inventoryManagement) {
      return AuthorizationGuard(
        roles: widget.roles,
        canAccess: (auth) => auth.canAccessProcurementManagement(),
        message: 'Your role does not have permission to access Inventory.',
        child: const InventoryDashboardScreen(),
      );
    }
    if (item.policy == AdminNavPolicy.complianceManagement) {
      return const ComplianceHomeScreen();
    }
    if (item.policy == AdminNavPolicy.reportManagement) {
      return ReportsDashboardScreen(
        roles: widget.roles,
      );
    }
    if (item.policy == AdminNavPolicy.equipmentManagement) {
      return EquipmentListScreen();
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
      case AdminNavPolicy.equipmentManagement:
        return Icons.construction;
    }
  }

}


