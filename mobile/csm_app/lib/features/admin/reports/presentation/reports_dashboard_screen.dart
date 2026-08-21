import 'package:flutter/material.dart';

import '../data/models/executive_dashboard.dart';
import '../data/models/financial_summary.dart';
import '../data/repositories/reports_repository.dart';

class ReportsDashboardScreen extends StatefulWidget {
  const ReportsDashboardScreen({super.key});

  @override
  State<ReportsDashboardScreen> createState() =>
      _ReportsDashboardScreenState();
}

class _ReportsDashboardScreenState
    extends State<ReportsDashboardScreen> {
  final _repository = ReportsRepository();

  ExecutiveDashboard? _executive;
  FinancialSummary? _financial;

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
      final financial =
      await _repository.getFinancialSummary();

      _executive = executive;
      _financial = financial;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  String money(double value) =>
      value.toStringAsFixed(2);

  Widget kpi(
      String title,
      String value,
      IconData icon,
      Color color,
      ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget statusCard(
      String title,
      Map<String, int> data,
      ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),
            const Divider(),
            ...data.entries.map(
                  (e) => Padding(
                padding:
                const EdgeInsets.symmetric(
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(e.key),
                    ),
                    Text(
                      e.value.toString(),
                      style: const TextStyle(
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
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

    if (_executive == null || _financial == null) {
      return const Scaffold(
        body: Center(
          child: Text('Unable to load reports'),
        ),
      );
    }

    final e = _executive!;
    final f = _financial!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Executive Dashboard',
              style:
              Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),

            kpi(
              'Construction Sites',
              e.totalSites.toString(),
              Icons.location_city,
              Colors.blue,
            ),
            kpi(
              'Active Sites',
              e.activeSites.toString(),
              Icons.check_circle,
              Colors.green,
            ),
            kpi(
              'Projects',
              e.totalProjects.toString(),
              Icons.assignment,
              Colors.deepPurple,
            ),
            kpi(
              'Contract Value',
              money(e.totalContractValue),
              Icons.account_balance,
              Colors.indigo,
            ),

            const SizedBox(height: 16),

            Text(
              'Financial Summary',
              style:
              Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),

            kpi(
              'Total Budget',
              money(f.totalBudget),
              Icons.account_balance_wallet,
              Colors.green,
            ),
            kpi(
              'Expenses',
              money(f.totalExpenses),
              Icons.money_off,
              Colors.red,
            ),
            kpi(
              'Invoices',
              money(f.totalInvoices),
              Icons.receipt_long,
              Colors.orange,
            ),
            kpi(
              'Payments',
              money(f.totalCompletedPayments),
              Icons.payments,
              Colors.teal,
            ),
            kpi(
              'Receivables',
              money(f.outstandingReceivables),
              Icons.trending_up,
              Colors.blue,
            ),
            kpi(
              'Payables',
              money(f.outstandingPayables),
              Icons.trending_down,
              Colors.deepOrange,
            ),

            const SizedBox(height: 20),

            statusCard(
              'Sites by Status',
              e.sitesByStatus,
            ),

            const SizedBox(height: 12),

            statusCard(
              'Projects by Status',
              e.projectsByStatus,
            ),
          ],
        ),
      ),
    );
  }
}