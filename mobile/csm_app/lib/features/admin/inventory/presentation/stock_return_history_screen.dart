import 'package:flutter/material.dart';

import '../data/models/stock_movement.dart';
import '../data/repositories/stock_movement_repository.dart';

class StockReturnHistoryScreen extends StatefulWidget {
  const StockReturnHistoryScreen({
    super.key,
    required this.repository,
  });

  final StockMovementRepository repository;

  @override
  State<StockReturnHistoryScreen> createState() =>
      _StockReturnHistoryScreenState();
}

class _StockReturnHistoryScreenState
    extends State<StockReturnHistoryScreen> {
  final List<StockMovement> _returns = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReturns();
  }

  Future<void> _loadReturns() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final returns = await widget.repository.getAll(
        movementType: StockMovementType.returnMovement,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _returns
          ..clear()
          ..addAll(returns);
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

  String _formatDate(DateTime value) {
    final local = value.toLocal();

    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  String _formatQuantity(StockMovement movement) {
    return '${movement.quantity} ${movement.unitOfMeasure}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Material Return Audit Trail'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadReturns,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadReturns,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading && _returns.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 300),
          Center(
            child: CircularProgressIndicator(),
          ),
        ],
      );
    }

    if (_error != null && _returns.isEmpty) {
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
                    onPressed: _loadReturns,
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

    if (_returns.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 220),
          Center(
            child: Text(
              'No material returns found.',
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _returns.length,
      itemBuilder: (context, index) {
        final movement = _returns[index];

        return _StockReturnAuditCard(
          movement: movement,
          returnDate: _formatDate(
            movement.movementDateUtc,
          ),
          quantity: _formatQuantity(movement),
        );
      },
    );
  }
}

class _StockReturnAuditCard extends StatelessWidget {
  const _StockReturnAuditCard({
    required this.movement,
    required this.returnDate,
    required this.quantity,
  });

  final StockMovement movement;
  final String returnDate;
  final String quantity;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.keyboard_return_outlined,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    movement.materialCode,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge,
                  ),
                ),
                const Chip(
                  label: Text('Return'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              movement.materialName,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Site: ${movement.siteName}',
            ),
            const SizedBox(height: 4),
            Text(
              'Return Date: $returnDate',
            ),
            const SizedBox(height: 4),
            Text(
              'Returned Quantity: $quantity',
            ),
            if (movement.stockBalanceBefore != null) ...[
              const SizedBox(height: 4),
              Text(
                'Stock Balance Before Return: '
                    '${movement.stockBalanceBefore} '
                    '${movement.unitOfMeasure}',
              ),
            ],
            if (movement.stockBalanceAfter != null) ...[
              const SizedBox(height: 4),
              Text(
                'Stock Balance After Return: '
                    '${movement.stockBalanceAfter} '
                    '${movement.unitOfMeasure}',
              ),
            ],
            if (movement.referenceNumber != null &&
                movement.referenceNumber!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Reference: ${movement.referenceNumber}',
              ),
            ],
            if (movement.referenceId != null) ...[
              const SizedBox(height: 4),
              Text(
                'Original Issue: ${movement.referenceId}',
              ),
            ],
            if (movement.unitCost != null) ...[
              const SizedBox(height: 4),
              Text(
                'Unit Cost: ${movement.unitCost}',
              ),
            ],
            if (movement.totalCost != null) ...[
              const SizedBox(height: 4),
              Text(
                'Total Cost: ${movement.totalCost}',
              ),
            ],
            if (movement.remarks != null &&
                movement.remarks!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 4),
              Text(
                'Audit Details',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall,
              ),
              const SizedBox(height: 4),
              Text(movement.remarks!),
            ],
          ],
        ),
      ),
    );
  }
}
