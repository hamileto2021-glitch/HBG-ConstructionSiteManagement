import 'package:flutter/material.dart';

import '../../../../../core/network/api_client.dart';
import '../../data/models/project_progress_dashboard.dart';
import '../../data/repositories/project_progress_repository.dart';

class ProjectProgressDashboardScreen extends StatefulWidget {
  const ProjectProgressDashboardScreen({
    super.key,
    required this.projectId,
  });

  final String projectId;

  @override
  State<ProjectProgressDashboardScreen> createState() =>
      _ProjectProgressDashboardScreenState();
}

class _ProjectProgressDashboardScreenState
    extends State<ProjectProgressDashboardScreen> {
  late final ProjectProgressRepository _repository;

  ProjectProgressDashboard? _dashboard;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = ProjectProgressRepository(ApiClient());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _repository.getDashboard(widget.projectId);

      if (!mounted) return;

      setState(() {
        _dashboard = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Color _healthColor(ProjectProgressDashboard p) {
    return p.openDelays == 0 ? Colors.green : Colors.orange;
  }

  Widget _buildCircularProgress(double progress) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: 1,
            strokeWidth: 12,
            color: Colors.grey.shade300,
          ),
          CircularProgressIndicator(
            value: progress / 100,
            strokeWidth: 12,
          ),
          Center(
            child: Text(
              '${progress.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectSummary(ProjectProgressDashboard p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PROJECT',
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 1.2,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          p.projectName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Chip(
          backgroundColor: _healthColor(p),
          label: Text(
            p.openDelays == 0 ? 'On Schedule' : 'Delayed',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Open Delays: ${p.openDelays} • Delay Days: ${p.totalDelayDays}',
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildKpiCard(
      String title,
      String value,
      IconData icon,
      Color color,
      ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSummary(ProjectProgressDashboard p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progress Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('Planned'),
                    const SizedBox(height: 6),
                    Text(
                      '${p.plannedProgress.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text('Actual'),
                    const SizedBox(height: 6),
                    Text(
                      '${p.actualProgress.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _dashboard == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Project Progress')),
        body: Center(child: Text(_error ?? 'No data available')),
      );
    }

    final p = _dashboard!;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;
    final isTablet = width >= 600 && width < 900;

    final kpiColumns = isDesktop ? 4 : (isTablet ? 3 : 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: isDesktop
                    ? Row(
                  children: [
                    _buildCircularProgress(p.actualProgress),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildProjectSummary(p),
                    ),
                  ],
                )
                    : Column(
                  children: [
                    _buildCircularProgress(p.actualProgress),
                    const SizedBox(height: 20),
                    _buildProjectSummary(p),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: kpiColumns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: isDesktop
                  ? 1.35
                  : isTablet
                  ? 1.0
                  : 0.85,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildKpiCard(
                  'Total Tasks',
                  '${p.totalTasks}',
                  Icons.assignment_outlined,
                  Colors.indigo,
                ),
                _buildKpiCard(
                  'Completed',
                  '${p.completedTasks}',
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildKpiCard(
                  'Remaining',
                  '${p.remainingTasks}',
                  Icons.pending_actions,
                  Colors.orange,
                ),
                _buildKpiCard(
                  'Open Delays',
                  '${p.openDelays}',
                  Icons.warning,
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildProgressSummary(p),
          ],
        ),
      ),
    );
  }
}