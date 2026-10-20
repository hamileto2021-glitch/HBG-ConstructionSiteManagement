import 'package:flutter/material.dart';

import '../data/models/employee.dart';
import '../data/models/generate_timesheet_request.dart';
import '../data/repositories/employee_repository.dart';
import '../data/repositories/timesheet_repository.dart';

class TimesheetGenerateScreen extends StatefulWidget {
  const TimesheetGenerateScreen({
    super.key,
    required this.repository,
  });

  final TimesheetRepository repository;

  @override
  State<TimesheetGenerateScreen> createState() =>
      _TimesheetGenerateScreenState();
}

class _TimesheetGenerateScreenState
    extends State<TimesheetGenerateScreen> {
  final _employeeRepo = EmployeeRepository();

  List<Employee> _employees = [];
  Employee? _selectedEmployee;

  DateTime _month = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    final employees = await _employeeRepo.getAll(
      status: EmployeeStatus.active,
    );

    setState(() {
      _employees = employees;
      _loading = false;
    });
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        _month = DateTime(
          picked.year,
          picked.month,
          1,
        );
      });
    }
  }

  Future<void> _generate() async {
    if (_selectedEmployee == null) return;

    setState(() => _saving = true);

    try {
      await widget.repository.generate(
        GenerateTimesheetRequest(
          employeeId: _selectedEmployee!.id,
          year: _month.year,
          month: _month.month,
        ),
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _monthName(int m) {
    const names = [
      'January','February','March','April',
      'May','June','July','August',
      'September','October','November','December'
    ];
    return names[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Timesheet'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<Employee>(
              decoration: const InputDecoration(
                labelText: 'Employee',
                border: OutlineInputBorder(),
              ),
              items: _employees.map((e) {
                return DropdownMenuItem(
                  value: e,
                  child: Text(
                    '${e.employeeNumber} - ${e.firstName} ${e.lastName}',
                  ),
                );
              }).toList(),
              onChanged: (v) {
                setState(() => _selectedEmployee = v);
              },
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: _pickMonth,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Payroll Month',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  '${_monthName(_month.month)} ${_month.year}',
                ),
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed:
              _saving ? null : _generate,
              icon: const Icon(Icons.auto_fix_high),
              label: Text(
                _saving
                    ? 'Generating...'
                    : 'Generate Timesheet',
              ),
            ),
          ],
        ),
      ),
    );
  }
}