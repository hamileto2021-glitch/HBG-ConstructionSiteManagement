import 'package:flutter/material.dart';

import '../data/models/employee.dart';

import '../data/repositories/employee_repository.dart';
import '../data/repositories/timesheet_repository.dart';

class TimesheetCreateScreen extends StatefulWidget {
  const TimesheetCreateScreen({
    super.key,
    required this.employeeRepository,
    required this.timesheetRepository,
  });

  final EmployeeRepository employeeRepository;
  final TimesheetRepository timesheetRepository;

  @override
  State<TimesheetCreateScreen> createState() =>
      _TimesheetCreateScreenState();
}

class _TimesheetCreateScreenState
    extends State<TimesheetCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoadingEmployees = true;
  bool _isSaving = false;
  String? _error;

  List<Employee> _employees = [];
  Employee? _selectedEmployee;

  DateTime? _periodStart;
  DateTime? _periodEnd;

  final _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    try {
      final employees =
          await widget.employeeRepository.getAll(
        status: EmployeeStatus.active,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _employees = employees;
        _isLoadingEmployees = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString();
        _isLoadingEmployees = false;
      });
    }
  }

  Future<void> _selectStartDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _periodStart ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _periodStart = selected;

      if (_periodEnd != null &&
          _periodEnd!.isBefore(selected)) {
        _periodEnd = null;
      }
    });
  }

  Future<void> _selectEndDate() async {
    final start = _periodStart;

    final selected = await showDatePicker(
      context: context,
      initialDate: _periodEnd ?? start ?? DateTime.now(),
      firstDate: start ?? DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _periodEnd = selected;
    });
  }

  Future<void> _createTimesheet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedEmployee == null ||
        _periodStart == null ||
        _periodEnd == null) {
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await widget.timesheetRepository.create(
        employeeId: _selectedEmployee!.id,
        periodStartDate: _periodStart!,
        periodEndDate: _periodEnd!,
        remarks: _remarksController.text.trim().isEmpty
            ? null
            : _remarksController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Timesheet created successfully.',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString();
        _isSaving = false;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Select date';
    }

    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Timesheet'),
      ),
      body: _isLoadingEmployees
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  DropdownButtonFormField<Employee>(
                    initialValue: _selectedEmployee,
                    decoration: const InputDecoration(
                      labelText: 'Employee',
                      border: OutlineInputBorder(),
                    ),
                    items: _employees
                        .map(
                          (employee) =>
                              DropdownMenuItem<Employee>(
                            value: employee,
                            child: Text(
                              '${employee.employeeNumber} - '
                              '${employee.firstName} '
                              '${employee.lastName}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _isSaving
                        ? null
                        : (employee) {
                            setState(() {
                              _selectedEmployee = employee;
                            });
                          },
                    validator: (value) {
                      if (value == null) {
                        return 'Select an employee.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Period start'),
                    subtitle: Text(
                      _formatDate(_periodStart),
                    ),
                    trailing: const Icon(
                      Icons.calendar_today_outlined,
                    ),
                    onTap:
                        _isSaving ? null : _selectStartDate,
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Period end'),
                    subtitle: Text(
                      _formatDate(_periodEnd),
                    ),
                    trailing: const Icon(
                      Icons.calendar_today_outlined,
                    ),
                    onTap:
                        _isSaving ? null : _selectEndDate,
                  ),
                  if (_periodStart != null &&
                      _periodEnd != null &&
                      _periodEnd!.isBefore(_periodStart!))
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Period end must not be before period start.',
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _remarksController,
                    maxLines: 4,
                    enabled: !_isSaving,
                    decoration: const InputDecoration(
                      labelText: 'Remarks',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed:
                          _isSaving ? null : _createTimesheet,
                      icon: const Icon(Icons.save_outlined),
                      label: _isSaving
                          ? const Text('Creating...')
                          : const Text('Create Timesheet'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
