import 'package:flutter/material.dart';

import '../data/inspection.dart';
import '../data/inspection_repository.dart';

import 'edit_inspection_screen.dart';

class InspectionDetailsScreen extends StatefulWidget {
  const InspectionDetailsScreen({
    super.key,
    required this.inspectionId,
    required this.repository,
  });

  final String inspectionId;
  final InspectionRepository repository;

  @override
  State<InspectionDetailsScreen> createState() =>
      _InspectionDetailsScreenState();
}

class _InspectionDetailsScreenState
    extends State<InspectionDetailsScreen> {
  Inspection? _inspection;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await widget.repository.getById(widget.inspectionId);

      if (!mounted) return;

      setState(() {
        _inspection = data;
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

  Color _statusColor(String status) {
    switch (status) {
      case 'Scheduled':
        return Colors.orange;
      case 'In Progress':
        return Colors.blue;
      case 'Passed':
        return Colors.green;
      case 'Passed With Observations':
        return Colors.teal;
      case 'Failed':
        return Colors.red;
      case 'Corrective Action Required':
        return Colors.deepOrange;
      case 'Closed':
        return Colors.grey;
      default:
        return Colors.black54;
    }
  }

  String _format(DateTime? value) {
    if (value == null) return '-';
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _inspection == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Inspection Details')),
        body: Center(child: Text(_error ?? 'Inspection not found')),
      );
    }

    final inspection = _inspection!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspection Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditInspectionScreen(
                    repository: widget.repository,
                    inspection: inspection,
                  ),
                ),
              );

              _load();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inspection.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      inspection.inspectionNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.fact_check,
                          color: _statusColor(inspection.status),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          inspection.status,
                          style: TextStyle(
                            color: _statusColor(inspection.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _infoRow(
                      'Inspection Type',
                      inspection.inspectionType,
                    ),
                    const Divider(),
                    _infoRow(
                      'Scheduled',
                      _format(inspection.scheduledAtUtc),
                    ),
                    const Divider(),
                    _infoRow(
                      'Started',
                      _format(inspection.startedAtUtc),
                    ),
                    const Divider(),
                    _infoRow(
                      'Completed',
                      _format(inspection.completedAtUtc),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      inspection.summary?.isNotEmpty == true
                          ? inspection.summary!
                          : 'No summary available',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Checklist',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (inspection.checklistItems.isEmpty)
                      const Text('No checklist items')
                    else
                      ...inspection.checklistItems.map(
                            (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            item.isCompliant == true
                                ? Icons.check_circle
                                : item.isCompliant == false
                                ? Icons.cancel
                                : Icons.radio_button_unchecked,
                            color: item.isCompliant == true
                                ? Colors.green
                                : item.isCompliant == false
                                ? Colors.red
                                : Colors.grey,
                          ),
                          title: Text(item.requirement),
                          subtitle: item.observation == null
                              ? null
                              : Text(item.observation!),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Corrective Action',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      inspection.correctiveActionRequired?.isNotEmpty == true
                          ? inspection.correctiveActionRequired!
                          : 'None',
                    ),
                    if (inspection.correctiveActionDueDate != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Due: ${_format(inspection.correctiveActionDueDate)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sign Off',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      inspection.signedOffAtUtc == null
                          ? 'Not signed'
                          : 'Signed on ${_format(inspection.signedOffAtUtc)}',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}