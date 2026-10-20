import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models/daily_progress.dart';
import '../data/repositories/daily_progress_repository.dart';
import 'daily_progress_edit_screen.dart';



class DailyProgressDetailScreen extends StatefulWidget {
  const DailyProgressDetailScreen({
    super.key,
    required this.logId,
    required this.repository,
  });

  final String logId;
  final DailyProgressRepository repository;

  @override
  State<DailyProgressDetailScreen> createState() =>
      _DailyProgressDetailScreenState();
}

class _DailyProgressDetailScreenState
    extends State<DailyProgressDetailScreen> {
  final DateFormat _date = DateFormat('yyyy-MM-dd');

  bool _isLoading = true;
  String? _error;
  DailyProgressLog? _log;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final log = await widget.repository.getById(widget.logId);

      if (!mounted) return;

      setState(() {
        _log = log;
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

  Future<void> _edit() async {
    if (_log == null) return;

    final updated = await Navigator.push<DailyProgressLog>(
      context,
      MaterialPageRoute(
        builder: (_) => DailyProgressEditScreen(
          log: _log!,
          repository: widget.repository,
        ),
      ),
    );

    if (updated != null) {
      setState(() {
        _log = updated;
      });

      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _log == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Daily Progress')),
        body: Center(child: Text(_error ?? 'Record not found')),
      );
    }

    final log = _log!;

    return Scaffold(
      appBar: AppBar(
        title: Text(log.logNumber),
        actions: [
          IconButton(
            onPressed: _edit,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoRow(
                    'Date',
                    _date.format(log.logDate),
                  ),
                  _InfoRow(
                    'Progress',
                    '${log.progressPercentage.toStringAsFixed(0)}%',
                  ),
                  _InfoRow(
                    'Weather',
                    log.weatherCondition ?? '-',
                  ),
                  _InfoRow(
                    'Temperature',
                    log.temperatureCelsius == null
                        ? '-'
                        : '${log.temperatureCelsius} °C',
                  ),
                  _InfoRow(
                    'Labor',
                    '${log.laborCount + log.contractorLaborCount}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _Section('Work Completed', log.workCompleted),
          _Section('Planned Next', log.workPlannedNext),
          _Section('Materials', log.materialsUsedSummary),
          _Section('Equipment', log.equipmentUsedSummary),
          _Section('Issues', log.issues),
          _Section('Safety', log.safetyNotes),
          _Section('Remarks', log.remarks),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.value);

  final String title;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(value!),
          ],
        ),
      ),
    );
  }
}