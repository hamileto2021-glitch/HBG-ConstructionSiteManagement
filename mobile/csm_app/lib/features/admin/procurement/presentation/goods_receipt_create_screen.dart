import 'package:flutter/material.dart';

import '../data/models/goods_receipt.dart';
import '../data/models/purchase_order.dart';
import '../data/repositories/goods_receipt_repository.dart';

class GoodsReceiptCreateScreen extends StatefulWidget {
  const GoodsReceiptCreateScreen({
    super.key,
    required this.repository,
    required this.purchaseOrder,
  });

  final GoodsReceiptRepository repository;
  final PurchaseOrder purchaseOrder;

  @override
  State<GoodsReceiptCreateScreen> createState() =>
      _GoodsReceiptCreateScreenState();
}

class _GoodsReceiptCreateScreenState extends State<GoodsReceiptCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _receiptNumberController = TextEditingController();
  final _deliveryNoteController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  final _remarksController = TextEditingController();

  late DateTime _receivedAt;

  final List<_GoodsReceiptLineDraft> _lines = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _receivedAt = DateTime.now();

    for (final line in widget.purchaseOrder.lines) {
      final remainingQuantity = line.orderedQuantity - line.receivedQuantity;

      if (remainingQuantity > 0) {
        _lines.add(
          _GoodsReceiptLineDraft(
            purchaseOrderLineId: line.id,
            materialName: line.materialName,
            materialCode: line.materialCode,
            unitOfMeasure: line.unitOfMeasure,
            remainingQuantity: remainingQuantity,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _receiptNumberController.dispose();
    _deliveryNoteController.dispose();
    _vehiclePlateController.dispose();
    _remarksController.dispose();

    for (final line in _lines) {
      line.dispose();
    }

    super.dispose();
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();

    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectReceivedDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _receivedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_receivedAt),
    );

    if (time == null || !mounted) {
      return;
    }

    setState(() {
      _receivedAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _createReceipt() async {
    if (_isSaving) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final inputs = <GoodsReceiptLineInput>[];

    for (final line in _lines) {
      final receivedQuantity = double.tryParse(
        line.receivedQuantityController.text.trim(),
      );

      final acceptedQuantity = double.tryParse(
        line.acceptedQuantityController.text.trim(),
      );

      final rejectedQuantity = double.tryParse(
        line.rejectedQuantityController.text.trim(),
      );

      if (receivedQuantity == null ||
          acceptedQuantity == null ||
          rejectedQuantity == null ||
          receivedQuantity < 0 ||
          acceptedQuantity < 0 ||
          rejectedQuantity < 0) {
        _showMessage('Enter valid quantities for every receipt line.');
        return;
      }

      if (receivedQuantity > line.remainingQuantity) {
        _showMessage(
          '${line.materialName}: received quantity cannot '
          'exceed the remaining quantity.',
        );
        return;
      }

      if ((acceptedQuantity + rejectedQuantity - receivedQuantity).abs() >
          0.0001) {
        _showMessage(
          '${line.materialName}: accepted plus rejected '
          'quantity must equal received quantity.',
        );
        return;
      }

      if (rejectedQuantity > 0 &&
          line.rejectionReasonController.text.trim().isEmpty) {
        _showMessage('Enter a rejection reason for ${line.materialName}.');
        return;
      }

      if (receivedQuantity <= 0) {
        continue;
      }

      inputs.add(
        GoodsReceiptLineInput(
          purchaseOrderLineId: line.purchaseOrderLineId,
          receivedQuantity: receivedQuantity,
          acceptedQuantity: acceptedQuantity,
          rejectedQuantity: rejectedQuantity,
          rejectionReason: _optionalValue(line.rejectionReasonController),
          remarks: _optionalValue(line.remarksController),
        ),
      );
    }

    if (inputs.isEmpty) {
      _showMessage('Enter a received quantity for at least one line.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.repository.create(
        purchaseOrderId: widget.purchaseOrder.id,
        constructionSiteId: widget.purchaseOrder.constructionSiteId,
        receiptNumber: _receiptNumberController.text.trim(),
        receivedAtUtc: _receivedAt,
        deliveryNoteNumber: _optionalValue(_deliveryNoteController),
        vehiclePlateNumber: _optionalValue(_vehiclePlateController),
        remarks: _optionalValue(_remarksController),
        lines: inputs,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Goods receipt created.')));

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      _showMessage(error.toString());
    }
  }

  String? _optionalValue(TextEditingController controller) {
    final value = controller.text.trim();

    return value.isEmpty ? null : value;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receive Goods')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildPurchaseOrderCard(context),
            const SizedBox(height: 16),
            _buildHeaderCard(context),
            const SizedBox(height: 16),
            _buildLinesCard(context),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _createReceipt,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.inventory_2_outlined),
                label: Text(
                  _isSaving ? 'Creating Receipt...' : 'Create Goods Receipt',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseOrderCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Purchase Order',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              widget.purchaseOrder.purchaseOrderNumber,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text('Vendor: ${widget.purchaseOrder.vendorName}'),
            const SizedBox(height: 4),
            Text('Site: ${widget.purchaseOrder.siteName}'),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Receipt Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _receiptNumberController,
              decoration: const InputDecoration(
                labelText: 'Receipt Number',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Receipt number is required.';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectReceivedDateTime,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Received At',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_formatDateTime(_receivedAt))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _deliveryNoteController,
              decoration: const InputDecoration(
                labelText: 'Delivery Note Number',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _vehiclePlateController,
              decoration: const InputDecoration(
                labelText: 'Vehicle Plate Number',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _remarksController,
              decoration: const InputDecoration(
                labelText: 'Remarks',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinesCard(BuildContext context) {
    if (_lines.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'All purchase order quantities have already '
            'been received.',
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Receipt Lines',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Accepted quantity plus rejected quantity '
              'must equal received quantity.',
            ),
            const SizedBox(height: 16),
            ..._lines.asMap().entries.map(
              (entry) => _GoodsReceiptLineCard(
                index: entry.key + 1,
                line: entry.value,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoodsReceiptLineDraft {
  _GoodsReceiptLineDraft({
    required this.purchaseOrderLineId,
    required this.materialName,
    required this.materialCode,
    required this.unitOfMeasure,
    required this.remainingQuantity,
  });

  final String purchaseOrderLineId;
  final String materialName;
  final String materialCode;
  final String unitOfMeasure;
  final double remainingQuantity;

  final receivedQuantityController = TextEditingController();

  final acceptedQuantityController = TextEditingController();

  final rejectedQuantityController = TextEditingController();

  final rejectionReasonController = TextEditingController();

  final remarksController = TextEditingController();

  void dispose() {
    receivedQuantityController.dispose();
    acceptedQuantityController.dispose();
    rejectedQuantityController.dispose();
    rejectionReasonController.dispose();
    remarksController.dispose();
  }
}

class _GoodsReceiptLineCard extends StatelessWidget {
  const _GoodsReceiptLineCard({required this.index, required this.line});

  final int index;
  final _GoodsReceiptLineDraft line;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$index. ${line.materialName}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (line.materialCode.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Code: ${line.materialCode}'),
            ],
            const SizedBox(height: 4),
            Text(
              'Remaining: '
              '${line.remainingQuantity} '
              '${line.unitOfMeasure}',
            ),
            const SizedBox(height: 12),
            _numberField(
              controller: line.receivedQuantityController,
              label: 'Received Quantity (${line.unitOfMeasure})',
            ),
            const SizedBox(height: 12),
            _numberField(
              controller: line.acceptedQuantityController,
              label: 'Accepted Quantity (${line.unitOfMeasure})',
            ),
            const SizedBox(height: 12),
            _numberField(
              controller: line.rejectedQuantityController,
              label: 'Rejected Quantity (${line.unitOfMeasure})',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: line.rejectionReasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: line.remarksController,
              decoration: const InputDecoration(
                labelText: 'Line Remarks',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  static Widget _numberField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
