import 'package:flutter/material.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../data/models/petty_cash_account.dart';
import '../data/repositories/petty_cash_repository.dart';
import 'petty_cash_transaction_list_screen.dart';

class PettyCashAccountDetailScreen extends StatefulWidget {
  const PettyCashAccountDetailScreen({
    super.key,
    required this.account,
  });

  final PettyCashAccount account;

  @override
  State<PettyCashAccountDetailScreen> createState() =>
      _PettyCashAccountDetailScreenState();
}

class _PettyCashAccountDetailScreenState
    extends State<PettyCashAccountDetailScreen> {
  final _repository = PettyCashRepository();

  late PettyCashAccount _account;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _account = widget.account;
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final latest = await _repository.getById(_account.id);

      if (!mounted) return;

      setState(() {
        _account = latest;
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

  String money(double value) =>
      CurrencyFormatter.etb(value);

  Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Petty Cash Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Colors.green.shade700,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      _account.accountCode,
                      style: const TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _account.accountName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'CURRENT BALANCE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'ETB ${money(_account.currentBalance)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    infoRow('Site', _account.siteName),
                    infoRow(
                      'Account Code',
                      _account.accountCode,
                    ),
                    infoRow(
                      'Account Name',
                      _account.accountName,
                    ),
                    infoRow(
                      'Status',
                      _account.isActive
                          ? 'Active'
                          : 'Inactive',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Balance Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    infoRow(
                      'Opening Balance',
                      'ETB ${money(_account.openingBalance)}',
                    ),
                    infoRow(
                      'Current Balance',
                      'ETB ${money(_account.currentBalance)}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        PettyCashTransactionListScreen(
                          account: _account,
                        ),
                  ),
                );

                await _refresh();
              },
              icon: const Icon(Icons.receipt_long),
              label: const Text('View Cash Ledger'),
            ),
          ],
        ),
      ),
    );
  }
}