import 'package:flutter/material.dart';

import '../data/models/stock_balance.dart';
import '../data/repositories/stock_balance_repository.dart';

class StockBalanceListScreen extends StatefulWidget {
  const StockBalanceListScreen({
    super.key,
    required this.repository,
  });

  final StockBalanceRepository repository;

  @override
  State<StockBalanceListScreen> createState() =>
      _StockBalanceListScreenState();
}

class _StockBalanceListScreenState
    extends State<StockBalanceListScreen> {
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

  String _formatQuantity(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }

  String _formatCost(double value) {
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Balance'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadBalances,
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _balances.length,
      itemBuilder: (context, index) {
        return _StockBalanceCard(
          balance: _balances[index],
          formatQuantity: _formatQuantity,
          formatCost: _formatCost,
        );
      },
    );
  }
}

class _StockBalanceCard extends StatelessWidget {
  const _StockBalanceCard({
    required this.balance,
    required this.formatQuantity,
    required this.formatCost,
  });

  final StockBalance balance;
  final String Function(double value) formatQuantity;
  final String Function(double value) formatCost;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLowStock = balance.isLowStock;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        balance.materialCode,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        balance.materialName,
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                if (isLowStock)
                  const Chip(
                    avatar: Icon(
                      Icons.warning_amber_outlined,
                      size: 18,
                    ),
                    label: Text('Low Stock'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Site: ${balance.siteName}',
            ),
            const SizedBox(height: 4),
            Text(
              'Unit: ${balance.unitOfMeasure}',
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _BalanceValue(
                    label: 'On Hand',
                    value:
                        '${formatQuantity(balance.quantityOnHand)} '
                        '${balance.unitOfMeasure}',
                  ),
                ),
                Expanded(
                  child: _BalanceValue(
                    label: 'Reserved',
                    value:
                        '${formatQuantity(balance.quantityReserved)} '
                        '${balance.unitOfMeasure}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _BalanceValue(
              label: 'Available',
              value:
                  '${formatQuantity(balance.availableQuantity)} '
                  '${balance.unitOfMeasure}',
              emphasize: true,
            ),
            const SizedBox(height: 12),
            Text(
              'Reorder Level: '
              '${formatQuantity(balance.reorderLevel)} '
              '${balance.unitOfMeasure}',
            ),
            const SizedBox(height: 4),
            Text(
              'Average Unit Cost: '
              '${formatCost(balance.averageUnitCost)}',
            ),
            if (balance.maximumStockLevel != null) ...[
              const SizedBox(height: 4),
              Text(
                'Maximum Stock Level: '
                '${formatQuantity(balance.maximumStockLevel!)} '
                '${balance.unitOfMeasure}',
              ),
            ],
            if (balance.storageLocation != null &&
                balance.storageLocation!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Storage: ${balance.storageLocation}',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BalanceValue extends StatelessWidget {
  const _BalanceValue({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: emphasize
              ? theme.textTheme.titleLarge
              : theme.textTheme.titleMedium,
        ),
      ],
    );
  }
}
