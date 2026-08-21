import 'package:flutter/material.dart';

import '../data/models/stock_balance.dart';

class StockBalanceDetailScreen extends StatelessWidget {
  const StockBalanceDetailScreen({
    super.key,
    required this.balance,
  });

  final StockBalance balance;

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
    final theme = Theme.of(context);
    final isLowStock = balance.isLowStock;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Balance'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            balance.materialCode,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            balance.materialName,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Site: ${balance.siteName}',
          ),
          const SizedBox(height: 4),
          Text(
            'Unit: ${balance.unitOfMeasure}',
          ),
          if (isLowStock) ...[
            const SizedBox(height: 12),
            const Chip(
              avatar: Icon(
                Icons.warning_amber_outlined,
              ),
              label: Text('Low Stock'),
            ),
          ],
          const SizedBox(height: 24),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Balance',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  _BalanceRow(
                    label: 'On Hand',
                    value:
                        '${_formatQuantity(balance.quantityOnHand)} '
                        '${balance.unitOfMeasure}',
                    emphasize: true,
                  ),
                  const Divider(height: 24),
                  _BalanceRow(
                    label: 'Reserved',
                    value:
                        '${_formatQuantity(balance.quantityReserved)} '
                        '${balance.unitOfMeasure}',
                  ),
                  const Divider(height: 24),
                  _BalanceRow(
                    label: 'Available',
                    value:
                        '${_formatQuantity(balance.availableQuantity)} '
                        '${balance.unitOfMeasure}',
                    emphasize: true,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stock Controls',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _BalanceRow(
                    label: 'Reorder Level',
                    value:
                        '${_formatQuantity(balance.reorderLevel)} '
                        '${balance.unitOfMeasure}',
                  ),
                  if (balance.maximumStockLevel != null) ...[
                    const Divider(height: 24),
                    _BalanceRow(
                      label: 'Maximum Stock Level',
                      value:
                          '${_formatQuantity(balance.maximumStockLevel!)} '
                          '${balance.unitOfMeasure}',
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cost & Storage',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _BalanceRow(
                    label: 'Average Unit Cost',
                    value:
                        _formatCost(
                          balance.averageUnitCost,
                        ),
                  ),
                  if (balance.storageLocation != null &&
                      balance.storageLocation!
                          .trim()
                          .isNotEmpty) ...[
                    const Divider(height: 24),
                    _BalanceRow(
                      label: 'Storage Location',
                      value:
                          balance.storageLocation!,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({
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

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: emphasize
                ? theme.textTheme.titleLarge
                : theme.textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}
