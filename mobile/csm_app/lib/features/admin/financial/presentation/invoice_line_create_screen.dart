import 'package:flutter/material.dart';

import '../data/models/invoice_line.dart';
import '../data/repositories/invoice_line_repository.dart';

class InvoiceLineCreateScreen extends StatefulWidget {
  const InvoiceLineCreateScreen({
    super.key,
    required this.invoiceId,
    required this.repository,
    this.line,
  });

  final String invoiceId;
  final InvoiceLineRepository repository;
  final InvoiceLine? line;

  bool get isEdit => line != null;

  @override
  State<InvoiceLineCreateScreen> createState() =>
      _InvoiceLineCreateScreenState();
}

class _InvoiceLineCreateScreenState
    extends State<InvoiceLineCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _descriptionController = TextEditingController();
  final _quantityController =
  TextEditingController(text: '1');
  final _unitPriceController =
  TextEditingController(text: '0');

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    if (widget.isEdit) {
      final line = widget.line!;
      _descriptionController.text = line.description;
      _quantityController.text =
          line.quantity.toStringAsFixed(2);
      _unitPriceController.text =
          line.unitPrice.toStringAsFixed(2);
    }
  }

  double get _quantity =>
      double.tryParse(_quantityController.text) ?? 0;

  double get _unitPrice =>
      double.tryParse(_unitPriceController.text) ?? 0;

  double get _lineTotal => _quantity * _unitPrice;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);

    try {
      if (widget.isEdit) {
        await widget.repository.update(
          invoiceLineId: widget.line!.id,
          description: _descriptionController.text.trim(),
          quantity: _quantity,
          unitPrice: _unitPrice,
        );
      } else {
        await widget.repository.create(
          invoiceId: widget.invoiceId,
          description: _descriptionController.text.trim(),
          quantity: _quantity,
          unitPrice: _unitPrice,
        );
      }

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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEdit
              ? 'Edit Invoice Line'
              : 'Create Invoice Line',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
              value == null || value.trim().isEmpty
                  ? 'Required'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              keyboardType:
              const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
              validator: (value) =>
              value == null || value.isEmpty
                  ? 'Required'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _unitPriceController,
              keyboardType:
              const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Unit Price',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
              validator: (value) =>
              value == null || value.isEmpty
                  ? 'Required'
                  : null,
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Line Total',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _lineTotal.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(
                widget.isEdit
                    ? 'Update Line'
                    : 'Create Line',
              ),
            ),
          ],
        ),
      ),
    );
  }
}