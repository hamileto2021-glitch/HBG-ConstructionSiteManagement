import 'package:flutter/material.dart';

import '../../data/models/wbs_task.dart';
import '../../data/repositories/wbs_task_repository.dart';
import 'wbs_task_edit_screen.dart';
import '../../data/repositories/task_resource_assignment_repository.dart';
import '../resources/task_resource_assignment_list_screen.dart';
import '../../../../../core/network/api_client.dart';




class WbsTaskDetailScreen extends StatefulWidget {
  const WbsTaskDetailScreen({
    super.key,
    required this.task,
    required this.repository,
  });

  final WbsTask task;
  final WbsTaskRepository repository;

  @override
  State<WbsTaskDetailScreen> createState() =>
      _WbsTaskDetailScreenState();
}

class _WbsTaskDetailScreenState
    extends State<WbsTaskDetailScreen> {
  late WbsTask _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  Future<void> _editTask() async {
    final updated = await Navigator.push<WbsTask>(
      context,
      MaterialPageRoute(
        builder: (_) => WbsTaskEditScreen(
          task: _task,
          repository: widget.repository,
        ),
      ),
    );

    if (updated != null && mounted) {
      setState(() => _task = updated);
    }
  }

  String _date(DateTime? d) {
    if (d == null) return '-';
    return '${d.day}/${d.month}/${d.year}';
  }

  String _status(WbsTaskStatus s) {
    switch (s) {
      case WbsTaskStatus.notStarted:
        return 'Not Started';
      case WbsTaskStatus.inProgress:
        return 'In Progress';
      case WbsTaskStatus.onHold:
        return 'On Hold';
      case WbsTaskStatus.completed:
        return 'Completed';
      case WbsTaskStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _priority(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.critical:
        return 'Critical';
    }
  }

  Color _statusColor(WbsTaskStatus s) {
    switch (s) {
      case WbsTaskStatus.notStarted:
        return Colors.orange;
      case WbsTaskStatus.inProgress:
        return Colors.blue;
      case WbsTaskStatus.onHold:
        return Colors.grey;
      case WbsTaskStatus.completed:
        return Colors.green;
      case WbsTaskStatus.cancelled:
        return Colors.red;
    }
  }

  Widget _buildResourceAssignmentCard(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.groups),
        ),
        title: const Text('Resource Assignment'),
        subtitle: const Text(
          'Assign employees and manage labour hours',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskResourceAssignmentListScreen(
                wbsTaskId: _task.id,
                taskName: _task.name,
                repository: TaskResourceAssignmentRepository(
                  ApiClient(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_task.taskCode),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: _editTask,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    _task.name,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall,
                  ),
                  const SizedBox(height: 12),

                  Chip(
                    backgroundColor:
                    _statusColor(_task.status),
                    label: Text(
                      _status(_task.status),
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Progress',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),

                  const SizedBox(height: 8),

                  LinearProgressIndicator(
                    value:
                    _task.progressPercentage / 100,
                  ),



                  const SizedBox(height: 8),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${_task.progressPercentage.toStringAsFixed(0)}%',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    'Task Information',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge,
                  ),



                  const SizedBox(height: 16),

                  _InfoRow(
                    label: 'Task Code',
                    value: _task.taskCode,
                  ),

                  _InfoRow(
                    label: 'Priority',
                    value: _priority(_task.priority),
                  ),

                  _InfoRow(
                    label: 'Planned Start',
                    value: _date(
                      _task.plannedStartDate,
                    ),
                  ),

                  _InfoRow(
                    label: 'Planned Finish',
                    value: _date(
                      _task.plannedFinishDate,
                    ),
                  ),

                  _InfoRow(
                    label: 'Actual Start',
                    value: _date(
                      _task.actualStartDate,
                    ),
                  ),

                  _InfoRow(
                    label: 'Actual Finish',
                    value: _date(
                      _task.actualFinishDate,
                    ),
                  ),

                  _InfoRow(
                    label: 'Estimated Hours',
                    value: _task.estimatedHours
                        .toStringAsFixed(1),
                  ),

                  _InfoRow(
                    label: 'Actual Hours',
                    value: _task.actualHours
                        .toStringAsFixed(1),
                  ),

                  if (_task.description != null &&
                      _task.description!
                          .isNotEmpty) ...[
                    const Divider(height: 28),

                    Text(
                      'Description',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium,
                    ),

                    const SizedBox(height: 8),

                    Text(_task.description!),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          _buildResourceAssignmentCard(context),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}