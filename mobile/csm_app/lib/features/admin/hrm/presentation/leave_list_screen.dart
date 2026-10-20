
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

  int get _pending =>
      _leaves
          .where((e) => e.status == LeaveStatus.pending)
          .length;

  int get _approved =>
      _leaves
          .where((e) => e.status == LeaveStatus.approved)
          .length;

  int get _rejected =>
      _leaves
          .where((e) => e.status == LeaveStatus.rejected)
          .length;

  double get _leaveDays =>
      _leaves.fold(0, (s, e) => s + e.numberOfDays);

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

      if (!mounted) return;

      setState(() {
        _leaves = leaves;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

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
        children: const [
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
          const Icon(Icons.error_outline, size: 48),
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
          Icon(Icons.event_busy_outlined, size: 64),
          SizedBox(height: 16),
          Center(
            child: Text('No leave requests found.'),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryCards(),
        const SizedBox(height: 16),
        ..._leaves.map(
              (leave) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildLeaveCard(context, leave),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.55,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _SummaryCard(
          title: 'Pending',
          value: '$_pending',
          icon: Icons.pending_actions,
          color: Colors.orange,
        ),
        _SummaryCard(
          title: 'Approved',
          value: '$_approved',
          icon: Icons.check_circle,
          color: Colors.green,
        ),
        _SummaryCard(
          title: 'Rejected',
          value: '$_rejected',
          icon: Icons.cancel,
          color: Colors.red,
        ),
        _SummaryCard(
          title: 'Leave Days',
          value: _leaveDays.toStringAsFixed(1),
          icon: Icons.event,
          color: Colors.blue,
        ),
      ],
    );
  }

  Future<void> _reviewLeave(
      Leave leave,
      LeaveStatus status,
      ) async {
    if (leave.status != LeaveStatus.pending) return;

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
            onChanged: (value) => remarks = value,
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(true),
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

    if (confirmed != true || !mounted) return;

    try {
      await widget.repository.review(
        leaveId: leave.id,
        status: status,
        remarks:
        remarks.trim().isEmpty ? null : remarks.trim(),
      );

      await _loadLeaves();

      if (!mounted) return;

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
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Leave review failed: $error'),
        ),
      );
    }
  }

  Future<void> _cancelLeave(Leave leave) async {
    if (leave.status != LeaveStatus.approved) return;

    var remarks = '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel Leave'),
          content: TextField(
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Cancellation Remarks',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => remarks = value,
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(false),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(true),
              child: const Text('Cancel Leave'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await widget.repository.cancel(
        leaveId: leave.id,
        remarks:
        remarks.trim().isEmpty ? null : remarks.trim(),
      );

      await _loadLeaves();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave cancelled successfully.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Leave cancellation failed: $error'),
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
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        leave.employeeName,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium,
                      ),
                      Text(
                        leave.employeeNumber,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium,
                      ),
                    ],
                  ),
                ),
                Chip(
                  backgroundColor:
                  _statusColor(leave.status)
                      .withValues(alpha: 0.12),
                  label: Text(
                    _statusLabel(leave.status),
                    style: TextStyle(
                      color: _statusColor(leave.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Leave Type',
              value: leave.leaveType,
            ),
            _InfoRow(
              label: 'Start Date',
              value: _formatDate(leave.startDate),
            ),
            _InfoRow(
              label: 'End Date',
              value: _formatDate(leave.endDate),
            ),
            _InfoRow(
              label: 'Days',
              value: leave.numberOfDays.toStringAsFixed(1),
            ),
            if (leave.reason != null &&
                leave.reason!.trim().isNotEmpty)
              _InfoRow(
                label: 'Reason',
                value: leave.reason!,
              ),
            if (leave.reviewedAtUtc != null) ...[
              const Divider(),
              _InfoRow(
                label: 'Reviewed',
                value: _formatDate(leave.reviewedAtUtc!),
              ),
            ],
            if (leave.reviewRemarks != null &&
                leave.reviewRemarks!.trim().isNotEmpty)
              _InfoRow(
                label: 'Remarks',
                value: leave.reviewRemarks!,
              ),
            if (leave.status == LeaveStatus.pending) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _reviewLeave(
                        leave,
                        LeaveStatus.rejected,
                      ),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _reviewLeave(
                        leave,
                        LeaveStatus.approved,
                      ),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
            if (leave.status == LeaveStatus.approved) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _cancelLeave(leave),
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

  Color _statusColor(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.pending:
        return Colors.orange;
      case LeaveStatus.approved:
        return Colors.green;
      case LeaveStatus.rejected:
        return Colors.red;
      case LeaveStatus.cancelled:
        return Colors.grey;
    }
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
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
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall,
            ),
            Text(title),
          ],
        ),
      ),
    );
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
            width: 110,
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