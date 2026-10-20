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

  final _overtimeHoursController =
  TextEditingController(text: '0');

  final _pensionController =
  TextEditingController(text: '0');

  final _taxController =
  TextEditingController(text: '0');

  final _otherDeductionsController =
  TextEditingController(text: '0');


  bool _loadingCalculation = false;


  @override
  void dispose() {
    _overtimeHoursController.dispose();
    _pensionController.dispose();
    _taxController.dispose();
    _otherDeductionsController.dispose();
    super.dispose();
  }

  Future<void> _calculatePayroll() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loadingCalculation = true);

    try {
      final updated = await widget.repository.calculate(
        payrollId: widget.payroll.id,
        overtimeMultiplier: 1.5,
        allowances: 0,
        bonuses: 0,
        taxDeduction:
        double.tryParse(_taxController.text) ?? 0,
        pensionDeduction:
        double.tryParse(_pensionController.text) ?? 0,
        otherDeductions:
        double.tryParse(_otherDeductionsController.text) ?? 0,
      );

      if (!mounted) return;

      Navigator.pop(context, updated);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingCalculation = false);
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
              controller: _overtimeHoursController,
              label: 'Overtime Hours',
              validator: _validateNumber,
            ),

            const SizedBox(height: 16),

            _NumberField(
              controller: _pensionController,
              label: 'Pension Deduction',
              validator: _validateNumber,
            ),

            const SizedBox(height: 16),

            _NumberField(
              controller: _taxController,
              label: 'Tax Deduction',
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
              onPressed: _loadingCalculation ? null : _calculatePayroll,
              icon: _loadingCalculation
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.calculate_outlined),
              label: Text(
                _loadingCalculation
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
