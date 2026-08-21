import 'package:flutter/material.dart';

import '../data/models/purchase_order.dart';
import '../data/repositories/purchase_order_repository.dart';
import 'purchase_order_create_screen.dart';
import 'purchase_order_detail_screen.dart';

class PurchaseOrderListScreen extends StatefulWidget {
  const PurchaseOrderListScreen({
    super.key,
    required this.repository,
  });

  final PurchaseOrderRepository repository;

  @override
  State<PurchaseOrderListScreen> createState() =>
      _PurchaseOrderListScreenState();
}

class _PurchaseOrderListScreenState
    extends State<PurchaseOrderListScreen> {
  final List<PurchaseOrder> _purchaseOrders = [];

  bool _isLoading = true;
  PurchaseOrderStatus? _statusFilter;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPurchaseOrders();
  }

  Future<void> _loadPurchaseOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final purchaseOrders =
          await widget.repository.getAll(
        status: _statusFilter,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _purchaseOrders
          ..clear()
          ..addAll(purchaseOrders);
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

  String _statusLabel(PurchaseOrderStatus status) {
    switch (status) {
      case PurchaseOrderStatus.draft:
        return 'Draft';
      case PurchaseOrderStatus.pendingApproval:
        return 'Pending Approval';
      case PurchaseOrderStatus.approved:
        return 'Approved';
      case PurchaseOrderStatus.sentToVendor:
        return 'Sent to Vendor';
      case PurchaseOrderStatus.partiallyDelivered:
        return 'Partially Delivered';
      case PurchaseOrderStatus.delivered:
        return 'Delivered';
      case PurchaseOrderStatus.closed:
        return 'Closed';
      case PurchaseOrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();

    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Orders'),
        actions: [
          PopupMenuButton<PurchaseOrderStatus?>(
            tooltip: 'Filter by status',
            initialValue: _statusFilter,
            onSelected: (value) {
              setState(() {
                _statusFilter = value;
              });
              _loadPurchaseOrders();
            },
            itemBuilder: (_) => [
              const PopupMenuItem<PurchaseOrderStatus?>(
                value: null,
                child: Text('All'),
              ),
              ...PurchaseOrderStatus.values.map(
                (status) =>
                    PopupMenuItem<PurchaseOrderStatus?>(
                  value: status,
                  child: Text(_statusLabel(status)),
                ),
              ),
            ],
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            tooltip: 'Create Purchase Order',
            onPressed: _isLoading
                ? null
                : () async {
                    final created =
                        await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) =>
                            PurchaseOrderCreateScreen(
                          repository: widget.repository,
                        ),
                      ),
                    );

                    if (created == true && mounted) {
                      await _loadPurchaseOrders();
                    }
                  },
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                _isLoading ? null : _loadPurchaseOrders,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPurchaseOrders,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading && _purchaseOrders.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 300),
          Center(
            child: CircularProgressIndicator(),
          ),
        ],
      );
    }

    if (_error != null && _purchaseOrders.isEmpty) {
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
                    onPressed: _loadPurchaseOrders,
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

    if (_purchaseOrders.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 220),
          Center(
            child: Text('No purchase orders found.'),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _purchaseOrders.length,
      itemBuilder: (context, index) {
        final purchaseOrder = _purchaseOrders[index];

        return _PurchaseOrderCard(
          purchaseOrder: purchaseOrder,
          statusLabel:
              _statusLabel(purchaseOrder.status),
          orderDate:
              _formatDate(purchaseOrder.orderDate),
          onTap: () async {
            final changed =
                await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) =>
                    PurchaseOrderDetailScreen(
                  repository: widget.repository,
                  purchaseOrderId:
                      purchaseOrder.id,
                ),
              ),
            );

            if (changed == true && mounted) {
              await _loadPurchaseOrders();
            }
          },
        );
      },
    );
  }
}

class _PurchaseOrderCard extends StatelessWidget {
  const _PurchaseOrderCard({
    required this.purchaseOrder,
    required this.statusLabel,
    required this.orderDate,
    required this.onTap,
  });

  final PurchaseOrder purchaseOrder;
  final String statusLabel;
  final String orderDate;
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
                  Icons.receipt_long_outlined,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    purchaseOrder.purchaseOrderNumber,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge,
                  ),
                ),
                Chip(
                  label: Text(statusLabel),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              purchaseOrder.vendorName,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Site: ${purchaseOrder.siteName}',
            ),
            const SizedBox(height: 4),
            Text(
              'Order Date: $orderDate',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${purchaseOrder.lines.length} '
                    'line${purchaseOrder.lines.length == 1 ? '' : 's'}',
                  ),
                ),
                Text(
                  '${purchaseOrder.currencyCode} '
                  '${purchaseOrder.totalAmount.toStringAsFixed(2)}',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium,
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






