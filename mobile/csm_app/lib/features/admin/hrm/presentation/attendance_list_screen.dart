import 'package:flutter/material.dart';

import '../data/models/attendance/attendance.dart';
import '../data/repositories/attendance_repository.dart';
import 'attendance_details_screen.dart';
import '../../../../core/location/location_service.dart';
import 'attendance_check_in_screen.dart';
import '../data/repositories/employee_repository.dart';
import '../../sites/data/repositories/site_repository.dart';

class AttendanceListScreen extends StatefulWidget {
  const AttendanceListScreen({
    super.key,
    required this.repository,
  });

  final AttendanceRepository repository;

  @override
  State<AttendanceListScreen> createState() =>
      _AttendanceListScreenState();
}

class _AttendanceListScreenState
    extends State<AttendanceListScreen> {
  List<Attendance> _attendances = [];
  bool _isLoading = false;
  String? _errorMessage;

  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _loadAttendances();
  }

  Future<void> _loadAttendances() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final attendances =
      await widget.repository.getAll(
        fromDate: _fromDate,
        toDate: _toDate,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _attendances = attendances;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _selectFromDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _fromDate = selected;

      if (_toDate != null &&
          _toDate!.isBefore(selected)) {
        _toDate = null;
      }
    });

    await _loadAttendances();
  }

  Future<void> _selectToDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _toDate ?? _fromDate ?? DateTime.now(),
      firstDate: _fromDate ?? DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _toDate = selected;
    });

    await _loadAttendances();
  }

  Future<void> _refresh() async {
    await _loadAttendances();
  }

  void _clearDateFilters() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });

    _loadAttendances();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
            tooltip: 'Check In',
            onPressed: () async {
              final result =
              await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => AttendanceCheckInScreen(
                    attendanceRepository: widget.repository,
                    employeeRepository: EmployeeRepository(),
                    siteRepository: SiteRepository(),
                    locationService: LocationService(),
                  ),
                ),
              );

              if (result == true && mounted) {
                await _loadAttendances();
              }
            },
            icon: const Icon(Icons.login),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildFilterCard(context),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Unable to load attendance.\n\n'
                        '$_errorMessage',
                  ),
                ),
              ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: LinearProgressIndicator(),
              ),
            if (!_isLoading &&
                _errorMessage == null &&
                _attendances.isEmpty)
              _buildEmptyCard(context),
            if (_attendances.isNotEmpty)
              ..._attendances.map(
                    (attendance) =>
                    Padding(
                      padding:
                      const EdgeInsets.only(bottom: 12),
                      child: _buildAttendanceCard(
                        context,
                        attendance,
                      ),
                    ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              'Date Filters',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateFilterButton(
                    label: 'From',
                    date: _fromDate,
                    onPressed: _selectFromDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateFilterButton(
                    label: 'To',
                    date: _toDate,
                    onPressed: _selectToDate,
                  ),
                ),
              ],
            ),
            if (_fromDate != null ||
                _toDate != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _clearDateFilters,
                  icon: const Icon(Icons.clear),
                  label: const Text(
                    'Clear Filters',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No attendance records found.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge,
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(
      BuildContext context,
      Attendance attendance,
      ) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AttendanceDetailsScreen(
                attendance: attendance,
                repository: widget.repository,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      attendance.employeeName,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium,
                    ),
                  ),
                  Chip(
                    label: Text(
                      _statusLabel(attendance.status),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                attendance.employeeNumber,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Site: ${attendance.siteName}',
              ),
              const SizedBox(height: 4),
              Text(
                'Date: '
                    '${_formatDate(attendance.attendanceDate)}',
              ),
              const SizedBox(height: 4),
              Text(
                'Check-in: '
                    '${_formatDateTime(attendance.checkInAtUtc)}',
              ),
              const SizedBox(height: 4),
              Text(
                'Check-out: '
                    '${_formatDateTime(attendance.checkOutAtUtc)}',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Regular: '
                          '${attendance.regularHours} h',
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Overtime: '
                          '${attendance.overtimeHours} h',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    attendance.isApproved
                        ? Icons.verified
                        : Icons.pending_actions,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    attendance.isApproved
                        ? 'Approved'
                        : attendance.requiresApproval
                        ? 'Requires approval'
                        : 'Approval not required',
                  ),
                ],
              ),
            ],
          ),
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

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) {
      return 'Not checked out';
    }

    final local = date.toLocal();

    return '${_formatDate(local)} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

class _DateFilterButton extends StatelessWidget {
  const _DateFilterButton({
    required this.label,
    required this.date,
    required this.onPressed,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.calendar_today),
      label: Text(
        date == null
            ? label
            : '$label: ${_formatDate(date!)}',
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}