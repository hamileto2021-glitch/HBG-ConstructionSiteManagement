import 'package:flutter/material.dart';

import '../data/models/goods_receipt.dart';
import '../data/repositories/goods_receipt_repository.dart';
import 'goods_receipt_detail_screen.dart';
import 'goods_receipt_create_screen.dart';
import '../../../../responsive/breakpoints.dart';
import '../../../../shared/widgets/adaptive_data_table.dart';




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

      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Create'),
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => GoodsReceiptCreateScreen(
                repository: widget.repository,
              ),
            ),
          );

          if (created == true) {
            _loadReceipts();
          }
        },
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

    if (AppBreakpoints.isDesktop(context)) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.7,
              children: [
                _GoodsReceiptKpiCard(
                  title: 'Receipts',
                  value: '${_receipts.length}',
                  icon: Icons.inventory_2,
                  color: Colors.blue,
                ),
                _GoodsReceiptKpiCard(
                  title: 'Today',
                  value: '$_todayCount',
                  icon: Icons.today,
                  color: Colors.green,
                ),
                _GoodsReceiptKpiCard(
                  title: 'Pending DN',
                  value: '$_pendingInspectionCount',
                  icon: Icons.assignment_late,
                  color: Colors.orange,
                ),
                _GoodsReceiptKpiCard(
                  title: 'Total Lines',
                  value: '$_totalLines',
                  icon: Icons.list_alt,
                  color: Colors.deepPurple,
                ),
              ],
            ),

            const SizedBox(height: 16),

            AdaptiveDataTable(
              columns: [
                AdaptiveColumn(
                  label: 'Receipt',
                  value: (r) => r['receipt'] as String,
                ),
                AdaptiveColumn(
                  label: 'PO',
                  value: (r) => r['po'] as String,
                ),
                AdaptiveColumn(
                  label: 'Site',
                  value: (r) => r['site'] as String,
                ),
                AdaptiveColumn(
                  label: 'Received',
                  value: (r) => r['received'] as String,
                ),
                AdaptiveColumn(
                  label: 'Lines',
                  value: (r) => r['lines'] as String,
                  numeric: true,
                ),
              ],
              rows: _receipts.map((gr) {
                return {
                  'item': gr,
                  'receipt': gr.receiptNumber,
                  'po': gr.purchaseOrderNumber,
                  'site': gr.siteName,
                  'received': _formatDate(gr.receivedAtUtc),
                  'lines': gr.lines.length.toString(),
                };
              }).toList(),
              onRowTap: (row) async {
                final receipt = row['item'] as GoodsReceipt;

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GoodsReceiptDetailScreen(
                      repository: widget.repository,
                      goodsReceiptId: receipt.id,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
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
            await Navigator.push(
              context,
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

  int get _todayCount {
    final today = DateTime.now();

    return _receipts.where((r) {
      final d = r.receivedAtUtc.toLocal();

      return d.year == today.year &&
          d.month == today.month &&
          d.day == today.day;
    }).length;
  }

  int get _pendingInspectionCount => _receipts
      .where((r) => r.deliveryNoteNumber == null)
      .length;

  int get _totalLines => _receipts.fold(
    0,
        (sum, r) => sum + r.lines.length,
  );
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

class _GoodsReceiptKpiCard extends StatelessWidget {
  const _GoodsReceiptKpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }
}
