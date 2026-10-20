import 'package:flutter/material.dart';

import '../data/models/employee.dart';
import '../data/repositories/employee_repository.dart';
import 'employee_details_screen.dart';
import 'employee_create_screen.dart';
import 'package:intl/intl.dart';
import '../../../../responsive/breakpoints.dart';
import '../../../../shared/widgets/adaptive_data_table.dart';


class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key, required this.repository});

  final EmployeeRepository repository;

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Employee> _employees = [];
  final NumberFormat _currency = NumberFormat('#,##0.00');

  String money(double value, String currency) =>
      '$currency ${_currency.format(value)}';

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final employees = await widget.repository.getAll();

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
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }
  String _statusLabel(EmployeeStatus status) {
    switch (status) {
      case EmployeeStatus.active:
        return 'Active';
      case EmployeeStatus.onLeave:
        return 'On Leave';
      case EmployeeStatus.suspended:
        return 'Suspended';
      case EmployeeStatus.inactive:
        return 'Inactive';
      case EmployeeStatus.terminated:
        return 'Terminated';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employees'),
        actions: [
          IconButton(
            tooltip: 'Add Employee',
            icon: const Icon(Icons.person_add),
            onPressed: () async {
              final createdEmployee =
              await Navigator.of(context).push<Employee>(
                MaterialPageRoute(
                  builder: (_) => EmployeeCreateScreen(
                    repository: widget.repository,
                  ),
                ),
              );

              if (createdEmployee != null && mounted) {
                await _loadEmployees();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadEmployees,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unable to load employees.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(_errorMessage!),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _loadEmployees,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_employees.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No employees have been created yet.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return AppBreakpoints.isDesktop(context)
        ? SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AdaptiveDataTable(
        columns: [
          AdaptiveColumn(
            label: 'Employee',
            value: (r) => r['name'] as String,
          ),
          AdaptiveColumn(
            label: 'Employee ID',
            value: (r) => r['employeeId'] as String,
          ),
          AdaptiveColumn(
            label: 'Department',
            value: (r) => r['department'] as String,
          ),
          AdaptiveColumn(
            label: 'Position',
            value: (r) => r['position'] as String,
          ),
          AdaptiveColumn(
            label: 'Status',
            value: (r) => r['status'] as String,
          ),
        ],
        rows: _employees.map((e) {
          final fullName = [
            e.firstName,
            if (e.middleName != null && e.middleName!.trim().isNotEmpty)
              e.middleName!,
            e.lastName,
          ].join(' ');

          return {
            'employee': e,
            'name': fullName,
            'employeeId': e.employeeNumber,
            'department': e.department ?? '-',
            'position': e.jobTitle ?? '-',
            'status': _statusLabel(e.status),
          };
        }).toList(),
        onRowTap: (row) {
          final employee = row['employee'] as Employee;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EmployeeDetailsScreen(
                employee: employee,
                repository: widget.repository,
              ),
            ),
          ).then((_) => _loadEmployees());
        },
      ),
    )
        : ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _employees.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _EmployeeCard(
          employee: _employees[index],
          repository: widget.repository,
        );
      },
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({
    required this.employee,
    required this.repository,
  });

  final Employee employee;
  final EmployeeRepository repository;
  String _money(double value) {
    return NumberFormat('#,##0.00').format(value);
  }

  String _date(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
  }



  @override
  Widget build(BuildContext context) {
    final fullName = [
      employee.firstName,
      if (employee.middleName != null && employee.middleName!.trim().isNotEmpty)
        employee.middleName!,
      employee.lastName,
    ].join(' ');

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EmployeeDetailsScreen(
                employee: employee,
                repository: repository,
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
                  CircleAvatar(
                    radius: 24,
                    child: Text(
                      employee.firstName[0].toUpperCase(),
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          employee.employeeNumber,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),

                  _StatusChip(status: employee.status),
                ],
              ),

              const SizedBox(height: 14),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (employee.department != null)
                    Chip(
                      label: Text(employee.department!),
                    ),

                  if (employee.jobTitle != null)
                    Chip(
                      label: Text(employee.jobTitle!),
                    ),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  const Icon(Icons.badge, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(_employeeTypeLabel(employee.employeeType)),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(Icons.calendar_month, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Hired: ${_date(employee.hireDate)}',
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              Row(
                children: [
                  const Icon(Icons.account_balance_wallet, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${employee.wageType.name.toUpperCase()} WAGE',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  Text(
                    '${employee.currencyCode} ${_money(employee.baseWage)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
      ),
    );
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
}
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final EmployeeStatus status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: _color(status).withValues(alpha: .12),
      label: Text(
        _label(status),
        style: TextStyle(
          color: _color(status),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _color(EmployeeStatus status) {
    switch (status) {
      case EmployeeStatus.active:
        return Colors.green;
      case EmployeeStatus.onLeave:
        return Colors.orange;
      case EmployeeStatus.suspended:
        return Colors.red;
      case EmployeeStatus.inactive:
        return Colors.grey;
      case EmployeeStatus.terminated:
        return Colors.black54;
    }
  }

  String _label(EmployeeStatus status) {
    switch (status) {
      case EmployeeStatus.active:
        return 'Active';
      case EmployeeStatus.onLeave:
        return 'On Leave';
      case EmployeeStatus.suspended:
        return 'Suspended';
      case EmployeeStatus.inactive:
        return 'Inactive';
      case EmployeeStatus.terminated:
        return 'Terminated';
    }
  }
}
