import 'package:flutter/material.dart';

import '../../../core/sync/sync_manager.dart';
import '../../../core/sync/sync_status.dart';
import '../../dashboard/data/models/dashboard_stats.dart';
import '../../dashboard/presentation/dashboard_controller.dart';
import '../company/data/repositories/backup_repository.dart';
import '../company/presentation/backup_screen.dart';
import '../audit/data/repositories/audit_repository.dart';
import '../audit/presentation/audit_log_screen.dart';
import '../../../core/network/api_client.dart';
import '../../../responsive/breakpoints.dart';
import '../../../shared/widgets/dashboard_kpi_card.dart';
import '../../../shared/widgets/project_progress_chart.dart';
import '../../../shared/widgets/equipment_utilization_card.dart';
import '../../../shared/widgets/low_stock_alert_card.dart';
import '../../../shared/widgets/recent_activity_card.dart';
import '../../dashboard/data/models/dashboard_analytics.dart';
import '../../dashboard/data/repositories/dashboard_repository.dart';
import '../hrm/data/repositories/employee_repository.dart';
import '../hrm/presentation/employee_list_screen.dart';
import '../projects/data/repositories/wbs_task_repository.dart';
import '../projects/presentation/wbs/wbs_task_list_screen.dart';
import '../projects/presentation/project_list_screen.dart';
import '../projects/data/repositories/project_repository.dart';
import '../inventory/presentation/stock_balance_list_screen.dart';
import '../inventory/data/repositories/stock_balance_repository.dart';






class AdminDashboard extends StatefulWidget {
  const AdminDashboard({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.roles,
    required this.syncManager,
  });

  final String userName;
  final String userEmail;
  final List<String> roles;
  final SyncManager syncManager;


  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final DashboardController _controller = DashboardController();

  late final DashboardRepository _analyticsRepository;



  DashboardAnalytics? _analytics;
  bool _loadingAnalytics = true;

