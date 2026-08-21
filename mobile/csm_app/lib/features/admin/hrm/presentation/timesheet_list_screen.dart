import 'package:flutter/material.dart';

import '../data/models/timesheet.dart';
import '../data/repositories/employee_repository.dart';
import '../data/repositories/timesheet_repository.dart';
import 'timesheet_create_screen.dart';

class TimesheetListScreen extends StatefulWidget {
  const TimesheetListScreen({
    super.key,
    required this.repository,
  });

  final TimesheetRepository repository;

  @override
  State<TimesheetListScreen> createState() =>
      _TimesheetListScreenState();
}

class _TimesheetListScreenState
    extends State<TimesheetListScreen> {
  bool _isLoading = true;
  String? _error;
  List<Timesheet> _timesheets = [];

  @override
  void initState() {
    super.initState();
    _loadTimesheets();
  }

  Future<void> _loadTimesheets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final timesheets =
          await widget.repository.getAll();

      if (!mounted) {
        return;
      }

      setState(() {
        _timesheets = timesheets;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _submitTimesheet(
    Timesheet timesheet,
  ) async {
    if (timesheet.status != TimesheetStatus.draft &&
        timesheet.status != TimesheetStatus.rejected) {
      return;
    }

    final remarks = await _remarksDialog(
      title: 'Submit Timesheet',
      label: 'Remarks',
      confirmText: 'Submit',
    );

    if (!mounted || remarks == null) {
      return;
    }

    try {
      await widget.repository.submit(
        timesheetId: timesheet.id,
        remarks: remarks,
      );

      if (!mounted) {
        return;
      }

      await _loadTimesheets();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Timesheet submitted successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Timesheet submission failed: $error',
          ),
        ),
      );
    }
  }

  Future<void> _reviewTimesheet(
    Timesheet timesheet,
    TimesheetStatus status,
  ) async {
    if (timesheet.status != TimesheetStatus.submitted) {
      return;
    }

    final remarks = await _remarksDialog(
      title: status == TimesheetStatus.approved
          ? 'Approve Timesheet'
          : 'Reject Timesheet',
      label: 'Remarks',
      confirmText: status == TimesheetStatus.approved
          ? 'Approve'
          : 'Reject',
    );

    if (!mounted || remarks == null) {
      return;
    }

    try {
      await widget.repository.review(
        timesheetId: timesheet.id,
        status: status,
        remarks: remarks,
      );

      if (!mounted) {
        return;
      }

      await _loadTimesheets();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == TimesheetStatus.approved
                ? 'Timesheet approved successfully.'
                : 'Timesheet rejected successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Timesheet review failed: $error',
          ),
        ),
      );
    }
  }

  Future<void> _cancelTimesheet(
    Timesheet timesheet,
  ) async {
    if (timesheet.status == TimesheetStatus.cancelled) {
      return;
    }

    final remarks = await _remarksDialog(
      title: 'Cancel Timesheet',
      label: 'Cancellation remarks',
      confirmText: 'Cancel Timesheet',
    );

    if (!mounted || remarks == null) {
      return;
    }

    try {
      await widget.repository.cancel(
        timesheetId: timesheet.id,
        remarks: remarks,
      );

      if (!mounted) {
        return;
      }

      await _loadTimesheets();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Timesheet cancelled successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Timesheet cancellation failed: $error',
          ),
        ),
      );
    }
  }

  Future<String?> _remarksDialog({
    required String title,
    required String label,
    required String confirmText,
  }) async {
    var remarks = '';

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            maxLines: 4,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              remarks = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(
                  remarks.trim(),
                );
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openCreateScreen() async {
    final result =
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TimesheetCreateScreen(
          employeeRepository: EmployeeRepository(),
          timesheetRepository: widget.repository,
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadTimesheets();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timesheet Management'),
        actions: [
          IconButton(
            tooltip: 'Create Timesheet',
            onPressed: _isLoading
                ? null
                : _openCreateScreen,
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading
                ? null
                : _loadTimesheets,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTimesheets,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading && _timesheets.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 300),
          Center(
            child: CircularProgressIndicator(),
          ),
        ],
      );
    }

    if (_error != null && _timesheets.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          const Icon(
            Icons.error_outline,
            size: 48,
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Unable to load timesheets.',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadTimesheets,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      );
    }

    if (_timesheets.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 180),
          Center(
            child: Text(
              'No timesheets found.',
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _timesheets.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildTimesheetCard(
          context,
          _timesheets[index],
        );
      },
    );
  }

  Widget _buildTimesheetCard(
    BuildContext context,
    Timesheet timesheet,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.access_time_outlined,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    timesheet.employeeName,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge,
                  ),
                ),
                Chip(
                  label: Text(
                    _statusLabel(timesheet.status),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Employee',
              value: timesheet.employeeNumber,
            ),
            _InfoRow(
              label: 'Period',
              value:
                  '${_formatDate(timesheet.periodStartDate)}'
                  ' - '
                  '${_formatDate(timesheet.periodEndDate)}',
            ),
            _InfoRow(
              label: 'Regular hours',
              value: timesheet.regularHours
                  .toStringAsFixed(2),
            ),
            _InfoRow(
              label: 'Overtime hours',
              value: timesheet.overtimeHours
                  .toStringAsFixed(2),
            ),
            _InfoRow(
              label: 'Total hours',
              value: timesheet.totalHours
                  .toStringAsFixed(2),
            ),
            if (timesheet.remarks != null &&
                timesheet.remarks!.trim().isNotEmpty)
              _InfoRow(
                label: 'Remarks',
                value: timesheet.remarks!,
              ),
            if (timesheet.approvalRemarks != null &&
                timesheet.approvalRemarks!
                    .trim()
                    .isNotEmpty)
              _InfoRow(
                label: 'Review remarks',
                value: timesheet.approvalRemarks!,
              ),
            if (timesheet.status ==
                    TimesheetStatus.draft ||
                timesheet.status ==
                    TimesheetStatus.rejected) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    _submitTimesheet(timesheet);
                  },
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Submit Timesheet'),
                ),
              ),
            ],
            if (timesheet.status ==
                TimesheetStatus.submitted) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _reviewTimesheet(
                          timesheet,
                          TimesheetStatus.rejected,
                        );
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        _reviewTimesheet(
                          timesheet,
                          TimesheetStatus.approved,
                        );
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
            if (timesheet.status !=
                    TimesheetStatus.cancelled &&
                timesheet.status !=
                    TimesheetStatus.approved) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _cancelTimesheet(timesheet);
                  },
                  icon: const Icon(
                    Icons.cancel_outlined,
                  ),
                  label: const Text('Cancel Timesheet'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusLabel(TimesheetStatus status) {
    switch (status) {
      case TimesheetStatus.draft:
        return 'Draft';
      case TimesheetStatus.submitted:
        return 'Submitted';
      case TimesheetStatus.approved:
        return 'Approved';
      case TimesheetStatus.rejected:
        return 'Rejected';
      case TimesheetStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();

    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge,
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}


