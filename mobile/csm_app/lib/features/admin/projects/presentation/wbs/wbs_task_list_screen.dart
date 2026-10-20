import 'package:flutter/material.dart';

import '../../../../../responsive/breakpoints.dart';
import '../../../../../shared/widgets/adaptive_data_table.dart';
import '../../data/models/wbs_task.dart';
import '../../data/repositories/wbs_task_repository.dart';
import 'wbs_task_create_screen.dart';
import 'wbs_task_detail_screen.dart';

class WbsTaskListScreen extends StatefulWidget {
  const WbsTaskListScreen({
    super.key,
    required this.repository,
  });

  final WbsTaskRepository repository;

  @override
  State<WbsTaskListScreen> createState() =>
      _WbsTaskListScreenState();
}

class _WbsTaskListScreenState
    extends State<WbsTaskListScreen> {
  final List<WbsTask> _tasks = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tasks = await widget.repository.getAll();

      if (!mounted) return;

      setState(() {
        _tasks
          ..clear()
          ..addAll(tasks);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  int get _completed =>
      _tasks
          .where((e) => e.status == WbsTaskStatus.completed)
          .length;

  int get _inProgress =>
      _tasks
          .where((e) => e.status == WbsTaskStatus.inProgress)
          .length;

  int get _pending =>
      _tasks
          .where((e) => e.status == WbsTaskStatus.notStarted)
          .length;

  double get _averageProgress {
    if (_tasks.isEmpty) return 0;

    final total = _tasks.fold<double>(
      0,
          (sum, e) => sum + e.progressPercentage,
    );

    return total / _tasks.length;
  }

  String _date(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  String _status(WbsTaskStatus status) {
    switch (status) {
      case WbsTaskStatus.notStarted:
        return 'Not Started';
      case WbsTaskStatus.inProgress:
        return 'In Progress';
      case WbsTaskStatus.onHold:
        return 'On Hold';
      case WbsTaskStatus.completed:
        return 'Completed';
      case WbsTaskStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _statusColor(WbsTaskStatus status) {
    switch (status) {
      case WbsTaskStatus.notStarted:
        return Colors.orange;
      case WbsTaskStatus.inProgress:
        return Colors.blue;
      case WbsTaskStatus.onHold:
        return Colors.grey;
      case WbsTaskStatus.completed:
        return Colors.green;
      case WbsTaskStatus.cancelled:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WBS Task Board'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
            _isLoading ? null : _loadTasks,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WbsTaskCreateScreen(
                    repository: widget.repository,
                  ),
                ),
              );

              _loadTasks();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTasks,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading && _tasks.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 300),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null && _tasks.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 220),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 56,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loadTasks,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildKpiHeader(),
        Expanded(
          child: AppBreakpoints.isDesktop(context)
              ? _buildDesktopTable()
              : _buildMobileList(),
        ),
      ],
    );
  }

  Widget _buildKpiHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _KpiCard(
              title: 'Completed',
              value: _completed.toString(),
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _KpiCard(
              title: 'In Progress',
              value: _inProgress.toString(),
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _KpiCard(
              title: 'Pending',
              value: _pending.toString(),
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _KpiCard(
              title: 'Avg %',
              value:
              '${_averageProgress.toStringAsFixed(0)}%',
              color: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AdaptiveDataTable(
        columns: [
          AdaptiveColumn(
            label: 'Code',
            value: (r) => r['code'] as String,
          ),
          AdaptiveColumn(
            label: 'Task',
            value: (r) => r['name'] as String,
          ),
          AdaptiveColumn(
            label: 'Status',
            value: (r) => r['status'] as String,
          ),
          AdaptiveColumn(
            label: 'Progress',
            value: (r) => r['progress'] as String,
          ),
          AdaptiveColumn(
            label: 'Finish',
            value: (r) => r['finish'] as String,
          ),
        ],
        rows: _tasks.map((task) {
          return {
            'item': task,
            'code': task.taskCode,
            'name': task.name,
            'status': _status(task.status),
            'progress':
            '${task.progressPercentage.toStringAsFixed(0)}%',
            'finish': _date(task.plannedFinishDate),
          };
        }).toList(),
        onRowTap: (row) {
          final task = row['item'] as WbsTask;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WbsTaskDetailScreen(
                task: task,
                repository: widget.repository,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileList() {
    if (_tasks.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 200),
          Center(child: Text('No WBS Tasks found')),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];

        return Card(
          margin:
          const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius:
            BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      WbsTaskDetailScreen(
                        task: task,
                        repository:
                        widget.repository,
                      ),
                ),
              );
            },
            child: Padding(
              padding:
              const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium,
                        ),
                      ),
                      Chip(
                        backgroundColor:
                        _statusColor(
                            task.status),
                        label: Text(
                          _status(task.status),
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Code: ${task.taskCode}',
                  ),
                  Text(
                    'Finish: ${_date(task.plannedFinishDate)}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Progress ${task.progressPercentage.toStringAsFixed(0)}%',
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value:
                    task.progressPercentage /
                        100,
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

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding:
        const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 10,
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}