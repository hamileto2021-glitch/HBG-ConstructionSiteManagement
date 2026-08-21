import 'package:flutter/material.dart';

import '../data/models/leave.dart';
import '../data/repositories/leave_repository.dart';
import '../data/repositories/employee_repository.dart';
import 'leave_create_screen.dart';

class LeaveListScreen extends StatefulWidget {
  const LeaveListScreen({
    super.key,
    required this.repository,
  });

  final LeaveRepository repository;

  @override
  State<LeaveListScreen> createState() =>
      _LeaveListScreenState();
}

class _LeaveListScreenState extends State<LeaveListScreen> {
  bool _isLoading = true;
  String? _error;
  List<Leave> _leaves = [];

  @override
  void initState() {
    super.initState();
    _loadLeaves();
  }

  Future<void> _loadLeaves() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final leaves = await widget.repository.getAll();

      if (!mounted) {
        return;
      }

      setState(() {
        _leaves = leaves;
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

  Future<void> _openCreateScreen() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LeaveCreateScreen(
          leaveRepository: widget.repository,
          employeeRepository: EmployeeRepository(),
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadLeaves();
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Management'),
        actions: [
          IconButton(
            tooltip: 'Create Leave',
            onPressed: _openCreateScreen,
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadLeaves,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadLeaves,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading && _leaves.isEmpty) {
      return ListView(
        children: [
          SizedBox(
            height: 300,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      );
    }

    if (_error != null && _leaves.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Unable to load leave requests.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadLeaves,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      );
    }

    if (_leaves.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 180),
          Center(
            child: Text(
              'No leave requests found.',
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _leaves.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildLeaveCard(
          context,
          _leaves[index],
        );
      },
    );
  }

  Future<void> _reviewLeave(
    Leave leave,
    LeaveStatus status,
  ) async {
    if (leave.status != LeaveStatus.pending) {
      return;
    }

    var remarks = '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            status == LeaveStatus.approved
                ? 'Approve Leave'
                : 'Reject Leave',
          ),
          content: TextField(
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Remarks',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              remarks = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(
                status == LeaveStatus.approved
                    ? 'Approve'
                    : 'Reject',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await widget.repository.review(
        leaveId: leave.id,
        status: status,
        remarks:
            remarks.trim().isEmpty
                ? null
                : remarks.trim(),
      );

      if (!mounted) {
        return;
      }

      await _loadLeaves();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == LeaveStatus.approved
                ? 'Leave approved successfully.'
                : 'Leave rejected successfully.',
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
            'Leave review failed: Cannot find an overload for "Replace" and the argument count: "3".',
          ),
        ),
      );
    }
  }
  Future<void> _cancelLeave(Leave leave) async {
    if (leave.status != LeaveStatus.approved) {
      return;
    }

    var remarks = '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel Leave'),
          content: TextField(
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Cancellation remarks',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              remarks = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Cancel Leave'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await widget.repository.cancel(
        leaveId: leave.id,
        remarks:
            remarks.trim().isEmpty
                ? null
                : remarks.trim(),
      );

      if (!mounted) {
        return;
      }

      await _loadLeaves();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Leave cancelled successfully.',
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
            'Leave cancellation failed: Cannot find an overload for "Replace" and the argument count: "3".',
          ),
        ),
      );
    }
  }
  Widget _buildLeaveCard(
    BuildContext context,
    Leave leave,
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
                const Icon(Icons.event_note_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    leave.employeeName,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge,
                  ),
                ),
                Chip(
                  label: Text(
                    _statusLabel(leave.status),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Employee',
              value: leave.employeeNumber,
            ),
            _InfoRow(
              label: 'Leave type',
              value: leave.leaveType,
            ),
            _InfoRow(
              label: 'Start date',
              value: _formatDate(leave.startDate),
            ),
            _InfoRow(
              label: 'End date',
              value: _formatDate(leave.endDate),
            ),
            _InfoRow(
              label: 'Days',
              value: leave.numberOfDays
                  .toStringAsFixed(1),
            ),
            if (leave.reason != null &&
                leave.reason!.trim().isNotEmpty)
              _InfoRow(
                label: 'Reason',
                value: leave.reason!,
              ),
            if (leave.status == LeaveStatus.pending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _reviewLeave(
                          leave,
                          LeaveStatus.rejected,
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
                        _reviewLeave(
                          leave,
                          LeaveStatus.approved,
                        );
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
            if (leave.status == LeaveStatus.approved) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _cancelLeave(leave);
                  },
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel Leave'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusLabel(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.pending:
        return 'Pending';
      case LeaveStatus.approved:
        return 'Approved';
      case LeaveStatus.rejected:
        return 'Rejected';
      case LeaveStatus.cancelled:
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
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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









