import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models/payroll.dart';
import '../data/repositories/payroll_repository.dart';
import 'payroll_create_screen.dart';
import 'payroll_calculate_screen.dart';
import 'payroll_detail_screen.dart';

class PayrollListScreen extends StatefulWidget {
  const PayrollListScreen({
    super.key,
    required this.repository,
  });

  final PayrollRepository repository;

  @override
  State<PayrollListScreen> createState() => _PayrollListScreenState();
}

class _PayrollListScreenState extends State<PayrollListScreen> {
  bool _isLoading = true;
  String? _error;
  List<Payroll> _payrollRecords = [];

  final NumberFormat _currency = NumberFormat('#,##0.00');

  String money(double value, String code) =>
      '$code ${_currency.format(value)}';

  int get _draft =>
      _payrollRecords
          .where((e) => e.status == PayrollStatus.draft)
          .length;

  int get _approved =>
      _payrollRecords
          .where((e) => e.status == PayrollStatus.approved)
          .length;

  int get _paid =>
      _payrollRecords
          .where((e) => e.status == PayrollStatus.paid)
          .length;

  double get _totalNet =>
      _payrollRecords.fold(0, (s, e) => s + e.netPay);

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

      if (!mounted) return;

      setState(() {
        _payrollRecords = records;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openCreateScreen() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            PayrollCreateScreen(repository: widget.repository),
      ),
    );

    if (result == true && mounted) {
      await _loadPayroll();
    }
  }

  Future<void> _openCalculateScreen(Payroll payroll) async {
    if (payroll.status != PayrollStatus.draft) return;

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
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
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
          Icon(Icons.payments_outlined, size: 64),
          SizedBox(height: 16),
          Center(
            child: Text('No payroll records found.'),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryCards(),
        const SizedBox(height: 16),
        ..._payrollRecords.map(
              (payroll) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildPayrollCard(context, payroll),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.55,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _SummaryCard(
          title: 'Draft',
          value: '$_draft',
          icon: Icons.edit_note,
          color: Colors.orange,
        ),
        _SummaryCard(
          title: 'Approved',
          value: '$_approved',
          icon: Icons.verified,
          color: Colors.blue,
        ),
        _SummaryCard(
          title: 'Paid',
          value: '$_paid',
          icon: Icons.payments,
          color: Colors.green,
        ),
        _SummaryCard(
          title: 'Net Payroll',
          value: _currency.format(_totalNet),
          icon: Icons.account_balance_wallet,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildPayrollCard(
      BuildContext context,
      Payroll payroll,
      ) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PayrollDetailScreen(
                payroll: payroll,
                repository: widget.repository,
              )
            ),
          );

          if (!mounted) return;
          await _loadPayroll();
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    child: Icon(Icons.payments),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          payroll.employeeName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium,
                        ),
                        Text(
                          payroll.employeeNumber,
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium,
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    backgroundColor:
                    _statusColor(payroll.status)
                        .withValues(alpha: 0.12),
                    label: Text(
                      _statusLabel(payroll.status),
                      style: TextStyle(
                        color:
                        _statusColor(payroll.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _InfoRow(
                label: 'Payroll Period',
                value:
                '${_formatDate(payroll.periodStart)}  →  ${_formatDate(payroll.periodEnd)}',
              ),

              _InfoRow(
                label: 'Regular Hours',
                value:
                payroll.regularHours.toStringAsFixed(1),
              ),

              _InfoRow(
                label: 'Overtime',
                value:
                payroll.overtimeHours.toStringAsFixed(1),
              ),

              const Divider(height: 24),

              _InfoRow(
                label: 'Gross Pay',
                value: money(
                  payroll.grossPay,
                  payroll.currencyCode,
                ),
              ),

              _InfoRow(
                label: 'Deductions',
                value: money(
                  payroll.totalDeductions,
                  payroll.currencyCode,
                ),
              ),

              const Divider(),

              _InfoRow(
                label: 'NET PAY',
                value: money(
                  payroll.netPay,
                  payroll.currencyCode,
                ),
                bold: true,
              ),

              if (payroll.status ==
                  PayrollStatus.draft) ...[
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () =>
                        _openCalculateScreen(payroll),
                    icon: const Icon(Icons.calculate),
                    label:
                    const Text('Calculate Payroll'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(PayrollStatus status) {
    switch (status) {
      case PayrollStatus.draft:
        return Colors.orange;
      case PayrollStatus.calculated:
        return Colors.blue;
      case PayrollStatus.approved:
        return Colors.indigo;
      case PayrollStatus.paid:
        return Colors.green;
      case PayrollStatus.cancelled:
        return Colors.red;
    }
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
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall,
            ),
            Text(title),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: bold
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontSize: bold ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}