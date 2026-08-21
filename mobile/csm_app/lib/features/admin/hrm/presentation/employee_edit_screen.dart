import 'package:flutter/material.dart';

import '../data/models/employee.dart';
import '../data/repositories/employee_repository.dart';

class EmployeeEditScreen extends StatefulWidget {
  const EmployeeEditScreen({
    super.key,
    required this.employee,
    required this.repository,
  });

  final Employee employee;
  final EmployeeRepository repository;

  @override
  State<EmployeeEditScreen> createState() => _EmployeeEditScreenState();
}

class _EmployeeEditScreenState extends State<EmployeeEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _middleNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _nationalIdController;
  late final TextEditingController _taxIdController;
  late final TextEditingController _jobTitleController;
  late final TextEditingController _departmentController;
  late final TextEditingController _baseWageController;
  late final TextEditingController _currencyController;
  late final TextEditingController _bankNameController;
  late final TextEditingController _bankAccountController;
  late final TextEditingController _emergencyNameController;
  late final TextEditingController _emergencyPhoneController;

  late DateTime? _dateOfBirth;
  late DateTime _hireDate;

  late EmployeeType _employeeType;
  late WageType _wageType;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    final employee = widget.employee;

    _firstNameController = TextEditingController(text: employee.firstName);
    _middleNameController = TextEditingController(
      text: employee.middleName ?? '',
    );
    _lastNameController = TextEditingController(text: employee.lastName);
    _phoneController = TextEditingController(text: employee.phoneNumber ?? '');
    _emailController = TextEditingController(text: employee.email ?? '');
    _nationalIdController = TextEditingController(
      text: employee.nationalIdNumber ?? '',
    );
    _taxIdController = TextEditingController(
      text: employee.taxIdentificationNumber ?? '',
    );
    _jobTitleController = TextEditingController(text: employee.jobTitle ?? '');
    _departmentController = TextEditingController(
      text: employee.department ?? '',
    );
    _baseWageController = TextEditingController(
      text: employee.baseWage.toString(),
    );
    _currencyController = TextEditingController(text: employee.currencyCode);
    _bankNameController = TextEditingController(text: employee.bankName ?? '');
    _bankAccountController = TextEditingController(
      text: employee.bankAccountNumber ?? '',
    );
    _emergencyNameController = TextEditingController(
      text: employee.emergencyContactName ?? '',
    );
    _emergencyPhoneController = TextEditingController(
      text: employee.emergencyContactPhone ?? '',
    );

    _dateOfBirth = employee.dateOfBirth;
    _hireDate = employee.hireDate;
    _employeeType = employee.employeeType;
    _wageType = employee.wageType;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _nationalIdController.dispose();
    _taxIdController.dispose();
    _jobTitleController.dispose();
    _departmentController.dispose();
    _baseWageController.dispose();
    _currencyController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate({
    required DateTime? currentDate,
    required ValueChanged<DateTime> onSelected,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? DateTime(2100),
    );

    if (selected != null && mounted) {
      setState(() {
        onSelected(selected);
      });
    }
  }

  Future<void> _saveEmployee() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final baseWage = double.tryParse(_baseWageController.text.trim());

    if (baseWage == null || baseWage < 0) {
      setState(() {
        _errorMessage = 'Please enter a valid base wage.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final employee = await widget.repository.update(
        employeeId: widget.employee.id,
        firstName: _firstNameController.text.trim(),
        middleName: _nullableText(_middleNameController.text),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _nullableText(_phoneController.text),
        email: _nullableText(_emailController.text),
        nationalIdNumber: _nullableText(_nationalIdController.text),
        taxIdentificationNumber: _nullableText(_taxIdController.text),
        dateOfBirth: _dateOfBirth,
        hireDate: _hireDate,
        jobTitle: _nullableText(_jobTitleController.text),
        department: _nullableText(_departmentController.text),
        employeeType: _employeeType,
        wageType: _wageType,
        baseWage: baseWage,
        currencyCode: _currencyController.text.trim().toUpperCase(),
        bankName: _nullableText(_bankNameController.text),
        bankAccountNumber: _nullableText(_bankAccountController.text),
        emergencyContactName: _nullableText(_emergencyNameController.text),
        emergencyContactPhone: _nullableText(_emergencyPhoneController.text),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(employee);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _errorMessage = error.toString();
      });
    }
  }

  String? _nullableText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit ${widget.employee.employeeNumber}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_errorMessage != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_errorMessage!),
                ),
              ),
              const SizedBox(height: 16),
            ],
            _buildPersonalInformationCard(context),
            const SizedBox(height: 16),
            _buildEmploymentCard(context),
            const SizedBox(height: 16),
            _buildCompensationCard(context),
            const SizedBox(height: 16),
            _buildBankingCard(context),
            const SizedBox(height: 16),
            _buildEmergencyContactCard(context),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveEmployee,
              icon: const Icon(Icons.save),
              label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
            ),
            if (_isSaving) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInformationCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: TextEditingController(
                text: widget.employee.employeeNumber,
              ),
              label: 'Employee Number',
              enabled: false,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _firstNameController,
              label: 'First Name',
              required: true,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _middleNameController,
              label: 'Middle Name',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _lastNameController,
              label: 'Last Name',
              required: true,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _nationalIdController,
              label: 'National ID Number',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _taxIdController,
              label: 'Tax Identification Number',
            ),
            const SizedBox(height: 16),
            _DateField(
              label: 'Date of Birth',
              value: _dateOfBirth,
              onTap: () => _selectDate(
                currentDate: _dateOfBirth,
                onSelected: (date) {
                  _dateOfBirth = date;
                },
                lastDate: DateTime.now(),
              ),
            ),
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
            _buildTextField(
              controller: _jobTitleController,
              label: 'Job Title',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _departmentController,
              label: 'Department',
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<EmployeeType>(
              initialValue: _employeeType,
              decoration: const InputDecoration(
                labelText: 'Employee Type',
                border: OutlineInputBorder(),
              ),
              items: EmployeeType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(_employeeTypeLabel(type)),
                    ),
                  )
                  .toList(),
              onChanged: _isSaving
                  ? null
                  : (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        _employeeType = value;
                      });
                    },
            ),
            const SizedBox(height: 12),
            _DateField(
              label: 'Hire Date',
              value: _hireDate,
              required: true,
              onTap: () => _selectDate(
                currentDate: _hireDate,
                onSelected: (date) {
                  _hireDate = date;
                },
              ),
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
            DropdownButtonFormField<WageType>(
              initialValue: _wageType,
              decoration: const InputDecoration(
                labelText: 'Wage Type',
                border: OutlineInputBorder(),
              ),
              items: WageType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(_wageTypeLabel(type)),
                    ),
                  )
                  .toList(),
              onChanged: _isSaving
                  ? null
                  : (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        _wageType = value;
                      });
                    },
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _baseWageController,
              label: 'Base Wage',
              required: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                final text = value?.trim() ?? '';

                if (text.isEmpty) {
                  return 'Required';
                }

                final amount = double.tryParse(text);

                if (amount == null || amount < 0) {
                  return 'Enter a valid wage';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _currencyController,
              label: 'Currency Code',
              required: true,
              textCapitalization: TextCapitalization.characters,
              validator: (value) {
                final text = value?.trim().toUpperCase() ?? '';

                if (text.isEmpty) {
                  return 'Required';
                }

                if (text.length != 3) {
                  return 'Use a 3-letter currency code';
                }

                return null;
              },
            ),
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
            _buildTextField(
              controller: _bankNameController,
              label: 'Bank Name',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _bankAccountController,
              label: 'Bank Account Number',
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
            _buildTextField(
              controller: _emergencyNameController,
              label: 'Contact Name',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _emergencyPhoneController,
              label: 'Contact Phone',
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool required = false,
    bool enabled = true,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled && !_isSaving,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator:
          validator ??
          (value) {
            if (required && (value == null || value.trim().isEmpty)) {
              return 'Required';
            }

            return null;
          },
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
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.required = false,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          value == null
              ? required
                    ? 'Select date'
                    : 'Not specified'
              : _formatDate(value!),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
