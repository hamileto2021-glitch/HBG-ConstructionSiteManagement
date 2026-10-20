import 'package:flutter/material.dart';

import '../data/models/petty_cash_account.dart';
import '../data/models/petty_cash_transaction.dart';
import '../data/repositories/petty_cash_transaction_repository.dart';
import 'petty_cash_transaction_create_screen.dart';

class PettyCashTransactionListScreen extends StatefulWidget {
  const PettyCashTransactionListScreen({
    super.key,
    required this.account,
  });

  final PettyCashAccount account;

  @override
  State<PettyCashTransactionListScreen> createState() =>
      _PettyCashTransactionListScreenState();
}

class _PettyCashTransactionListScreenState
    extends State<PettyCashTransactionListScreen> {
  final _repository = PettyCashTransactionRepository();

  bool _loading = true;
  List<PettyCashTransaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _repository.getByAccount(
        widget.account.id,
      );

      if (!mounted) return;

      setState(() {
        _transactions = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  String _money(double value) => value.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Petty Cash Ledger'),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PettyCashTransactionCreateScreen(
                    account: widget.account,
                  ),
            ),
          );

          if (created == true) {
            _load();
          }
        },
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _transactions.isEmpty
          ? const Center(
        child: Text(
          'No transactions recorded',
        ),
      )
          : ListView.builder(
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final tx = _transactions[index];

          final isIn =
              tx.transactionType ==
                  PettyCashTransactionType.cashIn;

          return Card(
            margin: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isIn
                    ? Colors.green
                    : Colors.red,
                child: Icon(
                  isIn
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                  color: Colors.white,
                ),
              ),
              title: Text(tx.description),
              subtitle: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(tx.referenceNumber),
                  Text(
                    'Balance: ETB ${_money(tx.balanceAfter)}',
                  ),
                ],
              ),
              trailing: Text(
                '${isIn ? '+' : '-'}ETB ${_money(tx.amount)}',
                style: TextStyle(
                  color: isIn
                      ? Colors.green
                      : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}