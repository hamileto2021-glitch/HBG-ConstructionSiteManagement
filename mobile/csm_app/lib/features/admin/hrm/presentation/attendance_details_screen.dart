import 'package:flutter/material.dart';

import '../data/models/attendance/attendance.dart';
import '../data/repositories/attendance_repository.dart';
import '../../../../core/location/location_service.dart';

class AttendanceDetailsScreen extends StatefulWidget {
  const AttendanceDetailsScreen({
    super.key,
    required this.attendance,
    required this.repository,
  });

  final Attendance attendance;
  final AttendanceRepository repository;

  @override
  State<AttendanceDetailsScreen> createState() =>
      _AttendanceDetailsScreenState();
}

class _AttendanceDetailsScreenState
    extends State<AttendanceDetailsScreen> {
  late Attendance _attendance;

  final LocationService _locationService = LocationService();

  bool _isCheckingOut = false;

  @override
  void initState() {
    super.initState();
    _attendance = widget.attendance;
  }
  Future<void> _checkOut() async {
    if (_attendance.checkOutAtUtc != null) {
      return;
    }

    setState(() {
      _isCheckingOut = true;
    });

    try {
      final position =
      await _locationService.getCurrentPosition();

      final updatedAttendance =
      await widget.repository.checkOut(
        attendanceId: _attendance.id,
        checkOutAtUtc: DateTime.now().toUtc(),
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _attendance = updatedAttendance;
        _isCheckingOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance check-out successful.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isCheckingOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Check-out failed: $error'),
        ),
      );
    }
  }

  Future<void> _approveAttendance() async {
    if (!_attendance.requiresApproval || _attendance.isApproved) {
      return;
    }

    try {
      final updatedAttendance =
      await widget.repository.approve(
        attendanceId: _attendance.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _attendance = updatedAttendance;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance approved successfully.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Approval failed: $error'),
        ),
      );
    }
  }

  Future<void> _showOverrideDialog() async {
    final messenger = ScaffoldMessenger.of(context);

    AttendanceStatus selectedStatus = _attendance.status;

    final checkInController = TextEditingController(
      text: _formatDateTimeForInput(
        _attendance.checkInAtUtc,
      ),
    );

    final checkOutController = TextEditingController(
      text: _formatDateTimeForInput(
        _attendance.checkOutAtUtc,
      ),
    );

    final reasonController = TextEditingController();
    final remarksController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Manual Override'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<AttendanceStatus>(
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Attendance status',
                        border: OutlineInputBorder(),
                      ),
                      items: AttendanceStatus.values
                          .map(
                            (status) => DropdownMenuItem(
                          value: status,
                          child: Text(_statusLabel(status)),
                        ),
                      )
                          .toList(),
                      onChanged: (status) {
                        if (status != null) {
                          setDialogState(() {
                            selectedStatus = status;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: checkInController,
                      decoration: const InputDecoration(
                        labelText: 'Check-in',
                        hintText: 'YYYY-MM-DD HH:mm',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: checkOutController,
                      decoration: const InputDecoration(
                        labelText: 'Check-out',
                        hintText: 'YYYY-MM-DD HH:mm',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: reasonController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Reason *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: remarksController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Remarks',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final reason =
                    reasonController.text.trim();

                    if (reason.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'A reason is required.',
                          ),
                        ),
                      );
                      return;
                    }

                    final checkIn =
                    _parseDateTimeInput(
                      checkInController.text,
                    );

                    if (checkIn == null) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Enter a valid check-in date and time.',
                          ),
                        ),
                      );
                      return;
                    }

                    final checkOut =
                    checkOutController.text.trim().isEmpty
                        ? null
                        : _parseDateTimeInput(
                      checkOutController.text,
                    );

                    if (checkOutController.text
                        .trim()
                        .isNotEmpty &&
                        checkOut == null) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Enter a valid check-out date and time.',
                          ),
                        ),
                      );
                      return;
                    }


                    try {
                      final updatedAttendance =
                      await widget.repository.overrideAttendance(
                        attendanceId: _attendance.id,
                        checkInAtUtc: checkIn.toUtc(),
                        checkOutAtUtc: checkOut?.toUtc(),
                        status: selectedStatus,
                        reason: reason,
                        remarks: remarksController.text.trim().isEmpty
                            ? null
                            : remarksController.text.trim(),
                      );

                      if (!mounted || !dialogContext.mounted) {
                        return;
                      }

                      Navigator.of(dialogContext).pop(true);

                      setState(() {
                        _attendance = updatedAttendance;
                      });

                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Attendance override successful.',
                          ),
                        ),
                      );


                    } catch (error) {
                      if (!mounted) {
                        return;
                      }

                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            'Override failed: $error',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Apply Override'),
                ),
              ],
            );
          },
        );
      },
    );



    if (result != true || !mounted) {
      return;
    }
  }
  String _formatDateTimeForInput(DateTime? date) {
    if (date == null) {
      return '';
    }

    final local = date.toLocal();

    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  DateTime? _parseDateTimeInput(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    return DateTime.tryParse(
      trimmed.replaceFirst(' ', 'T'),
    );
  }

  Widget _buildCheckOutCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Check-Out',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Capture your current GPS location and check out.',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isCheckingOut ? null : _checkOut,
                icon: _isCheckingOut
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.logout),
                label: Text(
                  _isCheckingOut
                      ? 'Checking Out...'
                      : 'Check Out',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderCard(context),
          if (_attendance.checkOutAtUtc == null) ...[
            const SizedBox(height: 16),
            _buildCheckOutCard(context),
          ],
          const SizedBox(height: 16),
          _buildAttendanceCard(context),
          const SizedBox(height: 16),
          _buildLocationCard(context),
          const SizedBox(height: 16),
          _buildHoursCard(context),
          const SizedBox(height: 16),
          _buildApprovalCard(context),
          if (_attendance.requiresApproval &&
              !_attendance.isApproved) ...[
            const SizedBox(height: 16),
            _buildApprovalActionCard(context),
          ],
          const SizedBox(height: 16),
          _buildOverrideActionCard(context),
          if (_attendance.manualOverrideReason != null ||
              _attendance.remarks != null) ...[
            const SizedBox(height: 16),
            _buildRemarksCard(context),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _attendance.employeeName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              _attendance.employeeNumber,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Status',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge,
                  ),
                ),
                Chip(
                  label: Text(
                    _statusLabel(_attendance.status),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Date: '
                  '${_formatDate(_attendance.attendanceDate)}',
            ),
            const SizedBox(height: 4),
            Text(
              'Source: '
                  '${_sourceLabel(_attendance.source)}',
            ),
            if (_attendance.shiftName != null) ...[
              const SizedBox(height: 4),
              Text(
                'Shift: ${_attendance.shiftName}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Times',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Check-in',
              value: _formatDateTime(
                _attendance.checkInAtUtc,
              ),
            ),
            const SizedBox(height: 10),
            _InfoRow(
              label: 'Check-out',
              value: _formatDateTime(
                _attendance.checkOutAtUtc,
              ),
            ),
            const SizedBox(height: 10),
            _InfoRow(
              label: 'Site',
              value: _attendance.siteName,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GPS & Geofence',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Check-in latitude',
              value: _formatDecimal(
                _attendance.checkInLatitude,
              ),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Check-in longitude',
              value: _formatDecimal(
                _attendance.checkInLongitude,
              ),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Check-in accuracy',
              value: _formatMeters(
                _attendance.checkInAccuracyMeters,
              ),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Check-in geofence',
              value: _attendance.isCheckInWithinGeofence
                  ? 'Within geofence'
                  : 'Outside geofence',
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Check-out latitude',
              value: _formatDecimal(
                _attendance.checkOutLatitude,
              ),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Check-out longitude',
              value: _formatDecimal(
                _attendance.checkOutLongitude,
              ),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Check-out accuracy',
              value: _formatMeters(
                _attendance.checkOutAccuracyMeters,
              ),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Check-out geofence',
              value: _attendance.isCheckOutWithinGeofence
                  ? 'Within geofence'
                  : 'Outside geofence',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoursCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Working Hours',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Regular hours',
              value:
              '${_attendance.regularHours} h',
            ),
            const SizedBox(height: 10),
            _InfoRow(
              label: 'Overtime hours',
              value:
              '${_attendance.overtimeHours} h',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Approval',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Requires approval',
              value: _attendance.requiresApproval
                  ? 'Yes'
                  : 'No',
            ),
            const SizedBox(height: 10),
            _InfoRow(
              label: 'Approved',
              value: _attendance.isApproved
                  ? 'Yes'
                  : 'No',
            ),
            if (_attendance.approvedBy != null) ...[
              const SizedBox(height: 10),
              _InfoRow(
                label: 'Approved by',
                value: _attendance.approvedBy!,
              ),
            ],
            if (_attendance.approvedAtUtc != null) ...[
              const SizedBox(height: 10),
              _InfoRow(
                label: 'Approved at',
                value: _formatDateTime(
                  _attendance.approvedAtUtc,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRemarksCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_attendance.manualOverrideReason != null) ...[
              Text(
                'Manual Override Reason',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _attendance.manualOverrideReason!,
              ),
            ],
            if (_attendance.manualOverrideReason != null &&
                _attendance.remarks != null)
              const SizedBox(height: 16),
            if (_attendance.remarks != null) ...[
              Text(
                'Remarks',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium,
              ),
              const SizedBox(height: 8),
              Text(_attendance.remarks!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalActionCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _approveAttendance,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Approve Attendance'),
          ),
        ),
      ),
    );
  }

  Widget _buildOverrideActionCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manual Override',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Correct attendance times or status when a manual adjustment is required.',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showOverrideDialog,
                icon: const Icon(Icons.edit_note),
                label: const Text('Manual Override'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.halfDay:
        return 'Half Day';
      case AttendanceStatus.leave:
        return 'Leave';
      case AttendanceStatus.holiday:
        return 'Holiday';
    }
  }

  String _sourceLabel(AttendanceSource source) {
    switch (source) {
      case AttendanceSource.mobileGps:
        return 'Mobile GPS';
      case AttendanceSource.biometric:
        return 'Biometric';
      case AttendanceSource.manual:
        return 'Manual';
      case AttendanceSource.imported:
        return 'Imported';
    }
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();

    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) {
      return 'Not recorded';
    }

    final local = date.toLocal();

    return '${_formatDate(local)} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  String _formatDecimal(double? value) {
    if (value == null) {
      return 'Not available';
    }

    return value.toStringAsFixed(6);
  }

  String _formatMeters(double? value) {
    if (value == null) {
      return 'Not available';
    }

    return '${value.toStringAsFixed(1)} m';
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 145,
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
    );
  }
}