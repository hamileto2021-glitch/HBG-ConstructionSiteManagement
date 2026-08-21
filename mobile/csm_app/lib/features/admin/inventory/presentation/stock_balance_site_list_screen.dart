import 'package:flutter/material.dart';

import '../data/models/stock_balance.dart';
import '../data/repositories/stock_balance_repository.dart';
import 'stock_balance_material_list_screen.dart';

class StockBalanceSiteListScreen extends StatefulWidget {
  const StockBalanceSiteListScreen({
    super.key,
    required this.repository,
  });

  final StockBalanceRepository repository;

  @override
  State<StockBalanceSiteListScreen> createState() =>
      _StockBalanceSiteListScreenState();
}

class _StockBalanceSiteListScreenState
    extends State<StockBalanceSiteListScreen> {
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
      final balances = await widget.repository.getAll();

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

  List<String> get _siteIds {
    final ids = <String>{};

    for (final balance in _balances) {
      ids.add(balance.constructionSiteId);
    }

    return ids.toList();
  }

  String _siteName(String siteId) {
    return _balances
        .firstWhere(
          (balance) =>
              balance.constructionSiteId == siteId,
        )
        .siteName;
  }

  int _materialCount(String siteId) {
    return _balances
        .where(
          (balance) =>
              balance.constructionSiteId == siteId,
        )
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Balance'),
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
              'No stock balances found.',
            ),
          ),
        ],
      );
    }

    final siteIds = _siteIds;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: siteIds.length,
      itemBuilder: (context, index) {
        final siteId = siteIds[index];
        final siteName = _siteName(siteId);
        final materialCount = _materialCount(siteId);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.location_city_outlined),
            ),
            title: Text(siteName),
            subtitle: Text(
              '$materialCount material'
              '${materialCount == 1 ? '' : 's'}',
            ),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      StockBalanceMaterialListScreen(
                    repository: widget.repository,
                    constructionSiteId: siteId,
                    siteName: siteName,
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
