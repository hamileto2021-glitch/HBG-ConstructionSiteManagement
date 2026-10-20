import 'package:flutter/material.dart';

import '../../data/models/work_task.dart';
import '../../data/repositories/work_task_repository.dart';

class WorkTaskDependencyGraphScreen extends StatelessWidget {
  const WorkTaskDependencyGraphScreen({
    super.key,
    required this.task,
    required this.repository,
    required this.allTasks,
  });

  final WorkTask task;
  final WorkTaskRepository repository;
  final List<WorkTask> allTasks;

  WorkTask? _findTask(String taskId) {
    try {
      return allTasks.firstWhere((t) => t.id == taskId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dependency Graph'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            task.taskNumber,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          Text(
            task.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),

          Text(
            'Predecessor Tasks',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          if (task.dependencies.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'This task has no predecessor dependencies.',
                  ),
                ),
              ),
            )
          else
            ...task.dependencies.map((dependency) {
              final predecessor = _findTask(
                dependency.dependsOnTaskId,
              );

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.account_tree_outlined),
                  title: Text(
                    predecessor?.taskNumber ?? 'Unknown Task',
                  ),
                  subtitle: Text(
                    predecessor?.title ??
                        dependency.dependsOnTaskId,
                  ),
                  trailing: const Icon(Icons.arrow_forward),
                ),
              );
            }),

          const SizedBox(height: 24),

          Text(
            'Task Flow',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  for (int i = 0;
                  i < task.dependencies.length;
                  i++) ...[
                    Builder(
                      builder: (context) {
                        final predecessor = _findTask(
                          task.dependencies[i].dependsOnTaskId,
                        );

                        return _TaskNode(
                          title: predecessor?.taskNumber ??
                              'Unknown Task',
                          subtitle:
                          predecessor?.title ?? '',
                          color: Colors.blue,
                        );
                      },
                    ),
                    const Icon(Icons.arrow_downward),
                  ],

                  _TaskNode(
                    title: task.taskNumber,
                    subtitle: task.title,
                    color: Colors.green,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskNode extends StatelessWidget {
  const _TaskNode({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle),
        ],
      ),
    );
  }
}