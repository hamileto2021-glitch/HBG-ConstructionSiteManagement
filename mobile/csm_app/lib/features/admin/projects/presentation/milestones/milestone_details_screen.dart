import 'package:flutter/material.dart';

import '../../data/models/milestones/milestone.dart';
import '../../data/repositories/milestone_repository.dart';
import 'milestone_edit_screen.dart';

class MilestoneDetailsScreen extends StatefulWidget {
  const MilestoneDetailsScreen({
    super.key,
    required this.milestone,
    required this.repository,
  });

  final Milestone milestone;
  final MilestoneRepository repository;

  @override
  State<MilestoneDetailsScreen> createState() => _MilestoneDetailsScreenState();
}

class _MilestoneDetailsScreenState extends State<MilestoneDetailsScreen> {
  late Milestone _milestone;
  bool _isChangingStatus = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _milestone = widget.milestone;
  }

  Future<void> _completeMilestone() async {
    setState(() {
      _isChangingStatus = true;
      _errorMessage = null;
    });

    try {
      final milestone = await widget.repository.complete(_milestone.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _milestone = milestone;
        _isChangingStatus = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isChangingStatus = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _reopenMilestone() async {
    setState(() {
      _isChangingStatus = true;
      _errorMessage = null;
    });

    try {
      final milestone = await widget.repository.reopen(_milestone.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _milestone = milestone;
        _isChangingStatus = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isChangingStatus = false;
        _errorMessage = error.toString();
      });
    }
  }
  Future<void> _openEditMilestone() async {
    final updatedMilestone =
    await Navigator.of(context).push<Milestone>(
      MaterialPageRoute(
        builder: (_) => MilestoneEditScreen(
          milestone: _milestone,
          repository: widget.repository,
        ),
      ),
    );

    if (updatedMilestone != null && mounted) {
      setState(() {
        _milestone = updatedMilestone;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_milestone.name),
        actions: [
          if (!_milestone.isCompleted)
            IconButton(
              tooltip: 'Edit Milestone',
              icon: const Icon(Icons.edit),
              onPressed: _openEditMilestone,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_errorMessage != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_errorMessage!),
              ),
            ),
          _buildStatusCard(context),
          const SizedBox(height: 16),
          _buildInformationCard(context),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Milestone Status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              _milestone.isCompleted ? 'Completed' : 'Pending',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (_milestone.isCompleted)
              FilledButton.icon(
                onPressed: _isChangingStatus ? null : _reopenMilestone,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reopen Milestone'),
              )
            else
              FilledButton.icon(
                onPressed: _isChangingStatus ? null : _completeMilestone,
                icon: const Icon(Icons.check),
                label: const Text('Complete Milestone'),
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
              'Milestone Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text('Name: ${_milestone.name}'),
            const SizedBox(height: 8),
            Text(
              'Planned date: '
              '${_formatDate(_milestone.plannedDate)}',
            ),
            if (_milestone.completedDate != null) ...[
              const SizedBox(height: 8),
              Text(
                'Completed date: '
                '${_formatDate(_milestone.completedDate!)}',
              ),
            ],
            if (_milestone.description != null &&
                _milestone.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(_milestone.description!),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
