import 'package:flutter/material.dart';

import '../data/models/stock_movement.dart';
import '../data/repositories/stock_movement_repository.dart';

class StockMovementListScreen extends StatefulWidget {
  const StockMovementListScreen({
    super.key,
    required this.repository,
  });

  final StockMovementRepository repository;

  @override
  State<StockMovementListScreen> createState() =>
      _StockMovementListScreenState();
}

class _StockMovementListScreenState
    extends State<StockMovementListScreen> {
  final List<StockMovement> _movements = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMovements();
  }

  Future<void> _loadMovements() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final movements = await widget.repository.getAll();

      if (!mounted) {
        return;
      }

      setState(() {
        _movements
          ..clear()
          ..addAll(movements);
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

  String _movementTypeLabel(
      StockMovementType type,
      ) {
    switch (type) {
      case StockMovementType.openingBalance:
        return 'Opening Balance';
      case StockMovementType.goodsReceipt:
        return 'Goods Receipt';
      case StockMovementType.issue:
        return 'Issue';
      case StockMovementType.returnMovement:
        return 'Return';
      case StockMovementType.transferIn:
        return 'Transfer In';
      case StockMovementType.transferOut:
        return 'Transfer Out';
      case StockMovementType.adjustmentIncrease:
        return 'Adjustment Increase';
      case StockMovementType.adjustmentDecrease:
        return 'Adjustment Decrease';
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

  String _formatQuantity(
      StockMovement movement,
      ) {
    return '${movement.quantity} '
        '${movement.unitOfMeasure}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Movements'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
            _isLoading ? null : _loadMovements,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMovements,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading && _movements.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 300),
          Center(
            child: CircularProgressIndicator(),
          ),
        ],
      );
    }

    if (_error != null && _movements.isEmpty) {
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
                    onPressed: _loadMovements,
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

    if (_movements.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 220),
          Center(
            child: Text(
              'No stock movements found.',
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _movements.length,
      itemBuilder: (context, index) {
        final movement = _movements[index];

        return _StockMovementCard(
          movement: movement,
          movementType:
          _movementTypeLabel(
            movement.movementType,
          ),
          movementDate:
          _formatDate(
            movement.movementDateUtc,
          ),
          quantity:
          _formatQuantity(movement),
        );
      },
    );
  }
}

class _StockMovementCard extends StatelessWidget {
  const _StockMovementCard({
    required this.movement,
    required this.movementType,
    required this.movementDate,
    required this.quantity,
  });

  final StockMovement movement;
  final String movementType;
  final String movementDate;
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
                  Icons.swap_horiz_outlined,
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
                Chip(
                  label: Text(movementType),
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
              'Date: $movementDate',
            ),
            const SizedBox(height: 4),
            Text(
              'Quantity: $quantity',
            ),
            if (movement.unitCost != null) ...[
              const SizedBox(height: 4),
              Text(
                'Unit Cost: '
                    '${movement.unitCost}',
              ),
            ],
            if (movement.totalCost != null) ...[
              const SizedBox(height: 4),
              Text(
                'Total Cost: '
                    '${movement.totalCost}',
              ),
            ],
            if (movement.referenceNumber != null) ...[
              const SizedBox(height: 4),
              Text(
                'Reference: '
                    '${movement.referenceNumber}',
              ),
            ],
            if (movement.remarks != null &&
                movement.remarks!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                movement.remarks!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}