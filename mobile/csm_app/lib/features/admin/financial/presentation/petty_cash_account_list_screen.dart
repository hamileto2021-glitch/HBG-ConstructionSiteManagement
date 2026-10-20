import 'package:flutter/material.dart';

import '../data/models/petty_cash_account.dart';
import '../data/repositories/petty_cash_repository.dart';
import 'petty_cash_account_create_screen.dart';
import 'petty_cash_account_detail_screen.dart';


class PettyCashAccountListScreen extends StatefulWidget {
  const PettyCashAccountListScreen({
    super.key,
    required this.repository,
  });

  final PettyCashRepository repository;

  @override
  State<PettyCashAccountListScreen> createState() =>
      _PettyCashAccountListScreenState();
}

class _PettyCashAccountListScreenState
    extends State<PettyCashAccountListScreen> {
  bool _loading = true;
  List<PettyCashAccount> _accounts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await widget.repository.getAll();

      if (!mounted) return;

      setState(() {
        _accounts = data;
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

  String _money(double value) =>
      value.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Petty Cash Accounts'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PettyCashAccountCreateScreen(
                    repository: widget.repository,
                  ),
            ),
          );

          if (created != null) {
            _load();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh: _load,
        child: _accounts.isEmpty
            ? ListView(
          children: const [
            SizedBox(height: 120),
            Center(
              child: Text(
                'No Petty Cash Accounts',
              ),
            ),
          ],
        )
            : ListView.builder(
          itemCount: _accounts.length,
          itemBuilder: (context, index) {
            final item = _accounts[index];

            return Card(
              margin:
              const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(
                    Icons.account_balance_wallet,
                  ),
                ),
                title: Text(
                  '${item.accountCode} • ${item.accountName}',
                ),
                subtitle: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(item.siteName),
                    const SizedBox(height: 2),
                    Text(
                      'Opening: ETB ${_money(item.openingBalance)}',
                    ),
                    Text(
                      'Current: ETB ${_money(item.currentBalance)}',
                      style: const TextStyle(
                        fontWeight:
                        FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                trailing: Icon(
                  item.isActive
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: item.isActive
                      ? Colors.green
                      : Colors.red,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PettyCashAccountDetailScreen(
                            account: item,
                          ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}