import 'package:flutter/material.dart';
import 'package:csm_app/features/admin/projects/data/models/project_delay.dart';
import 'package:csm_app/features/admin/projects/data/repositories/project_delay_repository.dart';

import 'project_delay_create_screen.dart';

class ProjectDelayListScreen extends StatefulWidget {
  const ProjectDelayListScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.siteId,
  });

  final String projectId;
  final String projectName;
  final String siteId;

  @override
  State<ProjectDelayListScreen> createState() =>
      _ProjectDelayListScreenState();
}

class _ProjectDelayListScreenState
    extends State<ProjectDelayListScreen> {
  final _repository = ProjectDelayRepository();

  bool _loading = true;
  List<ProjectDelay> _delays = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      _delays = await _repository.getAll(
        projectId: widget.projectId,
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _create() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectDelayCreateScreen(
          projectId: widget.projectId,
          siteId: widget.siteId,
        ),
      ),
    );

    if (created == true) {
      await _load();
    }
  }

  Future<void> _delete(ProjectDelay item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Delay'),
        content: Text(
          'Delete "${item.title}" permanently?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _repository.delete(item.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Delay deleted')),
    );

    await _load();
  }

  Color _statusColor(ProjectDelay item) =>
      item.isResolved ? Colors.green : Colors.orange;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.projectName} Delays'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('New Delay'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _delays.isEmpty
          ? const Center(child: Text('No delays recorded'))
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          itemCount: _delays.length,
          itemBuilder: (context, index) {
            final item = _delays[index];

            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              child: ListTile(
                onLongPress: () => _delete(item),
                leading: CircleAvatar(
                  backgroundColor: _statusColor(item)
                      .withValues(alpha: 0.15),
                  child: Icon(
                    item.isResolved
                        ? Icons.check_circle
                        : Icons.warning_amber,
                    color: _statusColor(item),
                  ),
                ),
                title: Text(item.title),
                subtitle: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(item.category.name),
                    Text(
                      '${item.timeImpactDays} day(s)',
                    ),
                    Text(
                      item.delayDate
                          .toIso8601String()
                          .split('T')
                          .first,
                    ),
                  ],
                ),
                trailing: Chip(
                  label: Text(
                    item.isResolved
                        ? 'Resolved'
                        : 'Open',
                  ),
                  backgroundColor: _statusColor(item)
                      .withValues(alpha: 0.15),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}