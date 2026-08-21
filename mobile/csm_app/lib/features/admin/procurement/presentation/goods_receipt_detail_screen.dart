import 'package:flutter/material.dart';

import '../data/models/goods_receipt.dart';
import '../data/repositories/goods_receipt_repository.dart';

class GoodsReceiptDetailScreen extends StatefulWidget {
  const GoodsReceiptDetailScreen({
    super.key,
    required this.repository,
    required this.goodsReceiptId,
  });

  final GoodsReceiptRepository repository;
  final String goodsReceiptId;

  @override
  State<GoodsReceiptDetailScreen> createState() =>
      _GoodsReceiptDetailScreenState();
}

class _GoodsReceiptDetailScreenState
    extends State<GoodsReceiptDetailScreen> {
  GoodsReceipt? _receipt;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReceipt();
  }

  Future<void> _loadReceipt() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final receipt = await widget.repository.getById(
        widget.goodsReceiptId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _receipt = receipt;
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

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();

    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final receipt = _receipt;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          receipt?.receiptNumber ?? 'Goods Receipt',
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
            _isLoading ? null : _loadReceipt,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null && _receipt == null) {
      return Center(
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
                onPressed: _loadReceipt,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final receipt = _receipt;

    if (receipt == null) {
      return const Center(
        child: Text('Goods receipt not found.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReceipt,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(context, receipt),
          const SizedBox(height: 16),
          _buildInformationCard(context, receipt),
          const SizedBox(height: 16),
          _buildLinesCard(context, receipt),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context,
      GoodsReceipt receipt,
      ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 40,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    receipt.receiptNumber,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Goods Receipt',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationCard(
      BuildContext context,
      GoodsReceipt receipt,
      ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              'Receipt Information',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Purchase Order',
              value: receipt.purchaseOrderNumber,
            ),
            _InfoRow(
              label: 'Site',
              value: receipt.siteName,
            ),
            _InfoRow(
              label: 'Received At',
              value: _formatDateTime(
                receipt.receivedAtUtc,
              ),
            ),
            _InfoRow(
              label: 'Delivery Note',
              value:
              receipt.deliveryNoteNumber ?? '-',
            ),
            _InfoRow(
              label: 'Vehicle Plate',
              value:
              receipt.vehiclePlateNumber ?? '-',
            ),
            _InfoRow(
              label: 'Received By',
              value: receipt.receivedBy,
            ),
            if (receipt.remarks != null &&
                receipt.remarks!.trim().isNotEmpty)
              _InfoRow(
                label: 'Remarks',
                value: receipt.remarks!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinesCard(
      BuildContext context,
      GoodsReceipt receipt,
      ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              'Receipt Lines',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
            ),
            const SizedBox(height: 16),
            if (receipt.lines.isEmpty)
              const Text(
                'No receipt lines found.',
              )
            else
              ...receipt.lines.map(
                    (line) => _buildLine(
                  context,
                  line,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLine(
      BuildContext context,
      GoodsReceiptLine line,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            line.materialCode,
            style: Theme.of(context)
                .textTheme
                .titleMedium,
          ),
          const SizedBox(height: 4),
          Text(line.materialName),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _QuantityColumn(
                  label: 'Received',
                  value: _formatNumber(
                    line.receivedQuantity,
                  ),
                ),
              ),
              Expanded(
                child: _QuantityColumn(
                  label: 'Accepted',
                  value: _formatNumber(
                    line.acceptedQuantity,
                  ),
                ),
              ),
              Expanded(
                child: _QuantityColumn(
                  label: 'Rejected',
                  value: _formatNumber(
                    line.rejectedQuantity,
                  ),
                ),
              ),
            ],
          ),
          if (line.stockBalanceBefore != null ||
              line.stockBalanceAfter != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Stock Balance',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _QuantityColumn(
                    label: 'Before',
                    value: line.stockBalanceBefore == null
                        ? '-'
                        : _formatNumber(
                      line.stockBalanceBefore!,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward,
                  size: 20,
                ),
                Expanded(
                  child: _QuantityColumn(
                    label: 'After',
                    value: line.stockBalanceAfter == null
                        ? '-'
                        : _formatNumber(
                      line.stockBalanceAfter!,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (line.rejectionReason != null &&
              line.rejectionReason!
                  .trim()
                  .isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Rejection Reason',
              value: line.rejectionReason!,
            ),
          ],
          if (line.remarks != null &&
              line.remarks!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            _InfoRow(
              label: 'Line Remarks',
              value: line.remarks!,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge,
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

class _QuantityColumn extends StatelessWidget {
  const _QuantityColumn({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelMedium,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleMedium,
        ),
      ],
    );
  }
}