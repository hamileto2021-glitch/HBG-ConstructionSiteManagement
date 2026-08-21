import 'package:flutter/material.dart';

import '../data/models/payment.dart';
import '../data/repositories/budget_repository.dart';
import '../data/repositories/cost_code_repository.dart';
import '../data/repositories/expense_repository.dart';
import '../data/repositories/invoice_repository.dart';
import '../data/repositories/payment_repository.dart';
import 'budget_list_screen.dart';
import 'cost_code_list_screen.dart';
import 'expense_list_screen.dart';
import 'invoice_list_screen.dart';
import 'payment_list_screen.dart';
import 'financial_summary_screen.dart';

class FinancialDashboardScreen extends StatefulWidget {
  const FinancialDashboardScreen({super.key});

  @override
  State<FinancialDashboardScreen> createState() =>
      _FinancialDashboardScreenState();
}

class _FinancialDashboardScreenState
    extends State<FinancialDashboardScreen> {
  final _budgetRepository = BudgetRepository();
  final _expenseRepository = ExpenseRepository();
  final _invoiceRepository = InvoiceRepository();
  final _paymentRepository = PaymentRepository();

  bool _loading = true;

  double _totalBudget = 0;
  double _totalExpenses = 0;
  double _totalInvoiced = 0;
  double _totalCollected = 0;
  double _totalPaid = 0;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final budgets = await _budgetRepository.getAll();
      final expenses = await _expenseRepository.getAll();
      final invoices = await _invoiceRepository.getAll();
      final payments = await _paymentRepository.getAll();

      _totalBudget =
          budgets.fold(0, (sum, e) => sum + e.totalAmount);

      _totalExpenses =
          expenses.fold(0, (sum, e) => sum + e.amount + e.taxAmount);

      _totalInvoiced =
          invoices.fold(0, (sum, e) => sum + e.totalAmount);

      _totalCollected = payments
          .where(
            (p) =>
        p.direction ==
            PaymentDirection.incoming &&
            p.status == PaymentStatus.completed,
      )
          .fold(0, (sum, p) => sum + p.amount);

      _totalPaid = payments
          .where(
            (p) =>
        p.direction ==
            PaymentDirection.outgoing &&
            p.status == PaymentStatus.completed,
      )
          .fold(0, (sum, p) => sum + p.amount);

      if (!mounted) return;

      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;

      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Financial Management',
          style:
          Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Manage cost codes, budgets, expenses, invoices, payments, and financial reporting.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),

        const SizedBox(height: 20),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics:
          const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.25,
          children: [
            _SummaryCard(
              title: 'Budget',
              value: _totalBudget,
              icon: Icons.account_balance_wallet,
              color: Colors.blue,
            ),
            _SummaryCard(
              title: 'Expenses',
              value: _totalExpenses,
              icon: Icons.receipt_long,
              color: Colors.red,
            ),
            _SummaryCard(
              title: 'Invoiced',
              value: _totalInvoiced,
              icon: Icons.description,
              color: Colors.orange,
            ),
            _SummaryCard(
              title: 'Collected',
              value: _totalCollected,
              icon: Icons.arrow_downward,
              color: Colors.green,
            ),
            _SummaryCard(
              title: 'Paid',
              value: _totalPaid,
              icon: Icons.arrow_upward,
              color: Colors.deepOrange,
            ),
            _SummaryCard(
              title: 'Cash Flow',
              value: _totalCollected - _totalPaid,
              icon: Icons.trending_up,
              color: Colors.teal,
            ),
          ],
        ),

        const SizedBox(height: 24),

        _ModuleCard(
          icon: Icons.account_tree_outlined,
          title: 'Cost Codes',
          description:
          'Manage financial cost codes, descriptions, parent codes, and active status.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CostCodeListScreen(
                  repository: CostCodeRepository(),
                ),
              ),
            );
          },
        ),

        _ModuleCard(
          icon:
          Icons.account_balance_wallet_outlined,
          title: 'Budgets',
          description:
          'Manage construction budgets, budget lines, approvals, revisions, and status.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BudgetListScreen(
                  repository: BudgetRepository(),
                ),
              ),
            );
          },
        ),

        _ModuleCard(
          icon: Icons.receipt_long_outlined,
          title: 'Expenses',
          description:
          'Record, submit, approve, reject, and track project and site expenses.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ExpenseListScreen(
                  repository: ExpenseRepository(),
                ),
              ),
            );
          },
        ),

        _ModuleCard(
          icon: Icons.description_outlined,
          title: 'Invoices',
          description:
          'Manage client invoices and vendor bills, invoice lines, and payment status.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => InvoiceListScreen(
                  repository: InvoiceRepository(),
                ),
              ),
            );
          },
        ),

        _ModuleCard(
          icon: Icons.payments_outlined,
          title: 'Payments',
          description:
          'Record incoming and outgoing payments and track their status.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PaymentListScreen(
                  repository: PaymentRepository(),
                ),
              ),
            );
          },
        ),

        _ModuleCard(
          icon: Icons.analytics_outlined,
          title: 'Financial Summary',
          description:
          'Review budgets, expenses, invoices, payments, receivables, and payables.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                const FinancialSummaryScreen(),
              ),
            );
          },
        ),
      ],
    );
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
  final double value;
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
              title,
              style:
              Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(
              value.toStringAsFixed(2),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(description),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}