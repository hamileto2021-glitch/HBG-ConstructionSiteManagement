import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models/daily_progress.dart';
import '../data/repositories/daily_progress_repository.dart';
import 'daily_progress_create_screen.dart';
import 'daily_progress_detail_screen.dart';


class DailyProgressListScreen extends StatefulWidget {
  const DailyProgressListScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.repository,
  });

  final String projectId;
  final String projectName;
  final DailyProgressRepository repository;

  @override
  State<DailyProgressListScreen> createState() =>
      _DailyProgressListScreenState();
}

class _DailyProgressListScreenState
    extends State<DailyProgressListScreen> {
  final DateFormat _date = DateFormat('yyyy-MM-dd');

  bool _isLoading = true;
  String? _error;
  List<DailyProgressLog> _logs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await widget.repository.getAll(
        projectId: widget.projectId,
      );

      if (!mounted) return;

      setState(() {
        _logs = result;
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
  Future<void> _openCreate() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DailyProgressCreateScreen(
          projectId: widget.projectId,
          projectName: widget.projectName,
          repository: widget.repository,
        ),
      ),
    );

    if (created == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.projectName} · Site Diary'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('Daily Progress'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!),
            ),
          ),
        ],
      );
    }

    if (_logs.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 80),
          Icon(Icons.menu_book_outlined, size: 64),
          SizedBox(height: 16),
          Center(
            child: Text(
              'No daily progress logs available.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _logs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final updated = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => DailyProgressDetailScreen(
                logId: _logs[index].id,
                repository: widget.repository,
              ),
            ),
          );

          if (updated == true) {
            await _load();
          }
        },
        child: _LogCard(
          log: _logs[index],
          date: _date,
        ),
      )
    );
  }
}

class _LogCard extends StatelessWidget {
  const _LogCard({
    required this.log,
    required this.date,
  });

  final DailyProgressLog log;
  final DateFormat date;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.logNumber,
                        style:
                        Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date.format(log.logDate),
                        style:
                        Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    '${log.progressPercentage.toStringAsFixed(0)}%',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.cloud, size: 18),
                const SizedBox(width: 6),
                Text(log.weatherCondition ?? 'N/A'),
                const Spacer(),
                Text(
                  log.temperatureCelsius == null
                      ? '--'
                      : '${log.temperatureCelsius!.toStringAsFixed(1)}°C',
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                const Icon(Icons.groups, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Labor: ${log.laborCount + log.contractorLaborCount}',
                ),
              ],
            ),

            if (log.workCompleted?.isNotEmpty ?? false) ...[
              const Divider(height: 24),
              Text(
                'Work Completed',
                style:
                Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(log.workCompleted!),
            ],

            if (log.workPlannedNext?.isNotEmpty ?? false) ...[
              const SizedBox(height: 14),
              Text(
                'Planned Next',
                style:
                Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(log.workPlannedNext!),
            ],

            if (log.materialsUsedSummary?.isNotEmpty ??
                false) ...[
              const SizedBox(height: 14),
              Text(
                'Materials',
                style:
                Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(log.materialsUsedSummary!),
            ],

            if (log.equipmentUsedSummary?.isNotEmpty ??
                false) ...[
              const SizedBox(height: 14),
              Text(
                'Equipment',
                style:
                Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(log.equipmentUsedSummary!),
            ],

            if (log.delays?.isNotEmpty ?? false) ...[
              const SizedBox(height: 14),
              Text(
                'Delays',
                style:
                Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(log.delays!),
            ],

            if (log.issues?.isNotEmpty ?? false) ...[
              const SizedBox(height: 14),
              Text(
                'Issues',
                style:
                Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(log.issues!),
            ],

            if (log.safetyNotes?.isNotEmpty ?? false) ...[
              const SizedBox(height: 14),
              Text(
                'Safety',
                style:
                Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(log.safetyNotes!),
            ],

            if (log.remarks?.isNotEmpty ?? false) ...[
              const SizedBox(height: 14),
              Text(
                'Remarks',
                style:
                Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(log.remarks!),
            ],
          ],
        ),
      ),
    );
  }
}