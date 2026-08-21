import 'package:flutter/material.dart';

import '../data/models/expense.dart';
import '../data/repositories/expense_repository.dart';
import 'expense_create_screen.dart';

class ExpenseDetailScreen extends StatefulWidget {
  const ExpenseDetailScreen({
    super.key,
    required this.expense,
    required this.repository,
  });

  final Expense expense;
  final ExpenseRepository repository;

  @override
  State<ExpenseDetailScreen> createState() =>
      _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState
    extends State<ExpenseDetailScreen> {
  late Expense _expense;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _expense = widget.expense;
  }

  List<ExpenseStatus> _availableTransitions() {
    switch (_expense.status) {
      case ExpenseStatus.draft:
        return [
          ExpenseStatus.submitted,
          ExpenseStatus.cancelled,
        ];
      case ExpenseStatus.submitted:
        return [
          ExpenseStatus.approved,
          ExpenseStatus.rejected,
          ExpenseStatus.cancelled,
        ];
      case ExpenseStatus.approved:
        return [ExpenseStatus.paid];
      case ExpenseStatus.rejected:
        return [
          ExpenseStatus.submitted,
          ExpenseStatus.cancelled,
        ];
      case ExpenseStatus.paid:
      case ExpenseStatus.cancelled:
        return [];
    }
  }

  Future<void> _refresh() async {
    final refreshed = await widget.repository.getById(
      _expense.id,
    );

    if (!mounted) return;

    setState(() {
      _expense = refreshed;
    });
  }

  Future<void> _changeStatus(
    ExpenseStatus nextStatus,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Status'),
          content: Text(
            'Change expense status to ${nextStatus.displayName}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await widget.repository.changeStatus(
        expenseId: _expense.id,
        status: nextStatus,
      );

      await _refresh();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status changed to ${nextStatus.displayName}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _money(double value) =>
      value.toStringAsFixed(2);

  bool get _canEdit =>
      _expense.status != ExpenseStatus.paid &&
      _expense.status != ExpenseStatus.cancelled;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_expense.expenseNumber),
        actions: [
          if (_canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final updated =
                    await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => ExpenseCreateScreen(
                      repository: widget.repository,
                      expense: _expense,
                    ),
                  ),
                );

                if (updated == true) {
                  await _refresh();
                }
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _expense.expenseNumber,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge,
                            ),
                          ),
                          Chip(
                            label: Text(
                              _expense.status.displayName,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _InfoRow(
                        label: 'Description',
                        value: _expense.description,
                      ),
                      _InfoRow(
                        label: 'Date',
                        value: _expense.expenseDate
                            .toIso8601String()
                            .split('T')
                            .first,
                      ),
                      _InfoRow(
                        label: 'Amount',
                        value:
                            '${_money(_expense.amount)} ${_expense.currencyCode}',
                      ),
                      _InfoRow(
                        label: 'Tax',
                        value:
                            '${_money(_expense.taxAmount)} ${_expense.currencyCode}',
                      ),
                      _InfoRow(
                        label: 'Exchange',
                        value: _expense.exchangeRate
                            .toStringAsFixed(2),
                      ),
                      _InfoRow(
                        label: 'Reference',
                        value: _expense.referenceNumber ??
                            '—',
                      ),
                      _InfoRow(
                        label: 'Receipt',
                        value: _expense
                                .receiptDocumentUrl ??
                            '—',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_availableTransitions().isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Change Status',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableTransitions()
                              .map(
                                (status) =>
                                    FilledButton(
                                  onPressed:
                                      _isLoading
                                          ? null
                                          : () =>
                                              _changeStatus(
                                            status,
                                          ),
                                  child: Text(
                                    status.displayName,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
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
            width: 96,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium,
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}