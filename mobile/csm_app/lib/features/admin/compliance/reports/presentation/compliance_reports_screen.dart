import 'package:flutter/material.dart';

import '../data/models/compliance_summary_report.dart';
import '../data/repositories/compliance_report_repository.dart';

class ComplianceReportsScreen extends StatefulWidget {
  const ComplianceReportsScreen({super.key});

  @override
  State<ComplianceReportsScreen> createState() =>
      _ComplianceReportsScreenState();
}

class _ComplianceReportsScreenState
    extends State<ComplianceReportsScreen> {

  final _repo = ComplianceReportRepository();

  ComplianceSummaryReport? report;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final r = await _repo.getSummary();

    if (!mounted) return;

    setState(() {
      report = r;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Audit Reports')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final r = report!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: load,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            _section(
              'Inspection Report',
              Icons.fact_check,
              [
                _row('Total Inspections', r.totalInspections),
                _row('Compliant Items', r.compliantItems),
                _row('Non-Compliant', r.nonCompliantItems),
                _row('Open Corrective', r.openCorrectiveActions),
              ],
            ),

            const SizedBox(height: 16),

            _section(
              'Permit Report',
              Icons.assignment,
              [
                _row('Active Permits', r.activePermits),
                _row('Expired Permits', r.expiredPermits),
              ],
            ),

            const SizedBox(height: 16),

            _section(
              'Safety Report',
              Icons.health_and_safety,
              [
                _row('Incidents', r.safetyIncidents),
                _row('Observations', r.safetyObservations),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String title, int value) {
    return ListTile(
      dense: true,
      title: Text(title),
      trailing: Text(
        value.toString(),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _section(
      String title,
      IconData icon,
      List<Widget> children,
      ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            ListTile(
              leading: Icon(icon),
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}