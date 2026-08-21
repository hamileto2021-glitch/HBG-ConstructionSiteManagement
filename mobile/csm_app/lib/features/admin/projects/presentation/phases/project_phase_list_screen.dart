import 'package:flutter/material.dart';

import '../../data/models/phases/project_phase.dart';
import '../../data/repositories/project_phase_repository.dart';
import 'project_phase_create_screen.dart';
import 'project_phase_details_screen.dart';

class ProjectPhaseListScreen extends StatefulWidget {
  const ProjectPhaseListScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.repository,
  });

  final String projectId;
  final String projectName;
  final ProjectPhaseRepository repository;

  @override
  State<ProjectPhaseListScreen> createState() =>
      _ProjectPhaseListScreenState();
}

class _ProjectPhaseListScreenState
    extends State<ProjectPhaseListScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ProjectPhase> _phases = [];


  @override
  void initState() {
    super.initState();
    _loadPhases();
  }

  Future<void> _loadPhases() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final phases = await widget.repository.getAll(
        projectId: widget.projectId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _phases = phases;
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

  Future<void> _openCreatePhase() async {
    final createdPhase =
        await Navigator.of(context).push<ProjectPhase>(
      MaterialPageRoute(
        builder: (_) => ProjectPhaseCreateScreen(
          projectId: widget.projectId,
          repository: widget.repository,
        ),
      ),
    );

    if (createdPhase != null && mounted) {
      await _loadPhases();
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectName),
        actions: [
          IconButton(
            tooltip: 'Add Phase',
            icon: const Icon(Icons.add),
            onPressed: _openCreatePhase,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPhases,
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
                'Unable to load project phases.\n\n'
                '$_errorMessage',
              ),
            ),
          ),
        ],
      );
    }

    if (_phases.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No project phases have been created yet.',
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
      itemCount: _phases.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _PhaseCard(
          phase: _phases[index],
          repository: widget.repository,
        );
      },
    );
  }
}

class _PhaseCard extends StatelessWidget {
  const _PhaseCard({
    required this.phase,
    required this.repository,
  });

  final ProjectPhase phase;
  final ProjectPhaseRepository repository;


  @override
  Widget build(BuildContext context) {
    final progress =
        (phase.progressPercentage / 100).clamp(0.0, 1.0);

      return Card(
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProjectPhaseDetailsScreen(
                  phase: phase,
                  repository: repository,
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
                CircleAvatar(
                  child: Text(
                    phase.sequence.toString(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    phase.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),
                ),
                Chip(
                  label: Text(
                    _statusLabel(phase.status),
                  ),
                ),
              ],
            ),
            if (phase.description != null &&
                phase.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(phase.description!),
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
                  '${phase.progressPercentage.toStringAsFixed(1)}%',
                ),
              ],
            ),
                 ],
               ),
             ),
           ),
         );
         }

  String _statusLabel(ProjectPhaseStatus status) {
    switch (status) {
      case ProjectPhaseStatus.notStarted:
        return 'Not Started';
      case ProjectPhaseStatus.inProgress:
        return 'In Progress';
      case ProjectPhaseStatus.onHold:
        return 'On Hold';
      case ProjectPhaseStatus.completed:
        return 'Completed';
      case ProjectPhaseStatus.cancelled:
        return 'Cancelled';
    }
  }
}


