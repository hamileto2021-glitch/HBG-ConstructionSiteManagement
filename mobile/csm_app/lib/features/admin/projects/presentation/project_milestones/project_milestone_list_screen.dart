import 'package:flutter/material.dart';

import '../../../../../responsive/breakpoints.dart';
import '../../../../../shared/widgets/adaptive_data_table.dart';
import '../../data/models/project_milestone.dart';
import '../../data/repositories/project_milestone_repository.dart';
import 'project_milestone_create_screen.dart';
import 'project_milestone_details_screen.dart';



class ProjectMilestoneListScreen extends StatefulWidget {
  const ProjectMilestoneListScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  final String projectId;
  final String projectName;

  @override
  State<ProjectMilestoneListScreen> createState() =>
      _ProjectMilestoneListScreenState();
}

class _ProjectMilestoneListScreenState
    extends State<ProjectMilestoneListScreen> {
  final _repository = ProjectMilestoneRepository();

  bool _loading = true;
  String? _error;
  List<ProjectMilestone> _milestones = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _repository.getAll();

      _milestones = data
          .where((e) => e.projectId == widget.projectId)
          .toList();
    } catch (e) {
      _error = e.toString();
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  int get _completed =>
      _milestones
          .where((e) => e.status == MilestoneStatus.completed)
          .length;

  int get _delayed =>
      _milestones
          .where((e) => e.status == MilestoneStatus.delayed)
          .length;

  double get _averageProgress {
    if (_milestones.isEmpty) return 0;

    final total = _milestones.fold<double>(
      0,
          (sum, e) => sum + e.progressPercentage,
    );

    return total / _milestones.length;
  }

  String _status(MilestoneStatus status) {
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

  String _date(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.projectName} Milestones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final created =
              await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ProjectMilestoneCreateScreen(
                        projectId: widget.projectId,
                        repository: _repository,
                      ),
                ),
              );

              if (created == true) {
                _load();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(_error!),
              ),
            ),
          ),
        ],
      );
    }

    if (_milestones.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 200),
          Center(
            child: Text('No milestones found.'),
          ),
        ],
      );
    }

    if (AppBreakpoints.isDesktop(context)) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics:
              const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.7,
              children: [
                _MilestoneKpiCard(
                  title: 'Milestones',
                  value: '${_milestones.length}',
                  icon: Icons.flag,
                  color: Colors.blue,
                ),
                _MilestoneKpiCard(
                  title: 'Completed',
                  value: '$_completed',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                _MilestoneKpiCard(
                  title: 'Delayed',
                  value: '$_delayed',
                  icon: Icons.warning,
                  color: Colors.red,
                ),
                _MilestoneKpiCard(
                  title: 'Progress',
                  value:
                  '${_averageProgress.toStringAsFixed(0)}%',
                  icon: Icons.trending_up,
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AdaptiveDataTable(
              columns: [
                AdaptiveColumn(
                  label: 'Milestone',
                  value: (r) => r['name'],
                ),
                AdaptiveColumn(
                  label: 'Planned',
                  value: (r) => r['planned'],
                ),
                AdaptiveColumn(
                  label: 'Actual',
                  value: (r) => r['actual'],
                ),
                AdaptiveColumn(
                  label: 'Progress',
                  value: (r) => r['progress'],
                  numeric: true,
                ),
                AdaptiveColumn(
                  label: 'Status',
                  value: (r) => r['status'],
                ),
              ],
              rows: _milestones.map((m) {
                return {
                  'name': m.name,
                  'planned': _date(m.plannedDate),
                  'actual': m.actualDate == null
                      ? '-'
                      : _date(m.actualDate!),
                  'progress':
                  '${m.progressPercentage.toStringAsFixed(0)}%',
                  'status': _status(m.status),
                };
              }).toList(),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _milestones.length,
      itemBuilder: (context, index) {
        final milestone = _milestones[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProjectMilestoneDetailsScreen(
                    milestone: milestone,
                    repository: _repository,
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
                      Expanded(
                        child: Text(
                          milestone.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Chip(
                        label: Text(_status(milestone.status)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Planned: ${_date(milestone.plannedDate)}'),
                  Text(
                    'Progress: ${milestone.progressPercentage.toStringAsFixed(0)}%',
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: milestone.progressPercentage / 100,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MilestoneKpiCard extends StatelessWidget {
  const _MilestoneKpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              backgroundColor:
              color.withValues(alpha: 0.12),
              child: Icon(icon, color: color),
            ),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
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