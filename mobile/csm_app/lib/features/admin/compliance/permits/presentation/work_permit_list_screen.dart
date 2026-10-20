import 'package:flutter/material.dart';

import '../data/work_permit.dart';
import '../data/work_permit_repository.dart';
import 'create_work_permit_screen.dart';
import 'work_permit_details_screen.dart';

class WorkPermitListScreen extends StatefulWidget {
  const WorkPermitListScreen({
    super.key,
    required this.repository,
  });

  final WorkPermitRepository repository;

  @override
  State<WorkPermitListScreen> createState() =>
      _WorkPermitListScreenState();
}

class _WorkPermitListScreenState
    extends State<WorkPermitListScreen> {
  List<WorkPermit> _permits = [];
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
        _permits = data;
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

  Color _statusColor(WorkPermit permit) {
    if (permit.isExpired) return Colors.red;

    switch (permit.status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'issued':
        return Colors.blue;
      case 'closed':
        return Colors.grey;
      case 'draft':
        return Colors.orange;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedStatus == 'All'
        ? _permits
        : _permits
        .where((p) => p.status == _selectedStatus)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Permits'),
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _error != null
          ? Center(child: Text(_error!))
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                12, 12, 12, 8),
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
                  value: 'Draft',
                  child: Text('Draft'),
                ),
                DropdownMenuItem(
                  value: 'Issued',
                  child: Text('Issued'),
                ),
                DropdownMenuItem(
                  value: 'Active',
                  child: Text('Active'),
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
                padding: const EdgeInsets.all(12),
                itemCount: filtered.length,
                separatorBuilder: (_, _) =>
                const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final permit = filtered[index];

                  final displayTitle =
                  permit.constructionSiteName
                      .isNotEmpty
                      ? permit
                      .constructionSiteName
                      : permit.name;

                  return Card(
                    child: ListTile(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                WorkPermitDetailsScreen(
                                  permitId: permit.id,
                                  repository:
                                  widget.repository,
                                ),
                          ),
                        );

                        _load();
                      },
                      contentPadding:
                      const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor:
                        _statusColor(permit),
                        child: const Icon(
                          Icons.assignment,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      title: Text(
                        displayTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                      subtitle: Padding(
                        padding:
                        const EdgeInsets.only(
                            top: 6),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                          children: [
                            Text(
                              permit.permitNumber,
                              style:
                              const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(
                                height: 4),

                            if (permit.isExpired)
                              const Text(
                                'Expired',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight:
                                  FontWeight.bold,
                                  fontSize: 12,
                                ),
                              )
                            else if (permit
                                .isExpiringSoon)
                              Text(
                                'Expires in ${permit.daysRemaining} days',
                                style:
                                const TextStyle(
                                  color: Colors
                                      .deepOrange,
                                  fontWeight:
                                  FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                        children: [
                          Text(
                            permit.status,
                            style: TextStyle(
                              color: _statusColor(
                                  permit),
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                              height: 8),
                          const Icon(Icons
                              .chevron_right),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created =
          await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CreateWorkPermitScreen(
                    repository: widget.repository,
                  ),
            ),
          );

          if (created == true) {
            _load();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}