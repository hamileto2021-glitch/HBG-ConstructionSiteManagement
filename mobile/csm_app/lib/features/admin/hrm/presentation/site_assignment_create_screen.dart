import 'package:flutter/material.dart';

import '../data/models/employee.dart';

import '../data/repositories/employee_repository.dart';
import '../data/repositories/site_assignment_repository.dart';
import '../../sites/data/models/site.dart';
import '../../sites/data/repositories/site_repository.dart';

class SiteAssignmentCreateScreen extends StatefulWidget {
  const SiteAssignmentCreateScreen({
    super.key,
    required this.assignmentRepository,
    required this.employeeRepository,
    required this.siteRepository,
  });

  final SiteAssignmentRepository assignmentRepository;
  final EmployeeRepository employeeRepository;
  final SiteRepository siteRepository;

  @override
  State<SiteAssignmentCreateScreen> createState() =>
      _SiteAssignmentCreateScreenState();
}

class _SiteAssignmentCreateScreenState
    extends State<SiteAssignmentCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  List<Employee> _employees = [];
  List<Site> _sites = [];

  Employee? _selectedEmployee;
  Site? _selectedSite;

  DateTime? _startDate;
  DateTime? _endDate;

  final _roleController = TextEditingController();
  final _remarksController = TextEditingController();

  bool _isPrimaryAssignment = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _roleController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final employees = await widget.employeeRepository.getAll(
        status: EmployeeStatus.active,
      );

      final sites = await widget.siteRepository.getAll();

      if (!mounted) {
        return;
      }

      setState(() {
        _employees = employees;
        _sites = sites.where((site) => site.isActive).toList();
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
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
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

    if (_selectedSite == null) {
      _showMessage('Select a construction site.');
      return;
    }

    if (_startDate == null) {
      _showMessage('Select a start date.');
      return;
    }

    if (_endDate != null &&
        _endDate!.isBefore(_startDate!)) {
      _showMessage(
        'End date cannot be earlier than start date.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.assignmentRepository.create(
        employeeId: _selectedEmployee!.id,
        constructionSiteId: _selectedSite!.id,
        startDate: _startDate!,
        endDate: _endDate,
        roleAtSite: _roleController.text.trim().isEmpty
            ? null
            : _roleController.text.trim(),
        isPrimaryAssignment: _isPrimaryAssignment,
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
            'Site assignment created successfully.',
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
        title: const Text('Create Site Assignment'),
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
                'Unable to load assignment data.',
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
                onPressed: _loadData,
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
                    'Assignment',
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
                              '${employee.firstName} ${employee.lastName}',
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
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Site>(
                    isExpanded: true,
                    initialValue: _selectedSite,
                    decoration: const InputDecoration(
                      labelText: 'Construction site',
                      border: OutlineInputBorder(),
                    ),
                    items: _sites
                        .map(
                          (site) => DropdownMenuItem<Site>(
                            value: site,
                            child: Text(
                              '${site.siteCode} - ${site.name}',
                              overflow:
                                  TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _isSaving
                        ? null
                        : (site) {
                            setState(() {
                              _selectedSite = site;
                            });
                          },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _roleController,
                    enabled: !_isSaving,
                    decoration: const InputDecoration(
                      labelText: 'Role at site',
                      border: OutlineInputBorder(),
                    ),
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
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Primary assignment',
                    ),
                    subtitle: const Text(
                      'Employee can have only one overlapping '
                      'primary site assignment.',
                    ),
                    value: _isPrimaryAssignment,
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            setState(() {
                              _isPrimaryAssignment =
                                  value;
                            });
                          },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _remarksController,
                    enabled: !_isSaving,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Remarks',
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
                  : const Icon(Icons.save),
              label: Text(
                _isSaving
                    ? 'Saving...'
                    : 'Create Assignment',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
