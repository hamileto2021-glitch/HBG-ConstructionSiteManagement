import 'package:flutter/material.dart';

import '../../compliance/safety/presentation/safety_incident_list_screen.dart';
import '../../reports/data/models/executive_dashboard.dart';
import '../../reports/data/repositories/reports_repository.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../projects/data/repositories/project_repository.dart';
import '../../projects/presentation/project_list_screen.dart';
import '../../projects/presentation/diary/daily_site_diary_list_screen.dart';
import '../../reports/presentation/reports_dashboard_screen.dart';
import '../../projects/data/models/project.dart';
import '../../compliance/safety/data/safety_incident_repository.dart';
import '../../../../core/network/api_client.dart';
import '../../procurement/presentation/procurement_dashboard_screen.dart';

class ExecutiveDashboardScreen extends StatefulWidget {
  const ExecutiveDashboardScreen({super.key});

  @override
  State<ExecutiveDashboardScreen> createState() =>
      _ExecutiveDashboardScreenState();
}

class _ExecutiveDashboardScreenState
    extends State<ExecutiveDashboardScreen> {
  final _repository = ReportsRepository();

  ExecutiveDashboard? _dashboard;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final data = await _repository.getExecutiveDashboard();

      if (!mounted) return;

      setState(() {
        _dashboard = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String money(double value) =>
      CurrencyFormatter.etb(value);

  Widget _buildBudgetChart(ExecutiveDashboard d) {
    final budget = d.totalBudget;
    final expenses = d.totalExpenses;
    final remaining =
    (budget - expenses).clamp(0.0, budget).toDouble();

    final expenseRatio = budget == 0 ? 0.0 : expenses / budget;
    final remainingRatio = budget == 0 ? 0.0 : remaining / budget;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Budget Utilization',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${d.budgetUtilization.toStringAsFixed(2)}% of budget used',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _BudgetBar(
                    label: 'Budget',
                    value: money(budget),
                    ratio: 1.0,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: _BudgetBar(
                    label: 'Expenses',
                    value: money(expenses),
                    ratio: expenseRatio,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: _BudgetBar(
                    label: 'Remaining',
                    value: money(remaining),
                    ratio: remainingRatio,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectStatusChart(ExecutiveDashboard d) {
    final values = [
      d.activeProjects,
      d.completedProjects,
      d.openDelays,
    ];

    final maxValue = values.reduce((a, b) => a > b ? a : b).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Project Status Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${d.activeProjects + d.completedProjects} total projects',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 155,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatusBar(
                    label: 'Active',
                    value: d.activeProjects,
                    maxValue: maxValue,
                    color: Colors.indigo,
                  ),
                  _StatusBar(
                    label: 'Completed',
                    value: d.completedProjects,
                    maxValue: maxValue,
                    color: Colors.green,
                  ),
                  _StatusBar(
                    label: 'Delayed',
                    value: d.openDelays,
                    maxValue: maxValue,
                    color: Colors.orange,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: const [
                _LegendItem('Active', Colors.indigo),
                _LegendItem('Completed', Colors.green),
                _LegendItem('Delayed', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyExpenseChart(ExecutiveDashboard d) {
    final now = DateTime.now();

    final months = List.generate(6, (i) {
      final date = DateTime(now.year, now.month - (5 - i), 1);
      return _monthName(date.month);
    });

    final values = [
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      d.totalExpenses,
    ];

    final maxValue = values.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Expense Trend',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Current month: ${money(d.totalExpenses)}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (i) {
                  return _ExpenseBar(
                    month: months[i],
                    value: values[i],
                    maxValue: maxValue,
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetySummaryCard(ExecutiveDashboard d) {
    final hasIncidents = d.openSafetyIncidents > 0;

    return Card(
      color: hasIncidents
          ? Colors.orange.shade50
          : Colors.green.shade50,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SafetyIncidentListScreen(
                repository: SafetyIncidentRepository(ApiClient()),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.health_and_safety,
                    color: hasIncidents
                        ? Colors.orange.shade800
                        : Colors.green.shade700,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Safety Incident Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasIncidents ? Colors.orange : Colors.green,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      d.openSafetyIncidents.toString(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Open Safety Incidents',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasIncidents
                              ? 'Tap to review active incidents'
                              : 'Tap to view incident history',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Risk Level'),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: hasIncidents
                          ? Colors.orange.shade100
                          : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      hasIncidents ? 'Attention' : 'Normal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: hasIncidents
                            ? Colors.orange.shade900
                            : Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryHealthCard(ExecutiveDashboard d) {
    final hasLowStock = d.lowStockItems > 0;

    return Card(
      color: hasLowStock
          ? Colors.amber.shade50
          : Colors.green.shade50,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ProcurementDashboardScreen(),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.inventory_2,
                    color: hasLowStock
                        ? Colors.amber.shade800
                        : Colors.green.shade700,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Inventory Health',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasLowStock
                          ? Colors.amber
                          : Colors.green,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      d.lowStockItems.toString(),
                      style: const TextStyle(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(width: 18),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasLowStock
                              ? 'Low Stock Items'
                              : 'Inventory Healthy',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasLowStock
                              ? 'Tap to review inventory requiring replenishment.'
                              : 'All monitored materials are above minimum stock.',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              const Divider(),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Status'),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: hasLowStock
                          ? Colors.amber.shade100
                          : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      hasLowStock ? 'Attention' : 'Healthy',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: hasLowStock
                            ? Colors.amber.shade900
                            : Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];

    return names[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_dashboard == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Executive Dashboard')),
        body: const Center(
          child: Text('Unable to load dashboard'),
        ),
      );
    }

    final d = _dashboard!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Executive Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Hamilton Business Group',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Generated: ${d.generatedAtUtc.toLocal().toString().substring(0, 16)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.8,
              children: [
                _KpiCard(
                  'Active Projects',
                  d.activeProjects.toString(),
                  Icons.business,
                  Colors.indigo,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProjectListScreen(
                          repository: ProjectRepository(),
                        ),
                      ),
                    );
                  },
                ),

                _KpiCard(
                  'Completed',
                  d.completedProjects.toString(),
                  Icons.check_circle,
                  Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProjectListScreen(
                          repository: ProjectRepository(),
                          initialStatus: ProjectStatus.completed,
                        ),
                      ),
                    );
                  },
                ),
                _KpiCard(
                  'Employees',
                  d.totalEmployees.toString(),
                  Icons.people,
                  Colors.blue,
                ),
                _KpiCard(
                  'Open Delays',
                  d.openDelays.toString(),
                  Icons.warning_amber,
                  Colors.orange,
                ),
              ],
            ),

            const SizedBox(height: 24),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Financial Overview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SummaryRow('Total Budget', money(d.totalBudget)),
                    _SummaryRow('Total Expenses', money(d.totalExpenses)),
                    const Divider(),
                    _SummaryRow(
                      'Budget Utilization',
                      '${d.budgetUtilization.toStringAsFixed(2)}%',
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: d.budgetUtilization / 100,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            _buildBudgetChart(d),

            const SizedBox(height: 24),

            _buildProjectStatusChart(d),

            const SizedBox(height: 24),

            _buildMonthlyExpenseChart(d),

            const SizedBox(height: 24),

            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: [
                _ActionCard(
                  title: 'Projects',
                  icon: Icons.business,
                  color: Colors.indigo,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProjectListScreen(
                          repository: ProjectRepository(),
                        ),
                      ),
                    );
                  },
                ),

                _ActionCard(
                  title: 'Reports',
                  icon: Icons.analytics,
                  color: Colors.deepPurple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReportsDashboardScreen(
                          roles: const {'Administrator'},
                        ),
                      ),
                    );
                  },
                ),

                _ActionCard(
                  title: 'Daily Diary',
                  icon: Icons.menu_book,
                  color: Colors.teal,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DailySiteDiaryListScreen(
                          projectId: '',
                          projectName: 'All Projects',
                          constructionSiteId: '',
                        )
                      ),
                    );
                  },
                ),
                _ActionCard(
                  title: 'Refresh',
                  icon: Icons.refresh,
                  color: Colors.orange,
                  onTap: _load,
                ),
              ],
            ),

            const SizedBox(height: 24),

            _buildSafetySummaryCard(d),

            const SizedBox(height: 24),

            _buildInventoryHealthCard(d),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard(
      this.title,
      this.value,
      this.icon,
      this.color, {
        this.onTap,
      });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withValues(alpha: .12),
                child: Icon(icon, color: color, size: 18),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: .12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.title, this.value);

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetBar extends StatelessWidget {
  const _BudgetBar({
    required this.label,
    required this.value,
    required this.ratio,
    required this.color,
  });

  final String label;
  final String value;
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final height = (ratio * 140).clamp(8.0, 140.0);

    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 36,
          height: 140,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.bottomCenter,
          child: Container(
            width: 36,
            height: height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  final String label;
  final int value;
  final double maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue == 0 ? 0.0 : value / maxValue;
    final height = (ratio * 105).clamp(12.0, 105.0);

    return SizedBox(
      width: 58,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            value.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 38,
            height: 105,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 38,
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ExpenseBar extends StatelessWidget {
  const _ExpenseBar({
    required this.month,
    required this.value,
    required this.maxValue,
  });

  final String month;
  final double value;
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue == 0 ? 0.0 : value / maxValue;
    final height = (ratio * 130).clamp(8.0, 130.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          value == 0 ? '-' : '${(value / 1000).round()}K',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 24,
          height: 130,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.bottomCenter,
          child: Container(
            width: 24,
            height: height,
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          month,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}