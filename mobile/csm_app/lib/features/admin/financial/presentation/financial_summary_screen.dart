import 'package:flutter/material.dart';

import '../data/models/payment.dart';
import '../data/repositories/budget_repository.dart';
import '../data/repositories/expense_repository.dart';
import '../data/repositories/invoice_repository.dart';
import '../data/repositories/payment_repository.dart';

class FinancialSummaryScreen extends StatefulWidget {
  const FinancialSummaryScreen({super.key});

  @override
  State<FinancialSummaryScreen> createState() =>
      _FinancialSummaryScreenState();
}

class _FinancialSummaryScreenState
    extends State<FinancialSummaryScreen> {
  final _budgetRepo = BudgetRepository();
  final _expenseRepo = ExpenseRepository();
  final _invoiceRepo = InvoiceRepository();
  final _paymentRepo = PaymentRepository();

  bool _loading = true;

  double budget = 0;
  double expenses = 0;
  double invoiced = 0;
  double collected = 0;
  double paid = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final budgets = await _budgetRepo.getAll();
    final exps = await _expenseRepo.getAll();
    final invs = await _invoiceRepo.getAll();
    final pays = await _paymentRepo.getAll();

    budget =
        budgets.fold(0, (a, b) => a + b.totalAmount);

    expenses = exps.fold(
      0,
          (a, b) => a + b.amount + b.taxAmount,
    );

    invoiced =
        invs.fold(0, (a, b) => a + b.totalAmount);

    collected = pays
        .where(
          (e) =>
      e.direction ==
          PaymentDirection.incoming &&
          e.status == PaymentStatus.completed,
    )
        .fold(0, (a, b) => a + b.amount);

    paid = pays
        .where(
          (e) =>
      e.direction ==
          PaymentDirection.outgoing &&
          e.status == PaymentStatus.completed,
    )
        .fold(0, (a, b) => a + b.amount);

    if (!mounted) return;

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final remainingBudget = budget - expenses;
    final receivable = invoiced - collected;
    final payable = expenses - paid;
    final cashFlow = collected - paid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Summary'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _row(
            'Total Budget',
            budget,
            Colors.blue,
          ),
          _row(
            'Total Expenses',
            expenses,
            Colors.red,
          ),
          _row(
            'Remaining Budget',
            remainingBudget,
            Colors.indigo,
          ),
          const Divider(),
          _row(
            'Total Invoiced',
            invoiced,
            Colors.orange,
          ),
          _row(
            'Collected',
            collected,
            Colors.green,
          ),
          _row(
            'Receivable',
            receivable,
            Colors.teal,
          ),
          const Divider(),
          _row(
            'Paid',
            paid,
            Colors.deepOrange,
          ),
          _row(
            'Payable',
            payable,
            Colors.purple,
          ),
          const Divider(thickness: 1.5),
          _row(
            'Net Cash Flow',
            cashFlow,
            cashFlow >= 0
                ? Colors.green
                : Colors.red,
            large: true,
          ),
        ],
      ),
    );
  }

  Widget _row(
      String title,
      double value,
      Color color, {
        bool large = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
      ),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: large ? 18 : 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              color: color,
              fontSize: large ? 22 : 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}