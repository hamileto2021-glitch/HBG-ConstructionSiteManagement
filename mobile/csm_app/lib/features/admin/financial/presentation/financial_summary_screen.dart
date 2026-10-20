import 'package:flutter/material.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../data/models/payment.dart';
import '../data/repositories/budget_repository.dart';
import '../data/repositories/expense_repository.dart';
import '../data/repositories/invoice_repository.dart';
import '../data/repositories/payment_repository.dart';
import '../data/repositories/petty_cash_repository.dart';



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
  final _pettyCashRepo = PettyCashRepository();

  bool _loading = true;

  double budget = 0;
  double expenses = 0;
  double invoiced = 0;
  double collected = 0;
  double paid = 0;
  double pettyCash = 0;
  int pettyAccounts = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final budgets = await _budgetRepo.getAll();
    final exps = await _expenseRepo.getAll();
    final invs = await _invoiceRepo.getAll();
    final pays = await _paymentRepo.getAll();
    final accounts = await _pettyCashRepo.getAll();

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
          e.status ==
              PaymentStatus.completed,
    )
        .fold(0, (a, b) => a + b.amount);

    paid = pays
        .where(
          (e) =>
      e.direction ==
          PaymentDirection.outgoing &&
          e.status ==
              PaymentStatus.completed,
    )
        .fold(0, (a, b) => a + b.amount);

    pettyCash = accounts.fold(
      0,
          (a, b) => a + b.currentBalance,
    );

    pettyAccounts =
        accounts.where((e) => e.isActive).length;

    if (!mounted) return;

    setState(() => _loading = false);
  }



  String money(double value) =>
      CurrencyFormatter.etb(value);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child:
          CircularProgressIndicator(),
        ),
      );
    }

    final remaining = budget - expenses;
    final receivable =
        invoiced - collected;
    final payable = expenses - paid;
    final cashFlow = collected - paid;
    final utilization = budget == 0
        ? 0
        : (expenses / budget) * 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
            'Executive Financial Summary'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding:
          const EdgeInsets.all(16),
          children: [
            const Text(
              'Executive KPIs',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics:
              const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [
                _kpi(
                  'Total Budget',
                  money(budget),
                  Icons.account_balance_wallet,
                  Colors.blue,
                ),
                _kpi(
                  'Remaining',
                  money(remaining),
                  Icons.pie_chart,
                  Colors.indigo,
                ),
                _kpi(
                  'Petty Cash',
                  money(pettyCash),
                  Icons.payments,
                  Colors.purple,
                ),
                _kpi(
                  'Cash Flow',
                  money(cashFlow),
                  Icons.trending_up,
                  cashFlow >= 0
                      ? Colors.green
                      : Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 24),

            _section(
              title: 'Budget Performance',
              icon: Icons.analytics,
              child: Column(
                children: [
                  _row(
                    'Total Budget',
                    budget,
                    Colors.blue,
                  ),
                  _row(
                    'Expenses',
                    expenses,
                    Colors.red,
                  ),
                  _row(
                    'Remaining',
                    remaining,
                    Colors.green,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                          'Utilization'),
                      Text(
                        '${utilization.toStringAsFixed(2)}%',
                        style: const TextStyle(
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: utilization / 100,
                    minHeight: 8,
                    borderRadius:
                    BorderRadius.circular(
                        20),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _section(
              title: 'Cash Position',
              icon: Icons.currency_exchange,
              child: Column(
                children: [
                  _row(
                    'Collected',
                    collected,
                    Colors.green,
                  ),
                  _row(
                    'Paid',
                    paid,
                    Colors.deepOrange,
                  ),
                  const Divider(),
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
            ),

            const SizedBox(height: 20),

            _section(
              title: 'Financial Position',
              icon: Icons.bar_chart,
              child: Column(
                children: [
                  _row(
                    'Total Invoiced',
                    invoiced,
                    Colors.orange,
                  ),
                  _row(
                    'Receivable',
                    receivable,
                    Colors.teal,
                  ),
                  _row(
                    'Payable',
                    payable,
                    Colors.purple,
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding:
                    EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor:
                      Colors.purple,
                      child: Icon(
                        Icons.payments,
                        color: Colors.white,
                      ),
                    ),
                    title: const Text(
                        'Petty Cash Accounts'),
                    trailing: Text(
                      pettyAccounts.toString(),
                      style: const TextStyle(
                        fontWeight:
                        FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const Divider(),
                  _row(
                    'Available Petty Cash',
                    pettyCash,
                    Colors.purple,
                    large: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _kpi(
      String title,
      String value,
      IconData icon,
      Color color,
      ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding:
        const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor:
              color.withValues(alpha: 0.12),
              child: Icon(
                icon,
                color: color,
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 2,
              style: TextStyle(
                fontSize: 17,
                color: color,
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding:
        const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
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
      padding:
      const EdgeInsets.symmetric(
          vertical: 8),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment
            .spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize:
              large ? 17 : 15,
              fontWeight:
              FontWeight.w600,
            ),
          ),
          Text(
            money(value),
            style: TextStyle(
              color: color,
              fontSize:
              large ? 18 : 16,
              fontWeight:
              FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}