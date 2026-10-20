import 'package:flutter/material.dart';

import '../data/inspection.dart';
import '../data/inspection_repository.dart';
import 'create_inspection_screen.dart';
import 'inspection_details_screen.dart';

class InspectionListScreen extends StatefulWidget {
  const InspectionListScreen({
    super.key,
    required this.repository,
  });

  final InspectionRepository repository;

  @override
  State<InspectionListScreen> createState() =>
      _InspectionListScreenState();
}

class _InspectionListScreenState
    extends State<InspectionListScreen> {
  List<Inspection> _inspections = [];
  bool _loading = true;
  String? _error;

  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await widget.repository.getAll();

      if (!mounted) return;

      setState(() {
        _inspections = data;
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
      case 'Cancelled':
        return Colors.black54;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedStatus == 'All'
        ? _inspections
        : _inspections
        .where((e) => e.status == _selectedStatus)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspections'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Filter Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'All',
                  child: Text('All'),
                ),
                DropdownMenuItem(
                  value: 'Scheduled',
                  child: Text('Scheduled'),
                ),
                DropdownMenuItem(
                  value: 'In Progress',
                  child: Text('In Progress'),
                ),
                DropdownMenuItem(
                  value: 'Passed',
                  child: Text('Passed'),
                ),
                DropdownMenuItem(
                  value: 'Failed',
                  child: Text('Failed'),
                ),
                DropdownMenuItem(
                  value: 'Closed',
                  child: Text('Closed'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedStatus = value;
                });
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                itemCount: filtered.length,
                separatorBuilder: (_, _) =>
                const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final inspection = filtered[index];

                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: _statusColor(inspection.status),
                        child: const Icon(
                          Icons.fact_check,
                          color: Colors.white,
                        ),
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inspection.constructionSiteName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            inspection.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              inspection.inspectionNumber,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(inspection.inspectionType),
                            const SizedBox(height: 2),
                            Text(
                              'Scheduled: ${inspection.scheduledAtUtc.day.toString().padLeft(2, '0')}/${inspection.scheduledAtUtc.month.toString().padLeft(2, '0')}/${inspection.scheduledAtUtc.year}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            inspection.status,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _statusColor(inspection.status),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InspectionDetailsScreen(
                              inspectionId: inspection.id,
                              repository: widget.repository,
                            ),
                          ),
                        );
                        _load();
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final created =
          await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CreateInspectionScreen(
                    repository: widget.repository,
                  ),
            ),
          );

          if (created == true) {
            _load();
          }
        },
      ),
    );
  }
}