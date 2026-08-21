import 'package:flutter/material.dart';

import '../../data/models/work_task.dart';
import '../../data/repositories/work_task_repository.dart';
import 'work_task_create_screen.dart';
import 'work_task_details_screen.dart';

class WorkTaskListScreen extends StatefulWidget {
  const WorkTaskListScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.repository,
    this.projectPhaseId,
  });

  final String projectId;
  final String projectName;
  final WorkTaskRepository repository;
  final String? projectPhaseId;

  @override
  State<WorkTaskListScreen> createState() =>
      _WorkTaskListScreenState();
}

class _WorkTaskListScreenState
    extends State<WorkTaskListScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<WorkTask> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tasks = await widget.repository.getAll(
        projectId: widget.projectId,
        projectPhaseId: widget.projectPhaseId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _openCreateTask() async {
    final createdTask =
        await Navigator.of(context).push<WorkTask>(
      MaterialPageRoute(
        builder: (_) => WorkTaskCreateScreen(
          projectId: widget.projectId,
          projectPhaseId: widget.projectPhaseId!,
          repository: widget.repository,
        ),
      ),
    );

    if (createdTask != null && mounted) {
      await _loadTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectName),
        actions: [
          IconButton(
            tooltip: 'Add Work Task',
            icon: const Icon(Icons.add),
            onPressed: _openCreateTask,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTasks,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Unable to load work tasks.\n\n'
                '$_errorMessage',
              ),
            ),
          ),
        ],
      );
    }

    if (_tasks.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No work tasks have been created yet.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _tasks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _TaskCard(
          task: _tasks[index],
        );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
  });

  final WorkTask task;

  @override
  Widget build(BuildContext context) {
    final progress =
        (task.progressPercentage / 100).clamp(0.0, 1.0);

    return Card(
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => WorkTaskDetailsScreen(
                  task: task,
                  repository: WorkTaskRepository(),
                ),
              ),
            );
          },
          child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.taskNumber,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge,
                  ),
                ),
                Chip(
                  label: Text(
                    _statusLabel(task.status),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              task.title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),
            if (task.description != null &&
                task.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(task.description!),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${task.progressPercentage.toStringAsFixed(1)}%',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Priority: ${_priorityLabel(task.priority)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
          ),
        ),
    );
  }

  String _statusLabel(WorkTaskStatus status) {
    switch (status) {
      case WorkTaskStatus.notStarted:
        return 'Not Started';
      case WorkTaskStatus.inProgress:
        return 'In Progress';
      case WorkTaskStatus.blocked:
        return 'Blocked';
      case WorkTaskStatus.onHold:
        return 'On Hold';
      case WorkTaskStatus.completed:
        return 'Completed';
      case WorkTaskStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _priorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.normal:
        return 'Normal';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.critical:
        return 'Critical';
    }
  }
}
