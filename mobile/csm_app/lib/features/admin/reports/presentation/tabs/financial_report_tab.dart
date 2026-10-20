import 'package:flutter/material.dart';
import '../../../../../core/utils/currency_formatter.dart';


class FinancialReportTab extends StatelessWidget {
  const FinancialReportTab({super.key});

  @override
  Widget build(BuildContext context) {
    const totalBudget = 124000000.0;
    const totalExpenses = 78650000.0;
    const completedPayments = 64200000.0;
    const outstanding = 13250000.0;

    final utilization = totalExpenses / totalBudget;

    String money(double value) =>
        CurrencyFormatter.etb(value);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Financial Analytics',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _FinanceCard(
                title: 'Budget',
                value: money(totalBudget),
                color: Colors.blue,
                icon: Icons.account_balance_wallet,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FinanceCard(
                title: 'Expenses',
                value: money(totalExpenses),
                color: Colors.red,
                icon: Icons.money_off,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _FinanceCard(
                title: 'Payments',
                value: money(completedPayments),
                color: Colors.green,
                icon: Icons.payments,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FinanceCard(
                title: 'Outstanding',
                value: money(outstanding),
                color: Colors.orange,
                icon: Icons.receipt_long,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        const Text(
          'Budget Utilization',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Overall Utilization'),
                    Text(
                      '${(utilization * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: utilization,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 18),

                _SummaryRow(
                  'Remaining Budget',
                  money(totalBudget - totalExpenses),
                ),
                const Divider(),
                _SummaryRow(
                  'Completed Payments',
                  money(completedPayments),
                ),
                const Divider(),
                _SummaryRow(
                  'Outstanding Invoices',
                  money(outstanding),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'Expense Distribution',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: const [
                _ExpenseBar(
                  label: 'Materials',
                  percent: 0.42,
                  color: Colors.blue,
                ),
                SizedBox(height: 12),
                _ExpenseBar(
                  label: 'Labour',
                  percent: 0.28,
                  color: Colors.green,
                ),
                SizedBox(height: 12),
                _ExpenseBar(
                  label: 'Equipment',
                  percent: 0.18,
                  color: Colors.orange,
                ),
                SizedBox(height: 12),
                _ExpenseBar(
                  label: 'Other',
                  percent: 0.12,
                  color: Colors.purple,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FinanceCard extends StatelessWidget {
  const _FinanceCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
      MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _ExpenseBar extends StatelessWidget {
  const _ExpenseBar({
    required this.label,
    required this.percent,
    required this.color,
  });

  final String label;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              '${(percent * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percent,
          color: color,
          minHeight: 8,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }
}