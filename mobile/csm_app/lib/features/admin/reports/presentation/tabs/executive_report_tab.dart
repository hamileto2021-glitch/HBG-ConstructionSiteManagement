import 'package:flutter/material.dart';

import '../../../../../core/utils/currency_formatter.dart';
import '../../data/models/executive_dashboard.dart';

class ExecutiveReportTab extends StatelessWidget {
  const ExecutiveReportTab({
    super.key,
    required this.executive,
  });

  final ExecutiveDashboard executive;

  String money(double value) => CurrencyFormatter.etb(value);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Company Overview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              _KpiCard(
                title: 'Active Projects',
                value: executive.activeProjects.toString(),
                icon: Icons.business,
                color: Colors.indigo,
              ),
              _KpiCard(
                title: 'Completed',
                value: executive.completedProjects.toString(),
                icon: Icons.check_circle,
                color: Colors.green,
              ),
              _KpiCard(
                title: 'Employees',
                value: executive.totalEmployees.toString(),
                icon: Icons.people,
                color: Colors.blue,
              ),
              _KpiCard(
                title: 'Open Delays',
                value: executive.openDelays.toString(),
                icon: Icons.warning_amber,
                color: Colors.orange,
              ),
              _KpiCard(
                title: 'Low Stock',
                value: executive.lowStockItems.toString(),
                icon: Icons.inventory_2,
                color: Colors.brown,
              ),
              _KpiCard(
                title: 'Safety',
                value: executive.openSafetyIncidents.toString(),
                icon: Icons.health_and_safety,
                color: Colors.red,
              ),
            ],
          ),

          const SizedBox(height: 24),

          const Text(
            'Financial Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _SummaryRow(
                    'Total Budget',
                    money(executive.totalBudget),
                  ),
                  _SummaryRow(
                    'Total Expenses',
                    money(executive.totalExpenses),
                  ),
                  const Divider(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Budget Utilization'),
                      Text(
                        '${executive.budgetUtilization.toStringAsFixed(2)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: executive.budgetUtilization / 100,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Operations Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _SummaryRow(
                    'Open Project Delays',
                    executive.openDelays.toString(),
                  ),
                  _SummaryRow(
                    'Low Stock Items',
                    executive.lowStockItems.toString(),
                  ),
                  _SummaryRow(
                    'Open Safety Incidents',
                    executive.openSafetyIncidents.toString(),
                  ),
                  _SummaryRow(
                    'Generated',
                    executive.generatedAtUtc
                        .toLocal()
                        .toString()
                        .substring(0, 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: .12),
              child: Icon(icon, color: color),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}