import 'package:flutter/material.dart';

import '../../data/models/project_milestone.dart';
import '../../data/repositories/project_milestone_repository.dart';
import 'project_milestone_edit_screen.dart';

class ProjectMilestoneDetailsScreen extends StatefulWidget {
  const ProjectMilestoneDetailsScreen({
    super.key,
    required this.milestone,
    required this.repository,
  });

  final ProjectMilestone milestone;
  final ProjectMilestoneRepository repository;

  @override
  State<ProjectMilestoneDetailsScreen> createState() =>
      _ProjectMilestoneDetailsScreenState();
}

class _ProjectMilestoneDetailsScreenState
    extends State<ProjectMilestoneDetailsScreen> {
  late ProjectMilestone _milestone;

  @override
  void initState() {
    super.initState();
    _milestone = widget.milestone;
  }

  Future<void> _editMilestone() async {
    final updated = await Navigator.push<ProjectMilestone>(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectMilestoneEditScreen(
          milestone: _milestone,
          repository: widget.repository,
        ),
      ),
    );

    if (updated != null && mounted) {
      setState(() => _milestone = updated);
    }
  }

  Color _statusColor(MilestoneStatus status) {
    switch (status) {
      case MilestoneStatus.pending:
        return Colors.grey;
      case MilestoneStatus.inProgress:
        return Colors.blue;
      case MilestoneStatus.completed:
        return Colors.green;
      case MilestoneStatus.delayed:
        return Colors.red;
    }
  }

  String _statusText(MilestoneStatus status) {
    switch (status) {
      case MilestoneStatus.pending:
        return 'Pending';
      case MilestoneStatus.inProgress:
        return 'In Progress';
      case MilestoneStatus.completed:
        return 'Completed';
      case MilestoneStatus.delayed:
        return 'Delayed';
    }
  }

  String _date(DateTime? date) {
    if (date == null) return 'Not set';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _milestone.progressPercentage / 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Milestone Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: _editMilestone,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _milestone.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Chip(
                    backgroundColor: _statusColor(_milestone.status),
                    label: Text(
                      _statusText(_milestone.status),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Progress',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${_milestone.progressPercentage.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.titleMedium,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Milestone Information',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(
                    label: 'Planned Date',
                    value: _date(_milestone.plannedDate),
                  ),
                  _InfoRow(
                    label: 'Actual Date',
                    value: _date(_milestone.actualDate),
                  ),
                  if (_milestone.description != null &&
                      _milestone.description!.isNotEmpty)
                    _InfoRow(
                      label: 'Description',
                      value: _milestone.description!,
                    ),
                  if (_milestone.notes != null &&
                      _milestone.notes!.isNotEmpty)
                    _InfoRow(
                      label: 'Notes',
                      value: _milestone.notes!,
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
      padding: const EdgeInsets.only(bottom: 14),
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
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}