import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  final DateFormat _date = DateFormat('yyyy-MM-dd');

  int get _presentCount =>
      _attendances
          .where((a) => a.status == AttendanceStatus.present)
          .length;

  int get _lateCount =>
      _attendances
          .where((a) => a.status == AttendanceStatus.late)
          .length;

  double get _regularHours =>
      _attendances.fold(0, (s, a) => s + a.regularHours);

  double get _overtimeHours =>
      _attendances.fold(0, (s, a) => s + a.overtimeHours);

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
      final attendances = await widget.repository.getAll(
        fromDate: _fromDate,
        toDate: _toDate,
      );

      if (!mounted) return;

      setState(() {
        _attendances = attendances;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async => _loadAttendances();

  Future<void> _selectFromDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected == null) return;

    setState(() {
      _fromDate = selected;
      if (_toDate != null && _toDate!.isBefore(selected)) {
        _toDate = null;
      }
    });

    _loadAttendances();
  }

  Future<void> _selectToDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _toDate ?? _fromDate ?? DateTime.now(),
      firstDate: _fromDate ?? DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected == null) return;

    setState(() => _toDate = selected);
    _loadAttendances();
  }

  void _clearFilters() {
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
            icon: const Icon(Icons.login),
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

              if (result == true) {
                _loadAttendances();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildFilterCard(),
            const SizedBox(height: 16),
            _buildSummaryCards(),
            const SizedBox(height: 16),
            if (_isLoading)
              const LinearProgressIndicator(),
            if (_errorMessage != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_errorMessage!),
                ),
              ),
            if (!_isLoading &&
                _errorMessage == null &&
                _attendances.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('No attendance records found.'),
                  ),
                ),
              ),
            ..._attendances.map(
                  (a) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildAttendanceCard(a),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _SummaryCard(
          title: 'Present',
          value: '$_presentCount',
          icon: Icons.check_circle,
          color: Colors.green,
        ),
        _SummaryCard(
          title: 'Late',
          value: '$_lateCount',
          icon: Icons.schedule,
          color: Colors.orange,
        ),
        _SummaryCard(
          title: 'Regular Hrs',
          value: _regularHours.toStringAsFixed(1),
          icon: Icons.access_time,
          color: Colors.blue,
        ),
        _SummaryCard(
          title: 'Overtime',
          value: _overtimeHours.toStringAsFixed(1),
          icon: Icons.more_time,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildFilterCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Date Filters',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateButton(
                    label: 'From',
                    date: _fromDate,
                    onTap: _selectFromDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateButton(
                    label: 'To',
                    date: _toDate,
                    onTap: _selectToDate,
                  ),
                ),
              ],
            ),
            if (_fromDate != null || _toDate != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear Filters'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(Attendance attendance) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attendance.employeeName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(attendance.employeeNumber),
                      ],
                    ),
                  ),
                  Chip(
                    backgroundColor: _statusColor(
                      attendance.status,
                    ).withValues(alpha: 0.12),
                    label: Text(
                      _statusLabel(attendance.status),
                      style: TextStyle(
                        color: _statusColor(attendance.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_city, size: 18),
                  const SizedBox(width: 6),
                  Expanded(child: Text(attendance.siteName)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18),
                  const SizedBox(width: 6),
                  Text(_date.format(attendance.attendanceDate)),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _timeTile(
                      'Check In',
                      attendance.checkInAtUtc,
                    ),
                  ),
                  Expanded(
                    child: _timeTile(
                      'Check Out',
                      attendance.checkOutAtUtc,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Regular: ${attendance.regularHours.toStringAsFixed(1)} h',
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'OT: ${attendance.overtimeHours.toStringAsFixed(1)} h',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    attendance.isApproved
                        ? Icons.verified
                        : Icons.pending_actions,
                    color: attendance.isApproved
                        ? Colors.green
                        : Colors.orange,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    attendance.isApproved
                        ? 'Approved'
                        : attendance.requiresApproval
                        ? 'Requires Approval'
                        : 'Approval Not Required',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeTile(String title, DateTime? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          value == null
              ? '--'
              : '${value.toLocal().hour.toString().padLeft(2, '0')}:${value.toLocal().minute.toString().padLeft(2, '0')}',
        ),
      ],
    );
  }

  Color _statusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.late:
        return Colors.orange;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.halfDay:
        return Colors.blue;
      case AttendanceStatus.leave:
        return Colors.purple;
      case AttendanceStatus.holiday:
        return Colors.teal;
    }
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(title),
          ],
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.calendar_month),
      label: Text(
        date == null
            ? label
            : '$label: ${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}',
      ),
    );
  }
}