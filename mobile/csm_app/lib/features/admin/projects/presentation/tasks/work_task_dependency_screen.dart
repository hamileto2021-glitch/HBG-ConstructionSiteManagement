import 'package:flutter/material.dart';

import '../../data/models/work_task.dart';
import '../../data/repositories/work_task_repository.dart';

class WorkTaskDependencyScreen extends StatefulWidget {
  const WorkTaskDependencyScreen({
    super.key,
    required this.currentTask,
    required this.allTasks,
    required this.repository,
  });

  final WorkTask currentTask;
  final List<WorkTask> allTasks;
  final WorkTaskRepository repository;

  @override
  State<WorkTaskDependencyScreen> createState() =>
      _WorkTaskDependencyScreenState();
}

class _WorkTaskDependencyScreenState
    extends State<WorkTaskDependencyScreen> {
  String? _selectedTaskId;
  bool _saving = false;

  List<WorkTask> get _availableTasks =>
      widget.allTasks
          .where((t) => t.id != widget.currentTask.id)
          .toList();

  Future<void> _save() async {
    if (_selectedTaskId == null) return;

    setState(() => _saving = true);

    try {
      await widget.repository.addDependency(
        taskId: widget.currentTask.id,
        dependsOnTaskId: _selectedTaskId!,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    if (mounted) {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Dependency'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              'Current Task',
              style:
              Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(
              widget.currentTask.title,
              style:
              Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),

            DropdownButtonFormField<String>(
              initialValue: _selectedTaskId,
              decoration: const InputDecoration(
                labelText: 'Depends On',
                border: OutlineInputBorder(),
              ),
              items: _availableTasks
                  .map(
                    (task) => DropdownMenuItem(
                  value: task.id,
                  child: Text(task.title),
                ),
              )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTaskId = value;
                });
              },
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                _saving ? null : _save,
                icon: const Icon(Icons.link),
                label: Text(
                  _saving
                      ? 'Saving...'
                      : 'Create Dependency',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}