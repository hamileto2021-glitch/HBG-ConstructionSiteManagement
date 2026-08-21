import 'package:flutter/material.dart';

import '../../data/models/milestones/milestone.dart';
import '../../data/repositories/milestone_repository.dart';
import 'milestone_create_screen.dart';
import 'milestone_details_screen.dart';

class MilestoneListScreen extends StatefulWidget {
  const MilestoneListScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    this.projectPhaseId,
    this.phaseName,
    required this.repository,
  });

  final String projectId;
  final String projectName;
  final String? projectPhaseId;
  final String? phaseName;
  final MilestoneRepository repository;

  @override
  State<MilestoneListScreen> createState() => _MilestoneListScreenState();
}

class _MilestoneListScreenState extends State<MilestoneListScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Milestone> _milestones = [];

  @override
  void initState() {
    super.initState();
    _loadMilestones();
  }

  Future<void> _loadMilestones() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final milestones = await widget.repository.getAll(
        projectId: widget.projectId,
        projectPhaseId: widget.projectPhaseId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _milestones = milestones;
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

  Future<void> _openCreateMilestone() async {
    final createdMilestone = await Navigator.of(context).push<Milestone>(
      MaterialPageRoute(
        builder: (_) => MilestoneCreateScreen(
          projectId: widget.projectId,
          projectPhaseId: widget.projectPhaseId,
          repository: widget.repository,
        ),
      ),
    );

    if (createdMilestone != null && mounted) {
      await _loadMilestones();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.phaseName == null
        ? 'Milestones'
        : '${widget.phaseName} Milestones';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Add Milestone',
            icon: const Icon(Icons.add),
            onPressed: _openCreateMilestone,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMilestones,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Unable to load milestones.\n\n'
                '$_errorMessage',
              ),
            ),
          ),
        ],
      );
    }

    if (_milestones.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No milestones have been created yet.',
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
      itemCount: _milestones.length,
      separatorBuilder: (_, _) =>
      const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _MilestoneCard(
          milestone: _milestones[index],
          repository: widget.repository,
        );
      },
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({
    required this.milestone,
    required this.repository,
  });

  final Milestone milestone;
  final MilestoneRepository repository;

  @override
  Widget build(BuildContext context) {
    final status = milestone.isCompleted
        ? 'Completed'
        : 'Pending';

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MilestoneDetailsScreen(
                milestone: milestone,
                repository: repository,
              ),
            ),
          );
        },
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
                      milestone.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium,
                    ),
                  ),
                  Chip(
                    label: Text(status),
                  ),
                ],
              ),
              if (milestone.description != null &&
                  milestone.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(milestone.description!),
              ],
              const SizedBox(height: 12),
              Text(
                'Planned: '
                '${_formatDate(milestone.plannedDate)}',
              ),
              if (milestone.completedDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Completed: '
                  '${_formatDate(milestone.completedDate!)}',
                ),
              ],
            ],
          ),
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
