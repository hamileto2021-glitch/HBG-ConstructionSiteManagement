import 'package:flutter/material.dart';

import '../data/models/employee.dart';
import '../data/repositories/employee_repository.dart';
import '../data/repositories/payroll_repository.dart';

class PayrollCreateScreen extends StatefulWidget {
  const PayrollCreateScreen({
    super.key,
    required this.repository,
  });

  final PayrollRepository repository;

  @override
  State<PayrollCreateScreen> createState() =>
      _PayrollCreateScreenState();
}

class _PayrollCreateScreenState
    extends State<PayrollCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _employeeRepository = EmployeeRepository();

  List<Employee> _employees = [];
  Employee? _selectedEmployee;

  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  DateTime get _periodStart =>
      DateTime(_selectedMonth.year, _selectedMonth.month, 1);

  DateTime get _periodEnd =>
      DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

  bool _isLoadingEmployees = true;
  bool _isSaving = false;
  String? _employeeError;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _isLoadingEmployees = true;
      _employeeError = null;
    });

    try {
      final employees = await _employeeRepository.getAll(
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
        _employeeError = error.toString();
        _isLoadingEmployees = false;
      });
    }
  }





  Future<void> _selectPayrollMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedMonth = DateTime(
          picked.year,
          picked.month,
          1,
        );
      });
    }
  }

  Future<void> _createPayroll() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }


    final employee = _selectedEmployee;

    if (employee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Select an employee.',
          ),
        ),
      );
      return;
    }



    setState(() {
      _isSaving = true;
    });

    try {

      debugPrint('Start: ${_formatDate(_periodStart)}');
      debugPrint('End: ${_formatDate(_periodEnd)}');
      await widget.repository.create(
        employeeId: employee.id,
        periodStart: _periodStart,
        periodEnd: _periodEnd,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payroll created successfully.',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payroll creation failed: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Payroll'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Create Payroll',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a new payroll record in Draft status.',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge,
            ),
            const SizedBox(height: 24),
            if (_isLoadingEmployees)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_employeeError != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Unable to load employees.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _employeeError!,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _loadEmployees,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else
              DropdownButtonFormField<Employee>(
                initialValue: _selectedEmployee,
                decoration: const InputDecoration(
                  labelText: 'Employee',
                  border: OutlineInputBorder(),
                ),
                items: _employees.map((employee) {
                  return DropdownMenuItem<Employee>(
                    value: employee,
                    child: Text(
                      '${employee.employeeNumber} - '
                      '${employee.firstName} '
                      '${employee.lastName}',
                    ),
                  );
                }).toList(),
                onChanged: _isSaving
                    ? null
                    : (employee) {
                        setState(() {
                          _selectedEmployee = employee;
                        });
                      },
                validator: (value) {
                  if (value == null) {
                    return 'Employee is required.';
                  }

                  return null;
                },
              ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectPayrollMonth,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Payroll Month',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_month),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_monthName(_selectedMonth.month)} ${_selectedMonth.year}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_formatDate(_periodStart)}  →  ${_formatDate(_periodEnd)}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed:
                  _isSaving || _isLoadingEmployees
                      ? null
                      : _createPayroll,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.add),
              label: Text(
                _isSaving
                    ? 'Creating...'
                    : 'Create Payroll',
              ),
            ),
          ],
        ),
      ),
    );
  }
}


