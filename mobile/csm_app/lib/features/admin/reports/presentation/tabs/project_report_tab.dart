import 'package:flutter/material.dart';

class ProjectReportTab extends StatelessWidget {
  const ProjectReportTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Project Performance',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        Row(
          children: const [
            Expanded(
              child: _MetricCard(
                title: 'Active',
                value: '14',
                color: Colors.blue,
                icon: Icons.business,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Completed',
                value: '8',
                color: Colors.green,
                icon: Icons.check_circle,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: const [
            Expanded(
              child: _MetricCard(
                title: 'Delayed',
                value: '3',
                color: Colors.red,
                icon: Icons.warning,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Milestones',
                value: '41',
                color: Colors.orange,
                icon: Icons.flag,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        const Text(
          'Overall Progress',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _ProgressRow(
                  project: 'Office Complex',
                  progress: 0.82,
                ),
                Divider(),
                _ProgressRow(
                  project: 'Warehouse',
                  progress: 0.58,
                ),
                Divider(),
                _ProgressRow(
                  project: 'Road Project',
                  progress: 0.33,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'Milestone Summary',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        Card(
          child: Column(
            children: const [
              ListTile(
                leading: Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
                title: Text('Completed Milestones'),
                trailing: Text(
                  '24',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.pending,
                  color: Colors.orange,
                ),
                title: Text('Pending Milestones'),
                trailing: Text(
                  '14',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.error,
                  color: Colors.red,
                ),
                title: Text('Delayed Milestones'),
                trailing: Text(
                  '3',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'Task Completion',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _TaskRow(
                  label: 'Completed',
                  count: 128,
                  color: Colors.green,
                ),
                const SizedBox(height: 10),
                _TaskRow(
                  label: 'In Progress',
                  count: 46,
                  color: Colors.blue,
                ),
                const SizedBox(height: 10),
                _TaskRow(
                  label: 'Not Started',
                  count: 19,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.project,
    required this.progress,
  });

  final String project;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(project)),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress,
          minHeight: 8,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 8,
          backgroundColor: color,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
        Text(
          count.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}