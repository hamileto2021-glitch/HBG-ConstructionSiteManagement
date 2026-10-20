import 'package:flutter/material.dart';

import '../../data/models/task_resource_assignment.dart';
import '../../data/repositories/task_resource_assignment_repository.dart';
import 'task_resource_assignment_create_screen.dart';

class TaskResourceAssignmentListScreen extends StatefulWidget {
  const TaskResourceAssignmentListScreen({
    super.key,
    required this.wbsTaskId,
    required this.taskName,
    required this.repository,
  });

  final String wbsTaskId;
  final String taskName;
  final TaskResourceAssignmentRepository repository;

  @override
  State<TaskResourceAssignmentListScreen> createState() =>
      _TaskResourceAssignmentListScreenState();
}

class _TaskResourceAssignmentListScreenState
    extends State<TaskResourceAssignmentListScreen> {
  final List<TaskResourceAssignment> _assignments = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await widget.repository.getByTask(widget.wbsTaskId);

      if (!mounted) return;

      setState(() {
        _assignments
          ..clear()
          ..addAll(data);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Color _avatarColor(String name) {
    final colors = [
      Colors.blue,
      Colors.teal,
      Colors.indigo,
      Colors.orange,
      Colors.green,
      Colors.purple,
    ];

    return colors[name.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taskName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: const Text('Assign'),
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => TaskResourceAssignmentCreateScreen(
                wbsTaskId: widget.wbsTaskId,
                repository: widget.repository,
              ),
            ),
          );

          if (created == true) {
            _load();
          }
        },
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _assignments.isEmpty
          ? const Center(
        child: Text('No employees assigned'),
      )
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _assignments.length,
          itemBuilder: (context, index) {
            final item = _assignments[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor:
                      _avatarColor(item.employeeName),
                      child: Text(
                        item.employeeName.isEmpty
                            ? '?'
                            : item.employeeName[0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.employeeName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(item.role),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Planned ${item.plannedHours.toStringAsFixed(1)} h',
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Actual ${item.actualHours.toStringAsFixed(1)} h',
                              ),
                            ],
                          ),
                          if ((item.remarks ?? '').isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              item.remarks!,
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}