import 'package:flutter/material.dart';

import '../../data/models/work_task.dart';
import '../../data/repositories/work_task_repository.dart';

class WorkTaskDetailsScreen extends StatefulWidget {
  const WorkTaskDetailsScreen({
    super.key,
    required this.task,
    required this.repository,
  });

  final WorkTask task;
  final WorkTaskRepository repository;

  @override
  State<WorkTaskDetailsScreen> createState() =>
      _WorkTaskDetailsScreenState();
}

class _WorkTaskDetailsScreenState
    extends State<WorkTaskDetailsScreen> {
  late WorkTask _task;
  bool _isLoading = true;
  bool _isChangingStatus = false;
  bool _isUpdatingProgress = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _loadTask();
  }

  Future<void> _loadTask() async {
    try {
      final task = await widget.repository.getById(
        widget.task.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _task = task;
        _isLoading = false;
        _errorMessage = null;
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

  List<WorkTaskStatus> _allowedNextStatuses(
    WorkTaskStatus current,
  ) {
    switch (current) {
      case WorkTaskStatus.notStarted:
        return [
          WorkTaskStatus.inProgress,
          WorkTaskStatus.cancelled,
        ];

      case WorkTaskStatus.inProgress:
        return [
          WorkTaskStatus.blocked,
          WorkTaskStatus.onHold,
          WorkTaskStatus.completed,
          WorkTaskStatus.cancelled,
        ];

      case WorkTaskStatus.blocked:
        return [
          WorkTaskStatus.inProgress,
          WorkTaskStatus.onHold,
          WorkTaskStatus.cancelled,
        ];

      case WorkTaskStatus.onHold:
        return [
          WorkTaskStatus.inProgress,
          WorkTaskStatus.completed,
          WorkTaskStatus.cancelled,
        ];

      case WorkTaskStatus.completed:
      case WorkTaskStatus.cancelled:
        return [];
    }
  }

  Future<void> _changeTaskStatus(
    WorkTaskStatus status,
  ) async {
    setState(() {
      _isChangingStatus = true;
    });

    try {
      final updatedTask =
          await widget.repository.changeStatus(
        taskId: _task.id,
        status: status,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _task = updatedTask;
        _isChangingStatus = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Task status changed to ${_statusLabel(status)}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isChangingStatus = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
        ),
      );
    }
  }

  Future<void> _showStatusDialog(
    List<WorkTaskStatus> allowedStatuses,
  ) async {
    final selectedStatus =
        await showDialog<WorkTaskStatus>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text('Change Task Status'),
          children: allowedStatuses
              .map(
                (status) => SimpleDialogOption(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(status);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                    ),
                    child: Text(
                      _statusLabel(status),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );

    if (selectedStatus != null && mounted) {
      await _changeTaskStatus(selectedStatus);
    }
  }

  Future<void> _showProgressDialog() async {
    final controller = TextEditingController(
      text: _task.progressPercentage
          .toStringAsFixed(1),
    );

    final value = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Update Progress'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Progress percentage',
              suffixText: '%',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = double.tryParse(
                  controller.text.trim(),
                );

                if (parsed == null ||
                    parsed < 0 ||
                    parsed > 100) {
                  ScaffoldMessenger.of(dialogContext)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Enter a value between 0 and 100.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.of(dialogContext).pop(parsed);
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );

    if (value != null && mounted) {
      await _updateProgress(value);
    }
  }

  Future<void> _updateProgress(double progress) async {
    setState(() {
      _isUpdatingProgress = true;
    });

    try {
      final updatedTask =
          await widget.repository.updateProgress(
        taskId: _task.id,
        progressPercentage: progress,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _task = updatedTask;
        _isUpdatingProgress = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Progress updated to '
            '${updatedTask.progressPercentage.toStringAsFixed(1)}%.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUpdatingProgress = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_task.taskNumber),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTask,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_errorMessage != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Unable to refresh task details.\n\n'
                    '$_errorMessage',
                  ),
                ),
              ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: LinearProgressIndicator(),
              ),
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildProgressCard(context),
            const SizedBox(height: 16),
            _buildStatusCard(context),
            const SizedBox(height: 16),
            _buildInformationCard(context),
            const SizedBox(height: 16),
            _buildDatesCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _task.taskNumber,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            Text(
              _task.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Chip(
              label: Text(
                _statusLabel(_task.status),
              ),
            ),
            if (_task.description != null &&
                _task.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(_task.description!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context) {
    final progress =
        (_task.progressPercentage / 100).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${_task.progressPercentage.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed:
                  _isUpdatingProgress ? null : _showProgressDialog,
              icon: const Icon(Icons.percent),
              label: const Text('Update Progress'),
            ),
            if (_isUpdatingProgress) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final allowedStatuses =
        _allowedNextStatuses(_task.status);

    if (allowedStatuses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Current status: ${_statusLabel(_task.status)}',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isChangingStatus
                  ? null
                  : () => _showStatusDialog(
                        allowedStatuses,
                      ),
              icon: const Icon(Icons.sync_alt),
              label: const Text('Change Status'),
            ),
            if (_isChangingStatus) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInformationCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Task number',
              value: _task.taskNumber,
            ),
            _InfoRow(
              label: 'Title',
              value: _task.title,
            ),
            _InfoRow(
              label: 'Priority',
              value: _priorityLabel(_task.priority),
            ),
            _InfoRow(
              label: 'Status',
              value: _statusLabel(_task.status),
            ),
            if (_task.description != null &&
                _task.description!.trim().isNotEmpty)
              _InfoRow(
                label: 'Description',
                value: _task.description!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatesCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Dates',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Planned start',
              value: _formatDate(_task.plannedStartDate),
            ),
            _InfoRow(
              label: 'Planned end',
              value: _formatDate(_task.plannedEndDate),
            ),
            _InfoRow(
              label: 'Actual start',
              value: _formatDate(_task.actualStartDate),
            ),
            _InfoRow(
              label: 'Actual end',
              value: _formatDate(_task.actualEndDate),
            ),
            _InfoRow(
              label: 'Created',
              value: _formatDateTime(_task.createdAtUtc),
            ),
          ],
        ),
      ),
    );
  }

  static String _statusLabel(WorkTaskStatus status) {
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

  static String _priorityLabel(TaskPriority priority) {
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

  static String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Not set';
    }

    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

