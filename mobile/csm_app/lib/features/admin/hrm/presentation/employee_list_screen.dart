import 'package:flutter/material.dart';

import '../data/models/employee.dart';
import '../data/repositories/employee_repository.dart';
import 'employee_details_screen.dart';
import 'employee_create_screen.dart';

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

    return ListView.separated(
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
                    child: Text(
                      employee.firstName.isNotEmpty
                          ? employee.firstName[0].toUpperCase()
                          : '?',
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
                        const SizedBox(height: 4),
                        Text(employee.employeeNumber),
                      ],
                    ),
                  ),
                  Chip(label: Text(_statusLabel(employee.status))),
                ],
              ),
              if (employee.jobTitle != null &&
                  employee.jobTitle!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  employee.jobTitle!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
              if (employee.department != null &&
                  employee.department!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(employee.department!),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(_employeeTypeLabel(employee.employeeType)),
                  ),
                  Text(
                    '${employee.baseWage.toStringAsFixed(2)} '
                    '${employee.currencyCode}',
                  ),
                ],
              ),
            ],
          ),
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
}
