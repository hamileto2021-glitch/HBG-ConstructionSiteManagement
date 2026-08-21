import 'package:flutter/material.dart';

import '../data/models/employee.dart';
import '../data/repositories/employee_repository.dart';
import '../data/repositories/leave_repository.dart';

class LeaveCreateScreen extends StatefulWidget {
  const LeaveCreateScreen({
    super.key,
    required this.leaveRepository,
    required this.employeeRepository,
  });

  final LeaveRepository leaveRepository;
  final EmployeeRepository employeeRepository;

  @override
  State<LeaveCreateScreen> createState() =>
      _LeaveCreateScreenState();
}

class _LeaveCreateScreenState
    extends State<LeaveCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  List<Employee> _employees = [];
  Employee? _selectedEmployee;

  DateTime? _startDate;
  DateTime? _endDate;

  final _leaveTypeController = TextEditingController();
  final _reasonController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _leaveTypeController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final employees = await widget.employeeRepository.getAll(
        status: EmployeeStatus.active,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _employees = employees;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadError = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectStartDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _startDate = selected;

      if (_endDate != null &&
          _endDate!.isBefore(selected)) {
        _endDate = null;
      }
    });
  }

  Future<void> _selectEndDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate:
          _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _endDate = selected;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedEmployee == null) {
      _showMessage('Select an employee.');
      return;
    }

    if (_startDate == null) {
      _showMessage('Select a start date.');
      return;
    }

    if (_endDate == null) {
      _showMessage('Select an end date.');
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      _showMessage(
        'End date cannot be earlier than start date.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.leaveRepository.create(
        employeeId: _selectedEmployee!.id,
        leaveType: _leaveTypeController.text.trim(),
        startDate: _startDate!,
        endDate: _endDate!,
        reason:
            _reasonController.text.trim().isEmpty
                ? null
                : _reasonController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Leave request created successfully.',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      _showMessage('Creation failed: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
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
        title: const Text('Create Leave Request'),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to load employees.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _loadError!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadEmployees,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Leave Request',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Employee>(
                    isExpanded: true,
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
                              overflow:
                                  TextOverflow.ellipsis,
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
                  TextFormField(
                    controller: _leaveTypeController,
                    enabled: !_isSaving,
                    decoration: const InputDecoration(
                      labelText: 'Leave type',
                      hintText:
                          'e.g. Annual, Sick, Emergency',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Enter a leave type.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed:
                        _isSaving ? null : _selectStartDate,
                    icon: const Icon(
                      Icons.calendar_today,
                    ),
                    label: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Start date: '
                        '${_formatDate(_startDate)}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed:
                        _isSaving ? null : _selectEndDate,
                    icon: const Icon(
                      Icons.event_available,
                    ),
                    label: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'End date: '
                        '${_formatDate(_endDate)}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _reasonController,
                    enabled: !_isSaving,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Reason',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(
                _isSaving
                    ? 'Submitting...'
                    : 'Submit Leave Request',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
