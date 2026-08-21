import 'package:flutter/material.dart';

import '../data/models/goods_receipt.dart';
import '../data/repositories/goods_receipt_repository.dart';
import 'goods_receipt_detail_screen.dart';

class GoodsReceiptListScreen extends StatefulWidget {
  const GoodsReceiptListScreen({super.key, required this.repository});

  final GoodsReceiptRepository repository;

  @override
  State<GoodsReceiptListScreen> createState() => _GoodsReceiptListScreenState();
}

class _GoodsReceiptListScreenState extends State<GoodsReceiptListScreen> {
  final List<GoodsReceipt> _receipts = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final receipts = await widget.repository.getAll();

      if (!mounted) {
        return;
      }

      setState(() {
        _receipts
          ..clear()
          ..addAll(receipts);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goods Receipts'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadReceipts,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadReceipts,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading && _receipts.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 300),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null && _receipts.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 220),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _loadReceipts,
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

    if (_receipts.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 220),
          Center(child: Text('No goods receipts found.')),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _receipts.length,
      itemBuilder: (context, index) {
        final receipt = _receipts[index];

        return _GoodsReceiptCard(
          receipt: receipt,
          receivedAt: _formatDate(receipt.receivedAtUtc),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GoodsReceiptDetailScreen(
                  repository: widget.repository,
                  goodsReceiptId: receipt.id,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _GoodsReceiptCard extends StatelessWidget {
  const _GoodsReceiptCard({
    required this.receipt,
    required this.receivedAt,
    required this.onTap,
  });

  final GoodsReceipt receipt;
  final String receivedAt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      receipt.receiptNumber,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Purchase Order: '
                    '${receipt.purchaseOrderNumber}',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Site: ${receipt.siteName}',
              ),
              const SizedBox(height: 4),
              Text(
                'Received: $receivedAt',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${receipt.lines.length} '
                          'line${receipt.lines.length == 1 ? '' : 's'}',
                    ),
                  ),
                  if (receipt.deliveryNoteNumber != null)
                    Text(
                      'DN: ${receipt.deliveryNoteNumber}',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
