import 'package:flutter/material.dart';

import '../../data/models/work_task.dart';
import '../../data/repositories/work_task_repository.dart';
import 'gantt_timeline_screen.dart';

class WorkTaskListScreen extends StatefulWidget {
  const WorkTaskListScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.projectPhaseId,
    required this.repository,
  });

  final String projectId;
  final String projectName;
  final String projectPhaseId;
  final WorkTaskRepository repository;

  @override
  State<WorkTaskListScreen> createState() =>
      _WorkTaskListScreenState();
}

class _WorkTaskListScreenState
    extends State<WorkTaskListScreen> {
  final List<WorkTask> _tasks = [];

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
      final data = await widget.repository.getAll(
        projectId: widget.projectId,
        projectPhaseId: widget.projectPhaseId,
      );

      if (!mounted) return;

      setState(() {
        _tasks
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

  Color _statusColor(WorkTaskStatus status) {
    switch (status) {
      case WorkTaskStatus.notStarted:
        return Colors.orange;
      case WorkTaskStatus.inProgress:
        return Colors.blue;
      case WorkTaskStatus.onHold:
        return Colors.grey;
      case WorkTaskStatus.completed:
        return Colors.green;
      case WorkTaskStatus.cancelled:
        return Colors.red;
    }
  }

  String _status(WorkTaskStatus status) {
    switch (status) {
      case WorkTaskStatus.notStarted:
        return 'Not Started';
      case WorkTaskStatus.inProgress:
        return 'In Progress';
      case WorkTaskStatus.onHold:
        return 'On Hold';
      case WorkTaskStatus.completed:
        return 'Completed';
      case WorkTaskStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _date(DateTime? d) {
    if (d == null) return '-';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
          IconButton(
            icon: const Icon(Icons.timeline),
            tooltip: 'Gantt Timeline',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GanttTimelineScreen(
                    tasks: _tasks,
                    projectName: widget.projectName,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _tasks.isEmpty
          ? const Center(
        child: Text('No Work Tasks'),
      )
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _tasks.length,
          itemBuilder: (context, index) {
            final task = _tasks[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium,
                          ),
                        ),
                        Chip(
                          backgroundColor:
                          _statusColor(task.status),
                          label: Text(
                            _status(task.status),
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Text('Task No: ${task.taskNumber}'),

                    Text(
                      'Schedule: ${_date(task.plannedStartDate)} → ${_date(task.plannedEndDate)}',
                    ),

                    const SizedBox(height: 10),

                    LinearProgressIndicator(
                      value:
                      task.progressPercentage / 100,
                    ),

                    const SizedBox(height: 6),

                    Align(
                      alignment:
                      Alignment.centerRight,
                      child: Text(
                        '${task.progressPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontWeight:
                          FontWeight.bold,
                        ),
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