import 'package:flutter/material.dart';

import '../data/models/payroll.dart';
import '../data/repositories/payroll_repository.dart';

class PayrollDetailScreen extends StatefulWidget {
  const PayrollDetailScreen({
    super.key,
    required this.payroll,
    required this.repository,
  });

  final Payroll payroll;
  final PayrollRepository repository;

  @override
  State<PayrollDetailScreen> createState() =>
      _PayrollDetailScreenState();
}

class _PayrollDetailScreenState
    extends State<PayrollDetailScreen> {
  late Payroll _payroll;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _payroll = widget.payroll;
  }

  Future<void> _approvePayroll() async {
    if (_payroll.status != PayrollStatus.calculated) {
      return;
    }

    final remarks = await _remarksDialog(
      title: 'Approve Payroll',
      label: 'Approval remarks',
      confirmText: 'Approve',
    );

    if (!mounted || remarks == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final updated = await widget.repository.approve(
        payrollId: _payroll.id,
        remarks: remarks.isEmpty ? null : remarks,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _payroll = updated;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payroll approved successfully.',
          ),
        ),
      );
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

  Future<void> _markPaid() async {
    if (_payroll.status != PayrollStatus.approved) {
      return;
    }

    final paymentReference =
        await _paymentReferenceDialog();

    if (!mounted || paymentReference == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final updated =
          await widget.repository.markPaid(
        payrollId: _payroll.id,
        paymentReference: paymentReference,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _payroll = updated;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payroll marked as paid successfully.',
          ),
        ),
      );
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

  Future<void> _cancelPayroll() async {
    if (_payroll.status == PayrollStatus.paid ||
        _payroll.status == PayrollStatus.cancelled) {
      return;
    }

    final remarks = await _remarksDialog(
      title: 'Cancel Payroll',
      label: 'Cancellation remarks',
      confirmText: 'Cancel Payroll',
    );

    if (!mounted || remarks == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final updated = await widget.repository.cancel(
        payrollId: _payroll.id,
        remarks: remarks.isEmpty ? null : remarks,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _payroll = updated;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payroll cancelled successfully.',
          ),
        ),
      );
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

  Future<String?> _remarksDialog({
    required String title,
    required String label,
    required String confirmText,
  }) async {
    var remarks = '';

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            maxLines: 4,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              remarks = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(
                  remarks.trim(),
                );
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _paymentReferenceDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        var paymentReference = '';

        return AlertDialog(
          title: const Text('Mark Payroll Paid'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Payment reference',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              paymentReference = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () {
                final value = paymentReference.trim();

                if (value.isEmpty) {
                  return;
                }

                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('Mark Paid'),
            ),
          ],
        );
      },
    );

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payroll Details'),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildPaySection(context),
            const SizedBox(height: 20),
            _buildDeductionSection(context),
            const SizedBox(height: 20),
            _buildStatusSection(context),
            if (_payroll.adjustments.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildAdjustmentsSection(context),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Future<void> _reload() async {
    try {
      final updated =
          await widget.repository.getById(_payroll.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _payroll = updated;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString();
      });
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  size: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _payroll.employeeName,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall,
                  ),
                ),
                Chip(
                  label: Text(
                    _statusLabel(_payroll.status),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Employee',
              value: _payroll.employeeNumber,
            ),
            _InfoRow(
              label: 'Period',
              value:
                  '${_formatDate(_payroll.periodStart)}'
                  ' - '
                  '${_formatDate(_payroll.periodEnd)}',
            ),
            _InfoRow(
              label: 'Currency',
              value: _payroll.currencyCode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaySection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Pay',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Base pay',
              value: _money(_payroll.basePay),
            ),
            _InfoRow(
              label: 'Regular hours',
              value: _payroll.regularHours
                  .toStringAsFixed(2),
            ),
            _InfoRow(
              label: 'Overtime hours',
              value: _payroll.overtimeHours
                  .toStringAsFixed(2),
            ),
            _InfoRow(
              label: 'Overtime pay',
              value: _money(_payroll.overtimePay),
            ),
            _InfoRow(
              label: 'Allowances',
              value: _money(_payroll.allowances),
            ),
            _InfoRow(
              label: 'Bonuses',
              value: _money(_payroll.bonuses),
            ),
            _InfoRow(
              label: 'Gross pay',
              value: _money(_payroll.grossPay),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeductionSection(
    BuildContext context,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Deductions',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Tax',
              value: _money(_payroll.taxDeduction),
            ),
            _InfoRow(
              label: 'Pension',
              value: _money(
                _payroll.pensionDeduction,
              ),
            ),
            _InfoRow(
              label: 'Other deductions',
              value: _money(
                _payroll.otherDeductions,
              ),
            ),
            _InfoRow(
              label: 'Total deductions',
              value: _money(
                _payroll.totalDeductions,
              ),
            ),
            const Divider(height: 24),
            _InfoRow(
              label: 'Net pay',
              value: _money(_payroll.netPay),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(
    BuildContext context,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Status Information',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Status',
              value: _statusLabel(_payroll.status),
            ),
            if (_payroll.approvedBy != null)
              _InfoRow(
                label: 'Approved by',
                value: _payroll.approvedBy!,
              ),
            if (_payroll.approvedAtUtc != null)
              _InfoRow(
                label: 'Approved at',
                value: _formatDateTime(
                  _payroll.approvedAtUtc!,
                ),
              ),
            if (_payroll.paidAtUtc != null)
              _InfoRow(
                label: 'Paid at',
                value: _formatDateTime(
                  _payroll.paidAtUtc!,
                ),
              ),
            if (_payroll.paymentReference != null)
              _InfoRow(
                label: 'Payment reference',
                value: _payroll.paymentReference!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjustmentsSection(
    BuildContext context,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Adjustments',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
            ),
            const SizedBox(height: 12),
            ..._payroll.adjustments.map(
              (adjustment) => _InfoRow(
                label: adjustment.type,
                value:
                    '${adjustment.description} - '
                    '${_money(adjustment.amount)}'
                    '${adjustment.isDeduction ? ' (Deduction)' : ''}',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    if (_payroll.status == PayrollStatus.calculated) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _isLoading
              ? null
              : _approvePayroll,
          icon: const Icon(Icons.check),
          label: const Text('Approve Payroll'),
        ),
      );
    }

    if (_payroll.status == PayrollStatus.approved) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed:
              _isLoading ? null : _markPaid,
          icon: const Icon(
            Icons.payments_outlined,
          ),
          label: const Text('Mark Payroll Paid'),
        ),
      );
    }

    if (_payroll.status != PayrollStatus.paid &&
        _payroll.status != PayrollStatus.cancelled) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed:
              _isLoading ? null : _cancelPayroll,
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Cancel Payroll'),
        ),
      );
    }

    return const SizedBox.shrink();
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

  String _formatDateTime(DateTime date) {
    final local = date.toLocal();

    return '${_formatDate(local)} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  String _money(double amount) {
    return '${amount.toStringAsFixed(2)} '
        '${_payroll.currencyCode}';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge,
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
