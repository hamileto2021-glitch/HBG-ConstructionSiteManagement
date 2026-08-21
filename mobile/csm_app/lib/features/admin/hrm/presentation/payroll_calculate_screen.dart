import 'package:flutter/material.dart';

import '../data/models/payroll.dart';
import '../data/repositories/payroll_repository.dart';

class PayrollCalculateScreen extends StatefulWidget {
  const PayrollCalculateScreen({
    super.key,
    required this.payroll,
    required this.repository,
  });

  final Payroll payroll;
  final PayrollRepository repository;

  @override
  State<PayrollCalculateScreen> createState() =>
      _PayrollCalculateScreenState();
}

class _PayrollCalculateScreenState
    extends State<PayrollCalculateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _overtimeMultiplierController =
      TextEditingController(text: '1.5');
  final _allowancesController =
      TextEditingController(text: '0');
  final _bonusesController =
      TextEditingController(text: '0');
  final _taxDeductionController =
      TextEditingController(text: '0');
  final _pensionDeductionController =
      TextEditingController(text: '0');
  final _otherDeductionsController =
      TextEditingController(text: '0');

  bool _isSaving = false;

  @override
  void dispose() {
    _overtimeMultiplierController.dispose();
    _allowancesController.dispose();
    _bonusesController.dispose();
    _taxDeductionController.dispose();
    _pensionDeductionController.dispose();
    _otherDeductionsController.dispose();
    super.dispose();
  }

  Future<void> _calculatePayroll() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.repository.calculate(
        payrollId: widget.payroll.id,
        overtimeMultiplier: double.parse(
          _overtimeMultiplierController.text.trim(),
        ),
        allowances: double.parse(
          _allowancesController.text.trim(),
        ),
        bonuses: double.parse(
          _bonusesController.text.trim(),
        ),
        taxDeduction: double.parse(
          _taxDeductionController.text.trim(),
        ),
        pensionDeduction: double.parse(
          _pensionDeductionController.text.trim(),
        ),
        otherDeductions: double.parse(
          _otherDeductionsController.text.trim(),
        ),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payroll calculated successfully.',
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
            'Payroll calculation failed: $error',
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

  String? _validateNumber(
    String? value, {
    bool allowZero = true,
  }) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Required.';
    }

    final number = double.tryParse(text);

    if (number == null) {
      return 'Enter a valid number.';
    }

    if (!allowZero && number <= 0) {
      return 'Must be greater than zero.';
    }

    if (allowZero && number < 0) {
      return 'Cannot be negative.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final payroll = widget.payroll;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculate Payroll'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              payroll.employeeName,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              payroll.employeeNumber,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '${_formatDate(payroll.periodStart)}'
              ' - '
              '${_formatDate(payroll.periodEnd)}',
            ),
            const SizedBox(height: 24),
            _NumberField(
              controller: _overtimeMultiplierController,
              label: 'Overtime multiplier',
              validator: (value) => _validateNumber(
                value,
                allowZero: false,
              ),
            ),
            const SizedBox(height: 16),
            _NumberField(
              controller: _allowancesController,
              label: 'Allowances',
              validator: _validateNumber,
            ),
            const SizedBox(height: 16),
            _NumberField(
              controller: _bonusesController,
              label: 'Bonuses',
              validator: _validateNumber,
            ),
            const SizedBox(height: 16),
            _NumberField(
              controller: _taxDeductionController,
              label: 'Tax deduction',
              validator: _validateNumber,
            ),
            const SizedBox(height: 16),
            _NumberField(
              controller: _pensionDeductionController,
              label: 'Pension deduction',
              validator: _validateNumber,
            ),
            const SizedBox(height: 16),
            _NumberField(
              controller: _otherDeductionsController,
              label: 'Other deductions',
              validator: _validateNumber,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed:
                  _isSaving ? null : _calculatePayroll,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.calculate_outlined),
              label: Text(
                _isSaving
                    ? 'Calculating...'
                    : 'Calculate Payroll',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();

    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
}
