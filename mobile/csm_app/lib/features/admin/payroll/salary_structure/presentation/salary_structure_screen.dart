import 'package:flutter/material.dart';

import '../../../hrm/data/models/employee.dart';
import '../../../hrm/data/repositories/employee_repository.dart';

import '../data/models/salary_structure.dart';
import '../data/repositories/salary_structure_repository.dart';

class SalaryStructureScreen extends StatefulWidget {
  const SalaryStructureScreen({super.key});

  @override
  State<SalaryStructureScreen> createState() =>
      _SalaryStructureScreenState();
}

class _SalaryStructureScreenState
    extends State<SalaryStructureScreen> {
  final _repo = SalaryStructureRepository();
  final _employeeRepo = EmployeeRepository();
  final _formKey = GlobalKey<FormState>();

  List<Employee> _employees = [];
  Employee? _selected;

  final _basic = TextEditingController();
  final _housing = TextEditingController(text: '0');
  final _transport = TextEditingController(text: '0');
  final _position = TextEditingController(text: '0');
  final _overtime = TextEditingController(text: '1.5');
  final _pension = TextEditingController(text: '7');
  final _bank = TextEditingController();
  final _account = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final list = await _employeeRepo.getAll(
        status: EmployeeStatus.active,
      );

      if (!mounted) return;

      setState(() {
        _employees = list;
        _loading = false;
      });

      // Auto-select first employee and load its salary
      if (list.isNotEmpty) {
        _selected = list.first;
        await _loadSalary(_selected!);

        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _loadSalary(Employee employee) async {
    final salary = await _repo.getByEmployee(employee.id);

    if (salary == null) {
      _basic.clear();
      _housing.text = '0';
      _transport.text = '0';
      _position.text = '0';
      _overtime.text = '1.5';
      _pension.text = '7';
      _bank.clear();
      _account.clear();
      return;
    }

    _basic.text = salary.basicSalary.toString();
    _housing.text = salary.housingAllowance.toString();
    _transport.text = salary.transportAllowance.toString();
    _position.text = salary.positionAllowance.toString();
    _overtime.text = salary.overtimeMultiplier.toString();
    _pension.text = salary.pensionPercentage.toString();
    _bank.text = salary.bankName;
    _account.text = salary.bankAccountNumber;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selected == null) return;

    setState(() => _saving = true);

    try {
      await _repo.save(
        SalaryStructure(
          id: '',
          employeeId: _selected!.id,
          basicSalary: double.parse(_basic.text),
          housingAllowance: double.parse(_housing.text),
          transportAllowance: double.parse(_transport.text),
          positionAllowance: double.parse(_position.text),
          overtimeMultiplier: double.parse(_overtime.text),
          pensionPercentage: double.parse(_pension.text),
          bankName: _bank.text,
          bankAccountNumber: _account.text,
          isActive: true,
        ),
      );

      // Reload from API
      await _loadSalary(_selected!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Salary structure saved successfully.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  Widget _moneyField(
      TextEditingController controller,
      String label,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType:
        const TextInputType.numberWithOptions(decimal: true),
        validator: _required,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
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
        title: const Text('Salary Structure'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<Employee?>(
              initialValue: _selected,
              decoration: const InputDecoration(
                labelText: 'Employee',
                border: OutlineInputBorder(),
              ),
              items: _employees.map((e) {
                return DropdownMenuItem<Employee>(
                  value: e,
                  child: Text(
                    '${e.employeeNumber} - ${e.firstName} ${e.lastName}',
                  ),
                );
              }).toList(),
              onChanged: (employee) async {
                if (employee == null) return;

                setState(() => _selected = employee);

                await _loadSalary(employee);

                if (mounted) {
                  setState(() {});
                }
              },
            ),
            const SizedBox(height: 18),
            _moneyField(_basic, 'Basic Salary'),
            _moneyField(_housing, 'Housing Allowance'),
            _moneyField(_transport, 'Transport Allowance'),
            _moneyField(_position, 'Position Allowance'),
            _moneyField(_overtime, 'Overtime Multiplier'),
            _moneyField(_pension, 'Pension %'),
            _moneyField(_bank, 'Bank Name'),
            _moneyField(_account, 'Bank Account Number'),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(
                _saving ? 'Saving...' : 'Save Salary Structure',
              ),
            ),
          ],
        ),
      ),
    );
  }
}