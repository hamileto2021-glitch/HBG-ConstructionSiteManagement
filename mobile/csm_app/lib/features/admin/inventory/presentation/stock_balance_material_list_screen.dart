import 'package:flutter/material.dart';

import '../data/models/stock_balance.dart';
import '../data/repositories/stock_balance_repository.dart';
import 'stock_balance_detail_screen.dart';

class StockBalanceMaterialListScreen extends StatefulWidget {
  const StockBalanceMaterialListScreen({
    super.key,
    required this.repository,
    required this.constructionSiteId,
    required this.siteName,
  });

  final StockBalanceRepository repository;
  final String constructionSiteId;
  final String siteName;

  @override
  State<StockBalanceMaterialListScreen> createState() =>
      _StockBalanceMaterialListScreenState();
}

class _StockBalanceMaterialListScreenState
    extends State<StockBalanceMaterialListScreen> {
  List<StockBalance> _balances = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBalances();
  }

  Future<void> _loadBalances() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final balances = await widget.repository.getAll(
        constructionSiteId:
            widget.constructionSiteId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _balances = balances;
        _isLoading = false;
      });
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

  String _formatQuantity(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.siteName),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                _isLoading ? null : _loadBalances,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadBalances,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading && _balances.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 300),
          Center(
            child: CircularProgressIndicator(),
          ),
        ],
      );
    }

    if (_error != null && _balances.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 220),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _loadBalances,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_balances.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 220),
          Center(
            child: Text(
              'No stock balances found for this site.',
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _balances.length,
      itemBuilder: (context, index) {
        final balance = _balances[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.inventory_2_outlined),
            ),
            title: Text(
              balance.materialCode,
            ),
            subtitle: Text(
              balance.materialName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                Text(
                  '${_formatQuantity(balance.quantityOnHand)} '
                  '${balance.unitOfMeasure}',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium,
                ),
                const Text('On Hand'),
              ],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      StockBalanceDetailScreen(
                    balance: balance,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
