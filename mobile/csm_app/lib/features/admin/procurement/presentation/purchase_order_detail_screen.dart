import 'package:flutter/material.dart';

import '../data/models/purchase_order.dart';
import '../data/repositories/purchase_order_repository.dart';
import '../data/repositories/goods_receipt_repository.dart';
import 'goods_receipt_create_screen.dart';

class PurchaseOrderDetailScreen extends StatefulWidget {
  const PurchaseOrderDetailScreen({
    super.key,
    required this.repository,
    required this.purchaseOrderId,
  });

  final PurchaseOrderRepository repository;
  final String purchaseOrderId;

  @override
  State<PurchaseOrderDetailScreen> createState() =>
      _PurchaseOrderDetailScreenState();
}

class _PurchaseOrderDetailScreenState extends State<PurchaseOrderDetailScreen> {
  PurchaseOrder? _purchaseOrder;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPurchaseOrder();
  }

  Future<void> _loadPurchaseOrder() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final purchaseOrder = await widget.repository.getById(
        widget.purchaseOrderId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _purchaseOrder = purchaseOrder;
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

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '-';
    }

    final local = value.toLocal();

    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  bool _canSubmit(PurchaseOrder order) {
    return order.status == PurchaseOrderStatus.draft;
  }

  bool _canApprove(PurchaseOrder order) {
    return order.status == PurchaseOrderStatus.pendingApproval;
  }

  bool _canSendToVendor(PurchaseOrder order) {
    return order.status == PurchaseOrderStatus.approved;
  }

  bool _canCancel(PurchaseOrder order) {
    return order.status != PurchaseOrderStatus.cancelled &&
        order.status != PurchaseOrderStatus.delivered &&
        order.status != PurchaseOrderStatus.closed;
  }

  Future<void> _submit() async {
    final order = _purchaseOrder;

    if (order == null || !_canSubmit(order) || _isSaving) {
      return;
    }

    await _runAction(
      action: () => widget.repository.submit(order.id),
      successMessage: 'Purchase order submitted.',
    );
  }

  Future<void> _approve() async {
    final order = _purchaseOrder;

    if (order == null || !_canApprove(order) || _isSaving) {
      return;
    }

    await _runAction(
      action: () => widget.repository.approve(order.id),
      successMessage: 'Purchase order approved.',
    );
  }

  Future<void> _sendToVendor() async {
    final order = _purchaseOrder;

    if (order == null || !_canSendToVendor(order) || _isSaving) {
      return;
    }

    await _runAction(
      action: () => widget.repository.sendToVendor(order.id),
      successMessage: 'Purchase order sent to vendor.',
    );
  }

  Future<void> _receiveGoods() async {
    final order = _purchaseOrder;

    if (order == null ||
        (order.status != PurchaseOrderStatus.sentToVendor &&
            order.status != PurchaseOrderStatus.partiallyDelivered) ||
        _isSaving) {
      return;
    }

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => GoodsReceiptCreateScreen(
          repository: GoodsReceiptRepository(),
          purchaseOrder: order,
        ),
      ),
    );

    if (changed == true && mounted) {
      await _loadPurchaseOrder();
    }
  }

  Future<void> _cancel() async {
    final order = _purchaseOrder;

    if (order == null || !_canCancel(order) || _isSaving) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel Purchase Order'),
          content: const Text(
            'Are you sure you want to cancel this purchase order?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Cancel Order'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _runAction(
      action: () => widget.repository.cancel(order.id),
      successMessage: 'Purchase order cancelled.',
    );
  }

  Future<void> _runAction({
    required Future<PurchaseOrder> Function() action,
    required String successMessage,
  }) async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedOrder = await action();

      if (!mounted) {
        return;
      }

      setState(() {
        _purchaseOrder = updatedOrder;
        _isSaving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _error = error.toString();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _purchaseOrder;

    return Scaffold(
      appBar: AppBar(
        title: Text(order?.purchaseOrderNumber ?? 'Purchase Order'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading || _isSaving ? null : _loadPurchaseOrder,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _purchaseOrder == null) {
      return Center(
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
                onPressed: _loadPurchaseOrder,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final order = _purchaseOrder;

    if (order == null) {
      return const Center(child: Text('Purchase order not found.'));
    }

    return RefreshIndicator(
      onRefresh: _loadPurchaseOrder,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(context, order),
          const SizedBox(height: 16),
          _buildActionButtons(order),
          const SizedBox(height: 16),
          _buildInformationCard(context, order),
          const SizedBox(height: 16),
          _buildFinancialCard(context, order),
          const SizedBox(height: 16),
          _buildLinesCard(context, order),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, PurchaseOrder order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              order.purchaseOrderNumber,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Chip(label: Text(_statusLabel(order.status))),
            const SizedBox(height: 12),
            Text(
              order.vendorName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (order.vendorCode.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Vendor Code: ${order.vendorCode}'),
            ],
            const SizedBox(height: 8),
            Text('Site: ${order.siteName}'),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(PurchaseOrder order) {
    final buttons = <Widget>[];

    if (_canSubmit(order)) {
      buttons.add(
        FilledButton.icon(
          onPressed: _isSaving ? null : _submit,
          icon: const Icon(Icons.send),
          label: const Text('Submit'),
        ),
      );
    }

    if (_canApprove(order)) {
      buttons.add(
        FilledButton.icon(
          onPressed: _isSaving ? null : _approve,
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Approve'),
        ),
      );
    }

    if (_canSendToVendor(order)) {
      buttons.add(
        FilledButton.icon(
          onPressed: _isSaving ? null : _sendToVendor,
          icon: const Icon(Icons.local_shipping_outlined),
          label: const Text('Send to Vendor'),
        ),
      );
    }

    if (order.status == PurchaseOrderStatus.sentToVendor ||
        order.status == PurchaseOrderStatus.partiallyDelivered) {
      buttons.add(
        FilledButton.icon(
          onPressed: _isSaving ? null : _receiveGoods,
          icon: const Icon(Icons.inventory_2_outlined),
          label: const Text('Receive Goods'),
        ),
      );
    }

    if (_canCancel(order)) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: _isSaving ? null : _cancel,
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Cancel'),
        ),
      );
    }

    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(spacing: 12, runSpacing: 12, children: buttons),
      ),
    );
  }

  Widget _buildInformationCard(BuildContext context, PurchaseOrder order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _infoRow('Order Date', _formatDate(order.orderDate)),
            _infoRow(
              'Expected Delivery',
              _formatDate(order.expectedDeliveryDate),
            ),
            _infoRow('Currency', order.currencyCode),
            _infoRow('Exchange Rate', order.exchangeRate.toStringAsFixed(4)),
            if (order.projectName != null)
              _infoRow('Project', order.projectName!),
            if (order.materialRequestNumber != null)
              _infoRow('Material Request', order.materialRequestNumber!),
            if (order.deliveryAddress != null &&
                order.deliveryAddress!.trim().isNotEmpty)
              _infoRow('Delivery Address', order.deliveryAddress!),
            if (order.paymentTerms != null &&
                order.paymentTerms!.trim().isNotEmpty)
              _infoRow('Payment Terms', order.paymentTerms!),
            if (order.notes != null && order.notes!.trim().isNotEmpty)
              _infoRow('Notes', order.notes!),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialCard(BuildContext context, PurchaseOrder order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _amountRow('Subtotal', order.subtotal, order.currencyCode),
            _amountRow('Tax', order.taxAmount, order.currencyCode),
            _amountRow('Discount', order.discountAmount, order.currencyCode),
            const Divider(height: 24),
            _amountRow(
              'Total',
              order.totalAmount,
              order.currencyCode,
              emphasize: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinesCard(BuildContext context, PurchaseOrder order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Lines', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (order.lines.isEmpty)
              const Text('No order lines found.')
            else
              ...order.lines.asMap().entries.map(
                (entry) => _buildLine(
                  context,
                  entry.key + 1,
                  entry.value,
                  order.currencyCode,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLine(
    BuildContext context,
    int index,
    PurchaseOrderLine line,
    String currencyCode,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$index. ${line.materialName}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (line.materialCode.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Material Code: ${line.materialCode}'),
          ],
          const SizedBox(height: 8),
          _infoRow(
            'Ordered Quantity',
            '${line.orderedQuantity} ${line.unitOfMeasure}',
          ),
          _infoRow(
            'Received Quantity',
            '${line.receivedQuantity} ${line.unitOfMeasure}',
          ),
          _infoRow(
            'Unit Price',
            '$currencyCode ${line.unitPrice.toStringAsFixed(2)}',
          ),
          _infoRow('Tax', '$currencyCode ${line.taxAmount.toStringAsFixed(2)}'),
          _infoRow(
            'Line Total',
            '$currencyCode ${line.lineTotal.toStringAsFixed(2)}',
          ),
          if (line.costCode != null && line.costCode!.trim().isNotEmpty)
            _infoRow('Cost Code', line.costCode!),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _amountRow(
    String label,
    double amount,
    String currencyCode, {
    bool emphasize = false,
  }) {
    final text = '$currencyCode ${amount.toStringAsFixed(2)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: emphasize
                  ? const TextStyle(fontWeight: FontWeight.bold)
                  : null,
            ),
          ),
          Text(
            text,
            style: emphasize
                ? const TextStyle(fontWeight: FontWeight.bold)
                : null,
          ),
        ],
      ),
    );
  }
}
