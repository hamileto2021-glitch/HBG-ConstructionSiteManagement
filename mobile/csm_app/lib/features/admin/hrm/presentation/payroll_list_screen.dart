import 'package:flutter/material.dart';

import '../data/models/payroll.dart';
import '../data/repositories/payroll_repository.dart';
import 'payroll_create_screen.dart';
import 'payroll_calculate_screen.dart';
import 'payroll_detail_screen.dart';

class PayrollListScreen extends StatefulWidget {
  const PayrollListScreen({super.key, required this.repository});

  final PayrollRepository repository;

  @override
  State<PayrollListScreen> createState() => _PayrollListScreenState();
}

class _PayrollListScreenState extends State<PayrollListScreen> {
  bool _isLoading = true;
  String? _error;
  List<Payroll> _payrollRecords = [];

  @override
  void initState() {
    super.initState();
    _loadPayroll();
  }

  Future<void> _loadPayroll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final records = await widget.repository.getAll();

      if (!mounted) {
        return;
      }

      setState(() {
        _payrollRecords = records;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openCreateScreen() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PayrollCreateScreen(repository: widget.repository),
      ),
    );

    if (result == true && mounted) {
      await _loadPayroll();
    }
  }

  Future<void> _openCalculateScreen(Payroll payroll) async {
    if (payroll.status != PayrollStatus.draft) {
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PayrollCalculateScreen(
          payroll: payroll,
          repository: widget.repository,
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadPayroll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payroll Management'),
        actions: [
          IconButton(
            tooltip: 'Create Payroll',
            onPressed: _isLoading ? null : _openCreateScreen,
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadPayroll,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPayroll,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading && _payrollRecords.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 300),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null && _payrollRecords.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 16),
          Text(
            'Unable to load payroll records.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadPayroll,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      );
    }

    if (_payrollRecords.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 180),
          Center(child: Text('No payroll records found.')),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _payrollRecords.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildPayrollCard(context, _payrollRecords[index]);
      },
    );
  }

  Widget _buildPayrollCard(BuildContext context, Payroll payroll) {
    return Card(
        child: InkWell(
          onTap: () {
            Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => PayrollDetailScreen(
                  payroll: payroll,
                  repository: widget.repository,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.payments_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    payroll.employeeName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Chip(label: Text(_statusLabel(payroll.status))),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(label: 'Employee', value: payroll.employeeNumber),
            _InfoRow(
              label: 'Period',
              value:
                  '${_formatDate(payroll.periodStart)}'
                  ' - '
                  '${_formatDate(payroll.periodEnd)}',
            ),
            _InfoRow(
              label: 'Gross pay',
              value: _money(payroll.grossPay, payroll.currencyCode),
            ),
            _InfoRow(
              label: 'Total deductions',
              value: _money(payroll.totalDeductions, payroll.currencyCode),
            ),
            _InfoRow(
              label: 'Net pay',
              value: _money(payroll.netPay, payroll.currencyCode),
            ),
            if (payroll.status == PayrollStatus.draft) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    _openCalculateScreen(payroll);
                  },
                  icon: const Icon(Icons.calculate_outlined),
                  label: const Text('Calculate Payroll'),
                ),
              ),
            ],
          ],
        ),
      ),
        ),
    );
  }

  String _statusLabel(PayrollStatus status) {
    switch (status) {
      case PayrollStatus.draft:
        return 'Draft';
      case PayrollStatus.calculated:
        return 'Calculated';
      case PayrollStatus.approved:
        return 'Approved';
      case PayrollStatus.paid:
        return 'Paid';
      case PayrollStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();

    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  String _money(double amount, String currencyCode) {
    return '${amount.toStringAsFixed(2)} '
        '$currencyCode';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
