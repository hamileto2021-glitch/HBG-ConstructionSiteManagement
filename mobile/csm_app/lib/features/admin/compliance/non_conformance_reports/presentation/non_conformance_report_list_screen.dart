import 'package:flutter/material.dart';

import '../../../../../core/network/api_client.dart';
import '../data/non_conformance_report.dart';
import '../data/non_conformance_report_repository.dart';
import 'create_non_conformance_report_screen.dart';
import 'non_conformance_report_details_screen.dart';


class NonConformanceReportListScreen extends StatefulWidget {
  const NonConformanceReportListScreen({super.key});

  @override
  State<NonConformanceReportListScreen> createState() =>
      _NonConformanceReportListScreenState();
}

class _NonConformanceReportListScreenState
    extends State<NonConformanceReportListScreen> {
  late final NonConformanceReportRepository _repository;

  List<NonConformanceReport> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = NonConformanceReportRepository(ApiClient());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _repository.getAll();

      if (!mounted) return;

      setState(() => _items = data);
    } catch (e) {
      if (!mounted) return;

      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Non-Conformance Reports'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.deepPurple,
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateNonConformanceReportScreen(),
            ),
          );

          if (created == true && mounted) {
            await _load();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!),
        ),
      )
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: _items.length,
          separatorBuilder: (_, _) =>
          const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = _items[index];

            return Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NonConformanceReportDetailsScreen(
                        reportId: item.id,
                      ),
                    ),
                  );

                  if (mounted) {
                    await _load();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.constructionSiteName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _severityColor(item.severity)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              item.severity,
                              style: TextStyle(
                                color: _severityColor(item.severity),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.ncrNumber,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 15,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(_date(item.reportedDate)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(item.status)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              item.status,
                              style: TextStyle(
                                color: _statusColor(item.status),
                                fontWeight: FontWeight.w600,
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
          },
        ),
      ),
    );
  }
}