  @override
  void initState() {
    super.initState();

    _controller.load();
    widget.syncManager.startConnectivityMonitoring();

    _analyticsRepository = DashboardRepository();

    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final data = await _analyticsRepository.getAnalytics();

      if (!mounted) return;

      setState(() {
        _analytics = data;
        _loadingAnalytics = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingAnalytics = false;
      });
    }
  }

  @override
  void dispose() {
    widget.syncManager.stopConnectivityMonitoring();
    _controller.dispose();
    super.dispose();
  }

  DashboardStats get stats =>
      _controller.stats ??
          const DashboardStats(
            activeProjects: 0,
            totalSites: 0,
            totalEmployees: 0,
            todayAttendance: 0,
            openWorkPermits: 0,
            lowStockItems: 0,
            backupCount: 0,
            lastBackupUtc: null,
          );

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppBreakpoints.isDesktop(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${widget.userName}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  if (_loadingAnalytics)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    widget.userEmail,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),

                  _buildStatisticsCard(context),

                  const SizedBox(height: 16),

                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: ProjectProgressChart(
                            values: _analytics?.projectProgress ??
                                [0, 0, 0, 0, 0, 0],
                            labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: EquipmentUtilizationCard(
                            utilization: _analytics == null
                                ? 0
                                : (_analytics!.equipmentInUse /
                                _analytics!.totalEquipment) * 100,
                            available: _analytics?.equipmentAvailable ?? 0,
                            inUse: _analytics?.equipmentInUse ?? 0,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    ProjectProgressChart(
                      values: [22, 34, 46, 61, 73, 88],
                      labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
                    ),
                    const SizedBox(height: 16),
                    EquipmentUtilizationCard(
                      utilization: _analytics == null
                          ? 0
                          : (_analytics!.equipmentInUse /
                          _analytics!.totalEquipment) *
                          100,
                      available: _analytics?.equipmentAvailable ?? 0,
                      inUse: _analytics?.equipmentInUse ?? 0,
                    )
                  ],

                  const SizedBox(height: 16),

                  LowStockAlertCard(
                    lowStockCount: stats.lowStockItems,
                    criticalItems: const [
                      'Cement OPC 42.5',
                      '16mm Rebar',
                      'Binding Wire',
                    ],
                  ),

                  const SizedBox(height: 16),

                  RecentActivityCard(
                    activities: const [
                      ActivityItem(
                        title: 'Equipment Assigned',
                        subtitle: 'Excavator 320 → Addis HQ',
                        time: '10 min',
                        icon: Icons.construction,
                        color: Colors.orange,
                      ),
                      ActivityItem(
                        title: 'Site Inspection Passed',
                        subtitle: 'Block A Foundation',
                        time: '35 min',
                        icon: Icons.verified,
                        color: Colors.green,
                      ),
                      ActivityItem(
                        title: 'Material Received',
                        subtitle: '120 Bags of Cement',
                        time: '1 hr',
                        icon: Icons.inventory,
                        color: Colors.blue,
                      ),
                      ActivityItem(
                        title: 'Employee Checked In',
                        subtitle: 'Ahmed Mohammed',
                        time: '2 hr',
                        icon: Icons.person,
                        color: Colors.indigo,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  _buildAccessCard(context),

                  const SizedBox(height: 16),

                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildSyncCard(context)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildBackupCard(context)),
                      ],
                    )
                  else ...[
                    _buildSyncCard(context),
                    const SizedBox(height: 16),
                    _buildBackupCard(context),
                  ],

                  const SizedBox(height: 16),
                  _buildAuditCard(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatisticsCard(BuildContext context) {
    final isDesktop = AppBreakpoints.isDesktop(context);
    final isTablet = AppBreakpoints.isTablet(context);

    final kpiColumns = isDesktop
        ? 4
        : isTablet
        ? 3
        : 2;

    final items = [
      DashboardKpiCard(
        title: 'Projects',
        value: stats.activeProjects.toString(),
        icon: Icons.engineering,
        color: Colors.blue,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProjectListScreen(
              repository: ProjectRepository(),
            ),
          ),
        ),
      ),
      DashboardKpiCard(
        title: 'WBS Tasks',
        value: 'Board',
        icon: Icons.account_tree,
        color: Colors.teal,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WbsTaskListScreen(
              repository: WbsTaskRepository(ApiClient()),
            ),
          ),
        ),
      ),
      DashboardKpiCard(
        title: 'Sites',
        value: stats.totalSites.toString(),
        icon: Icons.location_city,
        color: Colors.teal,
      ),
      DashboardKpiCard(
        title: 'Employees',
        value: stats.totalEmployees.toString(),
        icon: Icons.groups,
        color: Colors.green,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EmployeeListScreen(
              repository: EmployeeRepository(),
            ),
          ),
        ),
      ),
      DashboardKpiCard(
        title: 'Attendance',
        value: stats.todayAttendance.toString(),
        icon: Icons.fact_check,
        color: Colors.orange,
      ),
      DashboardKpiCard(
        title: 'Work Permits',
        value: stats.openWorkPermits.toString(),
        icon: Icons.assignment,
        color: Colors.indigo,
      ),
      DashboardKpiCard(
        title: 'Low Stock',
        value: stats.lowStockItems.toString(),
        icon: Icons.inventory_2,
        color: Colors.red,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StockBalanceListScreen(
              repository: StockBalanceRepository(),
            ),
          ),
        ),
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Project Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: kpiColumns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isDesktop
                    ? 1.35
                    : isTablet
                    ? 0.95
                    : 0.82,
              ),
              itemBuilder: (context, index) => items[index],
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildAccessCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Authorized Access',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'Your current roles determine which administration areas are available to you.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.roles
                  .map(
                    (role) => Chip(
                  avatar: const Icon(
                    Icons.verified_user_outlined,
                    size: 18,
                  ),
                  label: Text(role),
                ),
              )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncCard(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.syncManager,
      builder: (context, _) {
        final status = widget.syncManager.status;

        final lastSync = status.lastSuccessfulSyncUtc == null
            ? 'Not synchronized yet'
            : status.lastSuccessfulSyncUtc!
            .toLocal()
            .toString()
            .split('.')[0];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.sync_outlined),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        'Synchronization',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),

                    const SizedBox(width: 8),

                    FilledButton.icon(
                      onPressed: status.isSyncing
                          ? null
                          : () => widget.syncManager.synchronize(),
                      icon: const Icon(Icons.sync, size: 18),
                      label: const Text('Sync'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                _statusRow(
                  context,
                  'State',
                  '${status.state.name[0].toUpperCase()}${status.state.name.substring(1)}',
                ),
                _statusRow(
                  context,
                  'Pending operations',
                  status.pendingCount.toString(),
                ),
                _statusRow(
                  context,
                  'Failed operations',
                  status.failedCount.toString(),
                ),
                _statusRow(
                  context,
                  'Last successful sync',
                  lastSync,
                ),

                if (status.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    status.errorMessage!,
                    style: TextStyle(
                      color: status.state == SyncState.offline
                          ? Colors.orange
                          : Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusRow(
      BuildContext context,
      String label,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildBackupCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.backup, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Database Backup',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _metric(
                    'Backups',
                    stats.backupCount.toString(),
                  ),
                ),
                Expanded(
                  child: _metric(
                    'Latest',
                    stats.lastBackupUtc == null
                        ? 'Never'
                        : '${stats.lastBackupUtc!.day}/${stats.lastBackupUtc!.month}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BackupScreen(
                        repository: BackupRepository(ApiClient()),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.storage),
                label: const Text('Backup Center'),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildAuditCard(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(
          Icons.history,
          color: Colors.indigo,
        ),
        title: const Text('Audit Activity'),
        subtitle: const Text(
          'Review employee, payroll and system activity',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AuditLogScreen(
                repository: AuditRepository(ApiClient()),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _metric(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }


}