import 'package:flutter/material.dart';

import '../data/models/employee.dart';
import '../data/repositories/employee_repository.dart';
import 'employee_edit_screen.dart';

class EmployeeDetailsScreen extends StatefulWidget {
  const EmployeeDetailsScreen({
    super.key,
    required this.employee,
    required this.repository,
  });

  final Employee employee;
  final EmployeeRepository repository;

  @override
  State<EmployeeDetailsScreen> createState() => _EmployeeDetailsScreenState();
}

class _EmployeeDetailsScreenState extends State<EmployeeDetailsScreen> {
  late Employee _employee;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _employee = widget.employee;
    _loadEmployee();
  }

  Future<void> _loadEmployee() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final employee = await widget.repository.getById(_employee.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _employee = employee;
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
  List<EmployeeStatus> _allowedNextStatuses(
      EmployeeStatus current,
      ) {
    switch (current) {
      case EmployeeStatus.active:
        return [
          EmployeeStatus.onLeave,
          EmployeeStatus.suspended,
          EmployeeStatus.inactive,
          EmployeeStatus.terminated,
        ];

      case EmployeeStatus.onLeave:
        return [
          EmployeeStatus.active,
          EmployeeStatus.terminated,
        ];

      case EmployeeStatus.suspended:
        return [
          EmployeeStatus.active,
          EmployeeStatus.inactive,
          EmployeeStatus.terminated,
        ];

      case EmployeeStatus.inactive:
        return [
          EmployeeStatus.active,
          EmployeeStatus.terminated,
        ];

      case EmployeeStatus.terminated:
        return [];
    }
  }
  Future<void> _changeStatus(
      EmployeeStatus status,
      DateTime? terminationDate,
      ) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final employee =
      await widget.repository.changeStatus(
        employeeId: _employee.id,
        status: status,
        terminationDate: terminationDate,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _employee = employee;
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
  Future<void> _showStatusDialog() async {
    final allowedStatuses =
    _allowedNextStatuses(_employee.status);

    if (allowedStatuses.isEmpty) {
      return;
    }

    final selectedStatus =
    await showDialog<EmployeeStatus>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Change Employee Status'),
          children: [
            for (final status in allowedStatuses)
              SimpleDialogOption(
                onPressed: () {
                  Navigator.of(context).pop(status);
                },
                child: Text(_statusLabel(status)),
              ),
          ],
        );
      },
    );

    if (selectedStatus == null || !mounted) {
      return;
    }

    DateTime? terminationDate;

    if (selectedStatus == EmployeeStatus.terminated) {
      terminationDate = await showDatePicker(
        context: context,
        initialDate: _employee.hireDate,
        firstDate: _employee.hireDate,
        lastDate: DateTime(2100),
      );

      if (terminationDate == null || !mounted) {
        return;
      }
    }

    await _changeStatus(
      selectedStatus,
      terminationDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_employee.employeeNumber),
        actions: [
          IconButton(
            tooltip: 'Edit Employee',
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updatedEmployee = await Navigator.of(context)
                  .push<Employee>(
                    MaterialPageRoute(
                      builder: (_) => EmployeeEditScreen(
                        employee: _employee,
                        repository: widget.repository,
                      ),
                    ),
                  );

              if (updatedEmployee != null && mounted) {
                setState(() {
                  _employee = updatedEmployee;
                });
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadEmployee,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_errorMessage != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Unable to refresh employee details.\n\n'
                    '$_errorMessage',
                  ),
                ),
              ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: LinearProgressIndicator(),
              ),
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildStatusCard(context),
            const SizedBox(height: 16),
            _buildEmploymentCard(context),
            const SizedBox(height: 16),
            _buildContactCard(context),
            const SizedBox(height: 16),
            _buildCompensationCard(context),
            const SizedBox(height: 16),
            _buildBankingCard(context),
            const SizedBox(height: 16),
            _buildEmergencyContactCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final fullName = [
      _employee.firstName,
      if (_employee.middleName != null &&
          _employee.middleName!.trim().isNotEmpty)
        _employee.middleName!,
      _employee.lastName,
    ].join(' ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              child: Text(
                _employee.firstName.isNotEmpty
                    ? _employee.firstName[0].toUpperCase()
                    : '?',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _employee.employeeNumber,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 12),
                  Chip(label: Text(_statusLabel(_employee.status))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildStatusCard(BuildContext context) {
    final allowedStatuses =
    _allowedNextStatuses(_employee.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Employee Status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _statusLabel(_employee.status),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),
                ),
                Chip(
                  label: Text(
                    _statusLabel(_employee.status),
                  ),
                ),
              ],
            ),
            if (_employee.terminationDate != null) ...[
              const SizedBox(height: 12),
              Text(
                'Termination date: '
                    '${_formatDate(_employee.terminationDate!)}',
              ),
            ],
            if (allowedStatuses.isNotEmpty) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed:
                _isLoading ? null : _showStatusDialog,
                icon: const Icon(Icons.sync_alt),
                label: const Text('Change Status'),
              ),
            ],
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmploymentCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Employment Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Job title',
              value: _employee.jobTitle ?? 'Not specified',
            ),
            _InfoRow(
              label: 'Department',
              value: _employee.department ?? 'Not specified',
            ),
            _InfoRow(
              label: 'Employee type',
              value: _employeeTypeLabel(_employee.employeeType),
            ),
            _InfoRow(label: 'Status', value: _statusLabel(_employee.status)),
            _InfoRow(
              label: 'Hire date',
              value: _formatDate(_employee.hireDate),
            ),
            if (_employee.terminationDate != null)
              _InfoRow(
                label: 'Termination date',
                value: _formatDate(_employee.terminationDate!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Phone',
              value: _employee.phoneNumber ?? 'Not specified',
            ),
            _InfoRow(label: 'Email', value: _employee.email ?? 'Not specified'),
            _InfoRow(
              label: 'National ID',
              value: _employee.nationalIdNumber ?? 'Not specified',
            ),
            _InfoRow(
              label: 'Tax ID',
              value: _employee.taxIdentificationNumber ?? 'Not specified',
            ),
            _InfoRow(
              label: 'Date of birth',
              value: _employee.dateOfBirth == null
                  ? 'Not specified'
                  : _formatDate(_employee.dateOfBirth!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompensationCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Compensation', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Wage type',
              value: _wageTypeLabel(_employee.wageType),
            ),
            _InfoRow(
              label: 'Base wage',
              value:
                  '${_employee.baseWage.toStringAsFixed(2)} '
                  '${_employee.currencyCode}',
            ),
            _InfoRow(label: 'Currency', value: _employee.currencyCode),
          ],
        ),
      ),
    );
  }

  Widget _buildBankingCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Banking Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Bank',
              value: _employee.bankName ?? 'Not specified',
            ),
            _InfoRow(
              label: 'Account number',
              value: _employee.bankAccountNumber ?? 'Not specified',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emergency Contact',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Name',
              value: _employee.emergencyContactName ?? 'Not specified',
            ),
            _InfoRow(
              label: 'Phone',
              value: _employee.emergencyContactPhone ?? 'Not specified',
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(EmployeeStatus status) {
    switch (status) {
      case EmployeeStatus.active:
        return 'Active';
      case EmployeeStatus.inactive:
        return 'Inactive';
      case EmployeeStatus.suspended:
        return 'Suspended';
      case EmployeeStatus.terminated:
        return 'Terminated';
      case EmployeeStatus.onLeave:
        return 'On Leave';
    }
  }

  String _employeeTypeLabel(EmployeeType type) {
    switch (type) {
      case EmployeeType.permanent:
        return 'Permanent';
      case EmployeeType.temporary:
        return 'Temporary';
      case EmployeeType.contract:
        return 'Contract';
      case EmployeeType.dailyLabor:
        return 'Daily Labor';
    }
  }

  String _wageTypeLabel(WageType type) {
    switch (type) {
      case WageType.hourly:
        return 'Hourly';
      case WageType.daily:
        return 'Daily';
      case WageType.weekly:
        return 'Weekly';
      case WageType.monthly:
        return 'Monthly';
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
