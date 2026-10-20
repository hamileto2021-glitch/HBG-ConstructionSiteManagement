import 'package:flutter/material.dart';
import 'package:csm_app/core/network/api_client.dart';

import '../data/non_conformance_report.dart';
import '../data/non_conformance_report_repository.dart';
import 'edit_non_conformance_report_screen.dart';



class NonConformanceReportDetailsScreen extends StatefulWidget {
  const NonConformanceReportDetailsScreen({
    super.key,
    required this.reportId,
  });

  final String reportId;

  @override
  State<NonConformanceReportDetailsScreen> createState() =>
      _NonConformanceReportDetailsScreenState();
}

class _NonConformanceReportDetailsScreenState
    extends State<NonConformanceReportDetailsScreen> {
  late final NonConformanceReportRepository _repository;

  NonConformanceReport? _report;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = NonConformanceReportRepository(ApiClient());
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _repository.getById(widget.reportId);

      if (!mounted) return;

      setState(() {
        _report = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Color _severityColor(String value) {
    switch (value) {
      case 'Critical':
        return Colors.red;
      case 'Major':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  Color _statusColor(String value) {
    switch (value) {
      case 'Closed':
        return Colors.green;
      case 'InProgress':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year}';

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('NCR Details')),
        body: Center(child: Text(_error!)),
      );
    }

    final r = _report!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NCR Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => EditNonConformanceReportScreen(
                    report: r,
                  ),
                ),
              );

              if (updated == true && mounted) {
                await _load();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            r.constructionSiteName,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            r.ncrNumber,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Chip(
                label: Text(r.status),
                backgroundColor:
                _statusColor(r.status).withValues(alpha: 0.15),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(r.severity),
                backgroundColor:
                _severityColor(r.severity).withValues(alpha: 0.15),
              ),
            ],
          ),

          const Divider(height: 28),

          _tile('Title', r.title),
          _tile('Location', r.location),
          _tile('Reported Date', _date(r.reportedDate)),
          if (r.dueDate != null)
            _tile('Due Date', _date(r.dueDate!)),
          _tile('Raised By', r.raisedByName),

          const SizedBox(height: 20),

          Text(
            'Description',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(r.description),

          if (r.rootCause != null) ...[
            const SizedBox(height: 20),
            Text(
              'Root Cause',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(r.rootCause!),
          ],

          if (r.correctiveAction != null) ...[
            const SizedBox(height: 20),
            Text(
              'Corrective Action',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(r.correctiveAction!),
          ],

          if (r.preventiveAction != null) ...[
            const SizedBox(height: 20),
            Text(
              'Preventive Action',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(r.preventiveAction!),
          ],
        ],
      ),
    );
  }

  Widget _tile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 2),
          Text(value),
        ],
      ),
    );
  }
}