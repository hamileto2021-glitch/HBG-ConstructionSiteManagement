import 'package:flutter/material.dart';

import '../data/models/compliance_dashboard.dart';
import '../data/repositories/compliance_dashboard_repository.dart';

class ComplianceDashboardScreen extends StatefulWidget {
  const ComplianceDashboardScreen({super.key});

  @override
  State<ComplianceDashboardScreen> createState() =>
      _ComplianceDashboardScreenState();
}

class _ComplianceDashboardScreenState
    extends State<ComplianceDashboardScreen> {
  final ComplianceDashboardRepository _repository =
  ComplianceDashboardRepository();

  ComplianceDashboard? _dashboard;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _repository.getDashboard();

      if (!mounted) return;

      setState(() {
        _dashboard = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load compliance dashboard'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Compliance Dashboard'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final d = _dashboard;

    if (d == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Compliance Dashboard'),
        ),
        body: const Center(
          child: Text('No dashboard data'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compliance Dashboard'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: GridView.count(
          padding: const EdgeInsets.all(16),
          crossAxisCount: 2,
          childAspectRatio: 1.05,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _kpiCard(
              'Inspections',
              d.totalInspections,
              Colors.blue,
              Icons.fact_check,
            ),
            _kpiCard(
              'Corrective',
              d.openCorrectiveActions,
              Colors.orange,
              Icons.warning_amber,
            ),
            _kpiCard(
              'Permits',
              d.activePermits,
              Colors.green,
              Icons.assignment_turned_in,
            ),
            _kpiCard(
              'Expiring',
              d.expiringPermits,
              Colors.purple,
              Icons.schedule,
            ),
            _kpiCard(
              'Open NCR',
              d.openNcrs,
              Colors.red,
              Icons.report_problem,
            ),
            _kpiCard(
              'Incidents',
              d.safetyIncidents,
              Colors.deepOrange,
              Icons.health_and_safety,
            ),
            _kpiCard(
              'Observations',
              d.safetyObservations,
              Colors.teal,
              Icons.visibility,
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard(
      String title,
      int value,
      Color color,
      IconData icon,
      ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}