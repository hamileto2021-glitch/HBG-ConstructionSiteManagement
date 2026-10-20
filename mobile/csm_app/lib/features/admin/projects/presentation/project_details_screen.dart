import 'package:flutter/material.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../data/models/project.dart';
import '../data/repositories/project_repository.dart';
import '../data/repositories/project_phase_repository.dart';
import 'project_edit_screen.dart';
import 'phases/project_phase_list_screen.dart';

import 'diary/daily_site_diary_list_screen.dart';

import 'daily_progress_list_screen.dart';
import '../data/repositories/daily_progress_repository.dart';
import 'project_delay_list_screen.dart';
import 'progress/project_progress_dashboard_screen.dart';
import 'tasks/gantt_timeline_screen.dart';
import '../data/models/work_task.dart';
import '../data/repositories/work_task_repository.dart';





class ProjectDetailsScreen extends StatefulWidget {
  const ProjectDetailsScreen({
    super.key,
    required this.project,
    required this.repository,
  });

  final Project project;
  final ProjectRepository repository;




  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {


  final DailyProgressRepository _dailyRepository =
  DailyProgressRepository();

  final WorkTaskRepository _workTaskRepository = WorkTaskRepository();

  bool _isLoadingWorkTasks = true;
  String? _workTaskErrorMessage;
  List<WorkTask> _workTasks = [];









  String money(double value) =>
      CurrencyFormatter.etb(value);

  late Project _project;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isChangingStatus = false;



  @override
  void initState() {
    super.initState();

    _project = widget.project;

    _loadProject();
    _loadWorkTasks();
  }

  Future<void> _loadProject() async {
    try {
      final project = await widget.repository.getById(
        widget.project.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _project = project;
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

  Future<void> _loadWorkTasks() async {
    setState(() {
      _isLoadingWorkTasks = true;
      _workTaskErrorMessage = null;
    });

    try {
      final tasks = await _workTaskRepository.getAll(
        projectId: _project.id,
      );

      if (!mounted) return;

      setState(() {
        _workTasks = tasks;
        _isLoadingWorkTasks = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _workTaskErrorMessage = e.toString();
        _isLoadingWorkTasks = false;
      });
    }
  }




  Future<void> _openEditProject() async {
    final updatedProject = await Navigator.of(context).push<Project>(
      MaterialPageRoute(
        builder: (_) => ProjectEditScreen(
          project: _project,
          repository: widget.repository,
        ),
      ),
    );

    if (updatedProject != null && mounted) {
      setState(() {
        _project = updatedProject;
      });

      await _loadProject();
    }
  }
  List<ProjectStatus> _allowedNextStatuses(ProjectStatus current) {
    switch (current) {
      case ProjectStatus.draft:
        return [
          ProjectStatus.planning,
          ProjectStatus.cancelled,
        ];
      case ProjectStatus.planning:
        return [
          ProjectStatus.active,
          ProjectStatus.cancelled,
        ];
      case ProjectStatus.active:
        return [
          ProjectStatus.onHold,
          ProjectStatus.completed,
          ProjectStatus.cancelled,
        ];
      case ProjectStatus.onHold:
        return [
          ProjectStatus.active,
          ProjectStatus.completed,
          ProjectStatus.cancelled,
        ];
      case ProjectStatus.completed:
        return [
          ProjectStatus.closed,
        ];
      case ProjectStatus.cancelled:
      case ProjectStatus.closed:
        return [];
    }
  }

  Future<void> _changeProjectStatus(ProjectStatus status) async {
    setState(() {
      _isChangingStatus = true;
    });

    try {
      final updatedProject = await widget.repository.changeStatus(
        projectId: _project.id,
        status: status,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _project = updatedProject;
        _isChangingStatus = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Project status changed to ${_statusLabel(status)}.',
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

  Widget _buildStatusManagementCard(BuildContext context) {
    final allowedStatuses = _allowedNextStatuses(_project.status);

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
              'Project Status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Current status: ${_statusLabel(_project.status)}',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isChangingStatus
                  ? null
                  : () => _showStatusDialog(allowedStatuses),
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



  Future<void> _showStatusDialog(
    List<ProjectStatus> allowedStatuses,
  ) async {
    final selectedStatus = await showDialog<ProjectStatus>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text('Change Project Status'),
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
      await _changeProjectStatus(selectedStatus);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_project.projectCode),
        actions: [
          IconButton(
            tooltip: 'Progress Dashboard',
            icon: const Icon(Icons.query_stats),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProjectProgressDashboardScreen(
                    projectId: _project.id,
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Gantt Timeline',
            icon: const Icon(Icons.view_timeline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GanttTimelineScreen(
                    tasks: _workTasks,
                    projectName: _project.name,
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Project Phases',
            icon: const Icon(Icons.account_tree),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProjectPhaseListScreen(
                    projectId: _project.id,
                    projectName: _project.name,
                    repository: ProjectPhaseRepository(),
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Daily Site Diary',
            icon: const Icon(Icons.menu_book),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DailySiteDiaryListScreen(
                    projectId: _project.id,
                    projectName: _project.name,
                    constructionSiteId: _project.constructionSiteId,
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Edit Project',
            icon: const Icon(Icons.edit),
            onPressed: _openEditProject,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProject,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_errorMessage != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Unable to refresh project details.\n\n'
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
            _buildDailyDiaryCard(context),
            const SizedBox(height: 16),
            _buildStatusManagementCard(context),
            const SizedBox(height: 16),
            _buildProjectInformation(context),
            const SizedBox(height: 16),
            _buildDatesCard(context),
            const SizedBox(height: 16),
            _buildStatusManagementCard(context),
            const SizedBox(height: 16),
            _buildProjectInformation(context),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _project.projectCode,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _project.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
            _StatusChip(status: _project.status),
          ],
        ),
      ),
    );
  }





  Widget _buildDailyDiaryCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.menu_book,
                  color: Colors.indigo,
                ),
                const SizedBox(width: 12),
                Text(
                  'Daily Site Diary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Record weather, manpower, work completed, safety notes and visitor log.',
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.menu_book),
                  label: const Text('Open Daily Site Diary'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DailySiteDiaryListScreen(
                          projectId: _project.id,
                          projectName: _project.name,
                          constructionSiteId: _project.constructionSiteId,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                OutlinedButton.icon(
                  icon: const Icon(Icons.fact_check),
                  label: const Text('Daily Progress Report'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DailyProgressListScreen(
                          projectId: _project.id,
                          projectName: _project.name,
                          repository: _dailyRepository,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                OutlinedButton.icon(
                  icon: const Icon(
                    Icons.warning_amber,
                    color: Colors.orange,
                  ),
                  label: const Text('Project Delays & Issues'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProjectDelayListScreen(
                          projectId: widget.project.id,
                          projectName: widget.project.name,
                          siteId: widget.project.constructionSiteId,
                        )
                      ),
                    );
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProjectInformation(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Project Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Project code',
              value: _project.projectCode,
            ),
            _InfoRow(
              label: 'Company',
              value: _project.companyName,
            ),

            _InfoRow(
              label: 'Construction Site',
              value: _project.constructionSiteName,
            ),

            _InfoRow(
              label: 'Contract Value',
              value: money(_project.contractValue),
            ),
            _InfoRow(
              label: 'Status',
              value: _statusLabel(_project.status),
            ),
            if (_project.description != null &&
                _project.description!.trim().isNotEmpty)
              _InfoRow(
                label: 'Description',
                value: _project.description!,
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
              'Project Dates',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Planned start',
              value: _formatDate(_project.plannedStartDate),
            ),
            _InfoRow(
              label: 'Planned end',
              value: _formatDate(_project.plannedEndDate),
            ),
            _InfoRow(
              label: 'Actual start',
              value: _formatDate(_project.actualStartDate),
            ),
            _InfoRow(
              label: 'Actual end',
              value: _formatDate(_project.actualEndDate),
            ),
            _InfoRow(
              label: 'Created',
              value: _formatDateTime(_project.createdAtUtc),
            ),
          ],
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

  static String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  static String _statusLabel(ProjectStatus status) {
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.status,
  });

  final ProjectStatus status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(_statusLabel(status)),
    );
  }

  String _statusLabel(ProjectStatus status) {
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
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}








