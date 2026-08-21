import 'package:flutter/material.dart';

import '../../data/models/phases/project_phase.dart';
import '../../data/repositories/project_phase_repository.dart';
import 'project_phase_edit_screen.dart';
import '../../data/repositories/work_task_repository.dart';
import '../tasks/work_task_list_screen.dart';
import '../../data/repositories/milestone_repository.dart';
import '../milestones/milestone_list_screen.dart';
import '../../data/models/milestones/milestone.dart';
import '../../data/models/work_task.dart';

class ProjectPhaseDetailsScreen extends StatefulWidget {
  const ProjectPhaseDetailsScreen({
    super.key,
    required this.phase,
    required this.repository,
  });

  final ProjectPhase phase;
  final ProjectPhaseRepository repository;

  @override
  State<ProjectPhaseDetailsScreen> createState() =>
      _ProjectPhaseDetailsScreenState();
}

class _ProjectPhaseDetailsScreenState
    extends State<ProjectPhaseDetailsScreen> {
  late ProjectPhase _phase;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isChangingStatus = false;
  bool _isLoadingMilestones = true;
  String? _milestoneErrorMessage;
  List<Milestone> _milestones = [];

  bool _isLoadingWorkTasks = true;
  String? _workTaskErrorMessage;
  List<WorkTask> _workTasks = [];

  @override
  void initState() {
    super.initState();
    _phase = widget.phase;
    _loadPhase();
    _loadMilestones();
    _loadWorkTasks();
  }

  Future<void> _loadMilestones() async {
    setState(() {
      _isLoadingMilestones = true;
      _milestoneErrorMessage = null;
    });

    try {
      final milestones = await MilestoneRepository().getAll(
        projectId: _phase.projectId,
        projectPhaseId: _phase.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _milestones = milestones;
        _isLoadingMilestones = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingMilestones = false;
        _milestoneErrorMessage = error.toString();
      });
    }
  }

  Future<void> _loadWorkTasks() async {
    setState(() {
      _isLoadingWorkTasks = true;
      _workTaskErrorMessage = null;
    });

    try {
      final tasks = await WorkTaskRepository().getAll(
        projectId: _phase.projectId,
        projectPhaseId: _phase.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _workTasks = tasks;
        _isLoadingWorkTasks = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingWorkTasks = false;
        _workTaskErrorMessage = error.toString();
      });
    }
  }

  Future<void> _loadPhase() async {
    try {
      final phase = await widget.repository.getById(
        widget.phase.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _phase = phase;
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

  Future<void> _openEditPhase() async {
    final updatedPhase =
        await Navigator.of(context).push<ProjectPhase>(
      MaterialPageRoute(
        builder: (_) => ProjectPhaseEditScreen(
          phase: _phase,
          repository: widget.repository,
        ),
      ),
    );

    if (updatedPhase != null && mounted) {
      setState(() {
        _phase = updatedPhase;
      });

      await _loadPhase();
    }
  }
  List<ProjectPhaseStatus> _allowedNextStatuses(
    ProjectPhaseStatus current,
  ) {
    switch (current) {
      case ProjectPhaseStatus.notStarted:
        return [
          ProjectPhaseStatus.inProgress,
          ProjectPhaseStatus.cancelled,
        ];

      case ProjectPhaseStatus.inProgress:
        return [
          ProjectPhaseStatus.onHold,
          ProjectPhaseStatus.completed,
          ProjectPhaseStatus.cancelled,
        ];

      case ProjectPhaseStatus.onHold:
        return [
          ProjectPhaseStatus.inProgress,
          ProjectPhaseStatus.completed,
          ProjectPhaseStatus.cancelled,
        ];

      case ProjectPhaseStatus.completed:
      case ProjectPhaseStatus.cancelled:
        return [];
    }
  }

  Future<void> _changePhaseStatus(
    ProjectPhaseStatus status,
  ) async {
    setState(() {
      _isChangingStatus = true;
    });

    try {
      final updatedPhase =
          await widget.repository.changeStatus(
        phaseId: _phase.id,
        status: status,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _phase = updatedPhase;
        _isChangingStatus = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Phase status changed to ${_statusLabel(status)}.',
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

  Future<void> _showStatusDialog(
    List<ProjectPhaseStatus> allowedStatuses,
  ) async {
    final selectedStatus =
        await showDialog<ProjectPhaseStatus>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text('Change Phase Status'),
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
      await _changePhaseStatus(selectedStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_phase.name),
        actions: [
          IconButton(
            tooltip: 'Edit Phase',
            icon: const Icon(Icons.edit),
            onPressed: _openEditPhase,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPhase,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_errorMessage != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Unable to refresh phase details.\n\n'
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
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildProgressCard(context),
            const SizedBox(height: 16),
            _buildStatusManagementCard(context),
            const SizedBox(height: 16),
            _buildMilestonesCard(context),
            const SizedBox(height: 16),
            _buildWorkTasksCard(context),
            const SizedBox(height: 16),
            _buildInformationCard(context),
            const SizedBox(height: 16),
            _buildDatesCard(context),
            const SizedBox(height: 16),
            _buildDatesCard(context),
          ],
        ),
      ),
    );

  }

   Widget _buildStatusManagementCard(BuildContext context) {
      final allowedStatuses =
          _allowedNextStatuses(_phase.status);

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
                'Phase Status',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Current status: ${_statusLabel(_phase.status)}',
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _isChangingStatus
                    ? null
                    : () => _showStatusDialog(
                        allowedStatuses,
                      ),
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
                    'Sequence ${_phase.sequence}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _phase.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
            Chip(
              label: Text(_statusLabel(_phase.status)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context) {
    final progress =
        (_phase.progressPercentage / 100).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${_phase.progressPercentage.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestonesCard(BuildContext context) {
    if (_isLoadingMilestones) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Milestones',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
          ),
        ),
      );
    }

    if (_milestoneErrorMessage != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Milestones',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'Unable to load milestones.\n\n'
                    '$_milestoneErrorMessage',
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadMilestones,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final total = _milestones.length;
    final completed = _milestones
        .where((milestone) => milestone.isCompleted)
        .length;
    final pending = total - completed;

    final progress = total == 0
        ? 0.0
        : completed / total;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Milestones',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Total: $total',
                  ),
                ),
                Text(
                  'Completed: $completed',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Pending: $pending',
            ),
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
                  '${(progress * 100).toStringAsFixed(0)}%',
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MilestoneListScreen(
                      projectId: _phase.projectId,
                      projectName: _phase.name,
                      projectPhaseId: _phase.id,
                      phaseName: _phase.name,
                      repository: MilestoneRepository(),
                    ),
                  ),
                );

                if (mounted) {
                  await _loadMilestones();
                }
              },
              icon: const Icon(Icons.flag),
              label: const Text('View Milestones'),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildWorkTasksCard(BuildContext context) {
    if (_isLoadingWorkTasks) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Work Tasks',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
          ),
        ),
      );
    }

    if (_workTaskErrorMessage != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Work Tasks',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'Unable to load work tasks.\n\n'
                    '$_workTaskErrorMessage',
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadWorkTasks,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final total = _workTasks.length;

    final completed = _workTasks
        .where(
          (task) => task.status == WorkTaskStatus.completed,
    )
        .length;

    final inProgress = _workTasks
        .where(
          (task) => task.status == WorkTaskStatus.inProgress,
    )
        .length;

    final notStarted = _workTasks
        .where(
          (task) => task.status == WorkTaskStatus.notStarted,
    )
        .length;

    final blocked = _workTasks
        .where(
          (task) => task.status == WorkTaskStatus.blocked,
    )
        .length;

    final onHold = _workTasks
        .where(
          (task) => task.status == WorkTaskStatus.onHold,
    )
        .length;

    final cancelled = _workTasks
        .where(
          (task) => task.status == WorkTaskStatus.cancelled,
    )
        .length;

    final progress = total == 0
        ? 0.0
        : _workTasks
        .map((task) => task.progressPercentage)
        .reduce((a, b) => a + b) /
        total /
        100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Work Tasks',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text('Total: $total'),
                ),
                Text('Completed: $completed'),
              ],
            ),
            const SizedBox(height: 8),
            Text('In Progress: $inProgress'),
            const SizedBox(height: 4),
            Text('Not Started: $notStarted'),
            if (blocked > 0) ...[
              const SizedBox(height: 4),
              Text('Blocked: $blocked'),
            ],
            if (onHold > 0) ...[
              const SizedBox(height: 4),
              Text('On Hold: $onHold'),
            ],
            if (cancelled > 0) ...[
              const SizedBox(height: 4),
              Text('Cancelled: $cancelled'),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WorkTaskListScreen(
                      projectId: _phase.projectId,
                      projectName: _phase.name,
                      projectPhaseId: _phase.id,
                      repository: WorkTaskRepository(),
                    ),
                  ),
                );

                if (mounted) {
                  await _loadWorkTasks();
                }
              },
              icon: const Icon(Icons.task_alt),
              label: const Text('View Work Tasks'),
            ),
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
              'Phase Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Phase name',
              value: _phase.name,
            ),
            _InfoRow(
              label: 'Sequence',
              value: _phase.sequence.toString(),
            ),
            _InfoRow(
              label: 'Status',
              value: _statusLabel(_phase.status),
            ),
            if (_phase.description != null &&
                _phase.description!.trim().isNotEmpty)
              _InfoRow(
                label: 'Description',
                value: _phase.description!,
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
              'Phase Dates',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Planned start',
              value: _formatDate(_phase.plannedStartDate),
            ),
            _InfoRow(
              label: 'Planned end',
              value: _formatDate(_phase.plannedEndDate),
            ),
            _InfoRow(
              label: 'Actual start',
              value: _formatDate(_phase.actualStartDate),
            ),
            _InfoRow(
              label: 'Actual end',
              value: _formatDate(_phase.actualEndDate),
            ),
            _InfoRow(
              label: 'Created',
              value: _formatDateTime(_phase.createdAtUtc),
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

  static String _statusLabel(ProjectPhaseStatus status) {
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
            child: Text(label),
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




