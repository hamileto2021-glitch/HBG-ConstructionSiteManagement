import 'package:flutter/material.dart';

import '../data/models/goods_receipt.dart';
import '../data/models/purchase_order.dart';
import '../data/repositories/goods_receipt_repository.dart';
import '../data/repositories/purchase_order_repository.dart';

class GoodsReceiptCreateScreen extends StatefulWidget {
  const GoodsReceiptCreateScreen({
    super.key,
    required this.repository,
    this.purchaseOrderId,
  });

  final GoodsReceiptRepository repository;
  final String? purchaseOrderId;

  @override
  State<GoodsReceiptCreateScreen> createState() =>
      _GoodsReceiptCreateScreenState();
}

class _GoodsReceiptCreateScreenState
    extends State<GoodsReceiptCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _loading = true;
  bool _saving = false;

  final _receiptNumberController = TextEditingController();
  final _deliveryNote = TextEditingController();
  final _vehiclePlate = TextEditingController();

  DateTime _receivedDate = DateTime.now();

  List<PurchaseOrder> _purchaseOrders = [];
  PurchaseOrder? _selectedOrder;

  final List<_ReceiptLineDraft> _lines = [];

  String? _optionalValue(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  @override
  void initState() {
    super.initState();
    _loadPurchaseOrders();
  }

  Future<void> _loadPurchaseOrders() async {
    try {
      final orders =
      await PurchaseOrderRepository().getAll();

      _purchaseOrders = orders.where((po) {
        return po.status == PurchaseOrderStatus.approved ||
            po.status == PurchaseOrderStatus.sentToVendor ||
            po.status ==
                PurchaseOrderStatus.partiallyDelivered;
      }).toList();

      if (widget.purchaseOrderId != null) {
        final match = _purchaseOrders.where((po) {
          return po.id == widget.purchaseOrderId;
        }).toList();

        if (match.isNotEmpty) {
          _selectOrder(match.first);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _selectOrder(PurchaseOrder order) {
    _selectedOrder = order;

    _lines
      ..clear()
      ..addAll(
        order.lines.map(
              (e) => _ReceiptLineDraft(
            lineId: e.id,
            materialId: e.materialId,
            materialCode: e.materialCode,
            materialName: e.materialName,
            unit: e.unitOfMeasure,
            remainingQty:
            e.orderedQuantity - e.receivedQuantity,
          ),
        ),
      );

    setState(() {});
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _receivedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() => _receivedDate = picked);
    }
  }

  Future<void> _save() async {
    if (_selectedOrder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a Purchase Order'),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    for (final line in _lines) {
      if (line.acceptedQty + line.rejectedQty !=
          line.receivedQty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${line.materialCode}: Accepted + Rejected must equal Received',
            ),
          ),
        );
        return;
      }
    }

    setState(() => _saving = true);

    try {
      await widget.repository.create(
        purchaseOrderId: _selectedOrder!.id,
        constructionSiteId: _selectedOrder!.constructionSiteId,
        receiptNumber: _receiptNumberController.text.trim(),
        receivedAtUtc: _receivedDate,
        deliveryNoteNumber: _optionalValue(_deliveryNote),
        vehiclePlateNumber: _optionalValue(_vehiclePlate),
        remarks: null,
        lines: _lines
            .where((e) => e.receivedQty > 0)
            .map(
              (e) => GoodsReceiptLineInput(
            purchaseOrderLineId: e.lineId,
            receivedQuantity: e.receivedQty,
            acceptedQuantity: e.acceptedQty,
            rejectedQuantity: e.rejectedQty,
            rejectionReason: null,
            remarks: null,
          ),
        )
            .toList(),
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Goods Receipt'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<PurchaseOrder>(
              initialValue: _selectedOrder,
              decoration: const InputDecoration(
                labelText: 'Purchase Order',
                border: OutlineInputBorder(),
              ),
              isExpanded: true,
              items: _purchaseOrders
                  .map(
                    (po) =>
                    DropdownMenuItem<PurchaseOrder>(
                      value: po,
                      child: Text(
                        '${po.purchaseOrderNumber} • ${po.vendorName}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
              )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  _selectOrder(value);
                }
              },
              validator: (value) =>
              value == null ? 'Required' : null,
            ),
            TextFormField(
              controller: _receiptNumberController,
              decoration: const InputDecoration(
                labelText: 'Receipt Number',
                hintText: 'RCT-00526',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Receipt Number is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            const SizedBox(height: 16),
            if (_selectedOrder != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedOrder!.vendorName,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_selectedOrder!.siteCode ?? ''} • ${_selectedOrder!.siteName}',
                      ),
                      if (_selectedOrder!.projectName !=
                          null)
                        Text(
                          '${_selectedOrder!.projectCode ?? ''} • ${_selectedOrder!.projectName}',
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _deliveryNote,
              decoration: const InputDecoration(
                labelText: 'Delivery Note',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _vehiclePlate,
              decoration: const InputDecoration(
                labelText: 'Vehicle Plate',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Received Date'),
              subtitle: Text(_formatDate(_receivedDate)),
              trailing:
              const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const Divider(),
            if (_lines.isNotEmpty) ...[
              Text(
                'Receipt Lines',
                style:
                Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ..._lines.map(
                    (line) => _ReceiptLineCard(
                  line: line,
                  onChanged: () => setState(() {}),
                ),
              ),
              const SizedBox(height: 20),
            ],
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.inventory),
              label: Text(
                _saving
                    ? 'Creating...'
                    : 'Create Goods Receipt',
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _deliveryNote.dispose();
    _vehiclePlate.dispose();
    _receiptNumberController.dispose();
    super.dispose();
  }
}

class _ReceiptLineDraft {
  _ReceiptLineDraft({
    required this.lineId,
    required this.materialId,
    required this.materialCode,
    required this.materialName,
    required this.unit,
    required this.remainingQty,
  });

  final String lineId;
  final String materialId;
  final String materialCode;
  final String materialName;
  final String unit;

  final double remainingQty;

  double receivedQty = 0;
  double acceptedQty = 0;
  double rejectedQty = 0;
}

class _ReceiptLineCard extends StatelessWidget {
  const _ReceiptLineCard({
    required this.line,
    required this.onChanged,
  });

  final _ReceiptLineDraft line;
  final VoidCallback onChanged;

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
            Text(
              '${line.materialCode} • ${line.materialName}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Remaining: ${line.remainingQty} ${line.unit}',
            ),
            const SizedBox(height: 12),
            _numberField(
              label: 'Received',
              value: line.receivedQty,
              onChanged: (v) {
                line.receivedQty = v;
                line.acceptedQty = v;
                onChanged();
              },
            ),
            const SizedBox(height: 12),
            _numberField(
              label: 'Accepted',
              value: line.acceptedQty,
              onChanged: (v) {
                line.acceptedQty = v;
                onChanged();
              },
            ),
            const SizedBox(height: 12),
            _numberField(
              label: 'Rejected',
              value: line.rejectedQty,
              onChanged: (v) {
                line.rejectedQty = v;
                onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _numberField({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    final controller = TextEditingController(
      text: value == 0 ? '' : value.toString(),
    );

    return TextFormField(
      controller: controller,
      keyboardType:
      const TextInputType.numberWithOptions(
        decimal: true,
      ),
      decoration: InputDecoration(
        labelText: label,
        suffixText: line.unit,
        border: const OutlineInputBorder(),
      ),
      onChanged: (v) =>
          onChanged(double.tryParse(v) ?? 0),
    );
  }
}