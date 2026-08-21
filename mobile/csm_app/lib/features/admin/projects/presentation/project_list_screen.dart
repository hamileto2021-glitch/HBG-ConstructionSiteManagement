import 'package:flutter/material.dart';

import '../data/models/project.dart';
import '../data/repositories/project_repository.dart';
import 'project_details_screen.dart';
import 'project_create.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({
    super.key,
    required this.repository,
  });

  final ProjectRepository repository;

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Project> _projects = const [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final projects = await widget.repository.getAll();

      if (!mounted) {
        return;
      }

      setState(() {
        _projects = projects;
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

  Future<void> _openCreateProject() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProjectCreateScreen(
          repository: widget.repository,
        ),
      ),
    );

    if (created == true && mounted) {
      await _loadProjects();
    }
  }
  Future<void> _refreshProjects() async {
    try {
      final projects = await widget.repository.getAll();

      if (!mounted) {
        return;
      }

      setState(() {
        _projects = projects;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            tooltip: 'Create Project',
            icon: const Icon(Icons.add),
            onPressed: _openCreateProject,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to load projects.',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _loadProjects,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_projects.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshProjects,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 160),
            Icon(
              Icons.assignment_outlined,
              size: 56,
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'No projects found.',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshProjects,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _projects.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _ProjectCard(
            project: _projects[index],
            repository: widget.repository,
          );
        },
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.repository,
  });

  final Project project;
  final ProjectRepository repository;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProjectDetailsScreen(
                project: project,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.projectCode,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        project.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: project.status),
              ],
            ),
            if (project.description != null &&
                project.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(project.description!),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Progress',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Text(
                  '${project.progressPercentage.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (project.progressPercentage / 100)
                  .clamp(0.0, 1.0),
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Contract value',
              value: project.contractValue.toStringAsFixed(2),
            ),
            _InfoRow(
              label: 'Planned start',
              value: _formatDate(project.plannedStartDate),
            ),
            _InfoRow(
              label: 'Planned end',
              value: _formatDate(project.plannedEndDate),
            ),
          ],
        ),
      ),
    ),
    );
  }

  static String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Not set';
    }

    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.status,
  });

  final ProjectStatus status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(_label(status)),
    );
  }

  String _label(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.draft:
        return 'Draft';
      case ProjectStatus.planning:
        return 'Planning';
      case ProjectStatus.active:
        return 'Active';
      case ProjectStatus.onHold:
        return 'On Hold';
      case ProjectStatus.completed:
        return 'Completed';
      case ProjectStatus.cancelled:
        return 'Cancelled';
      case ProjectStatus.closed:
        return 'Closed';
    }
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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label),
          ),
          Text(
            value,
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }
}













