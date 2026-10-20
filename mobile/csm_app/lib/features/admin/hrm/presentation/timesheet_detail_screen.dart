import 'package:flutter/material.dart';

import '../data/models/timesheet.dart';
import '../data/repositories/timesheet_repository.dart';

class TimesheetDetailScreen extends StatefulWidget {
  const TimesheetDetailScreen({
    super.key,
    required this.timesheet,
    required this.repository,
  });

  final Timesheet timesheet;
  final TimesheetRepository repository;

  @override
  State<TimesheetDetailScreen> createState() =>
      _TimesheetDetailScreenState();
}

class _TimesheetDetailScreenState
    extends State<TimesheetDetailScreen> {
  late Timesheet _timesheet;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _timesheet = widget.timesheet;
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);

    try {
      final updated = await widget.repository.submit(
        timesheetId: _timesheet.id,
      );

      setState(() => _timesheet = updated);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Timesheet submitted successfully.'),
        ),
      );
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approve() async {
    setState(() => _isLoading = true);

    try {
      final updated = await widget.repository.review(
        timesheetId: _timesheet.id,
        status: TimesheetStatus.approved,
      );

      setState(() => _timesheet = updated);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Timesheet approved.')),
      );
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reject() async {
    setState(() => _isLoading = true);

    try {
      final updated = await widget.repository.review(
        timesheetId: _timesheet.id,
        status: TimesheetStatus.rejected,
      );

      setState(() => _timesheet = updated);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Timesheet rejected.')),
      );
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancel() async {
    setState(() => _isLoading = true);

    try {
      final updated = await widget.repository.cancel(
        timesheetId: _timesheet.id,
      );

      setState(() => _timesheet = updated);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Timesheet cancelled.')),
      );
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(Object e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timesheet Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _timesheet.employeeName,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(_timesheet.employeeNumber),
          const SizedBox(height: 20),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _row(
                    'Period',
                    '${_format(_timesheet.periodStartDate)} - ${_format(_timesheet.periodEndDate)}',
                  ),
                  const Divider(),
                  _row(
                    'Regular Hours',
                    _timesheet.regularHours.toStringAsFixed(2),
                  ),
                  _row(
                    'Overtime Hours',
                    _timesheet.overtimeHours.toStringAsFixed(2),
                  ),
                  _row(
                    'Total Hours',
                    _timesheet.totalHours.toStringAsFixed(2),
                    bold: true,
                  ),
                  const Divider(),
                  _row(
                    'Status',
                    _timesheet.status.name.toUpperCase(),
                    bold: true,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          ..._buildActions(),
        ],
      ),
    );
  }

  List<Widget> _buildActions() {
    switch (_timesheet.status) {
      case TimesheetStatus.draft:
        return [
          FilledButton.icon(
            onPressed: _isLoading ? null : _submit,
            icon: const Icon(Icons.send),
            label: const Text('Submit Timesheet'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _cancel,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancel'),
          ),
        ];

      case TimesheetStatus.submitted:
        return [
          FilledButton.icon(
            onPressed: _isLoading ? null : _approve,
            icon: const Icon(Icons.check_circle),
            label: const Text('Approve'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _reject,
            icon: const Icon(Icons.close),
            label: const Text('Reject'),
          ),
        ];

      default:
        return [
          Card(
            color: Colors.green.shade50,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.verified, color: Colors.green),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This timesheet is completed and is read-only.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ];
    }
  }

  Widget _row(
      String label,
      String value, {
        bool bold = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(
              fontWeight:
              bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _format(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}