import 'package:flutter/material.dart';

import '../data/models/invoice.dart';
import '../data/repositories/invoice_repository.dart';
import '../data/repositories/invoice_line_repository.dart';
import 'invoice_line_list_screen.dart';

class InvoiceDetailScreen extends StatefulWidget {
  const InvoiceDetailScreen({
    super.key,
    required this.invoiceId,
    required this.repository,
  });

  final String invoiceId;
  final InvoiceRepository repository;

  @override
  State<InvoiceDetailScreen> createState() =>
      _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState
    extends State<InvoiceDetailScreen> {
  Invoice? _invoice;
  bool _loading = true;
  bool _updating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final invoice = await widget.repository.getById(
        widget.invoiceId,
      );

      if (!mounted) return;

      setState(() {
        _invoice = invoice;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _changeStatus(
      InvoiceStatus status,
      ) async {
    if (_invoice == null) return;

    setState(() => _updating = true);

    try {
      final updated =
      await widget.repository.changeStatus(
        invoiceId: _invoice!.id,
        status: status,
      );

      if (!mounted) return;

      setState(() => _invoice = updated);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status changed to ${status.displayName}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _updating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Invoice'),
        ),
        body: Center(child: Text(_error!)),
      );
    }

    final invoice = _invoice!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(invoice.invoiceNumber),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    invoice.invoiceNumber,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(
                      invoice.status.displayName,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle('Invoice Information'),
          _InfoRow(
            'Type',
            invoice.type.displayName,
          ),
          _InfoRow(
            'Invoice Date',
            _date(invoice.invoiceDate),
          ),
          _InfoRow(
            'Due Date',
            invoice.dueDate == null
                ? '—'
                : _date(invoice.dueDate!),
          ),
          _InfoRow(
            'Currency',
            invoice.currencyCode,
          ),
          _InfoRow(
            'Exchange Rate',
            invoice.exchangeRate.toString(),
          ),
          const SizedBox(height: 16),
          _SectionTitle('Financial Summary'),
          _InfoRow(
            'Subtotal',
            invoice.subtotal.toStringAsFixed(2),
          ),
          _InfoRow(
            'Tax',
            invoice.taxAmount.toStringAsFixed(2),
          ),
          _InfoRow(
            'Total',
            invoice.totalAmount.toStringAsFixed(2),
          ),
          const SizedBox(height: 20),

          FilledButton.icon(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => InvoiceLineListScreen(
                    invoiceId: invoice.id,
                    repository: InvoiceLineRepository(),
                  ),
                ),
              );

              if (mounted) {
                await _loadInvoice();
              }
            },
            icon: const Icon(Icons.receipt_long),
            label: const Text('View Invoice Lines'),
          ),


          const SizedBox(height: 16),
          _SectionTitle('Additional'),
          _InfoRow(
            'Description',
            invoice.description?.isEmpty ?? true
                ? '—'
                : invoice.description!,
          ),
          _InfoRow(
            'Reference',
            invoice.externalReference?.isEmpty ?? true
                ? '—'
                : invoice.externalReference!,
          ),
          const SizedBox(height: 24),
          if (_updating)
            const Center(
              child: CircularProgressIndicator(),
            )
          else
            ..._statusButtons(invoice),
        ],
      ),
    );
  }

  List<Widget> _statusButtons(Invoice invoice) {
    switch (invoice.status) {
      case InvoiceStatus.draft:
        return [
          FilledButton(
            onPressed: () => _changeStatus(
              InvoiceStatus.issued,
            ),
            child: const Text('Issue Invoice'),
          ),
        ];

      case InvoiceStatus.issued:
        return [
          FilledButton(
            onPressed: () => _changeStatus(
              InvoiceStatus.partiallyPaid,
            ),
            child: const Text('Mark Partially Paid'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () =>
                _changeStatus(InvoiceStatus.paid),
            child: const Text('Mark Paid'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _changeStatus(
              InvoiceStatus.cancelled,
            ),
            child: const Text('Cancel Invoice'),
          ),
        ];

      case InvoiceStatus.partiallyPaid:
        return [
          FilledButton(
            onPressed: () =>
                _changeStatus(InvoiceStatus.paid),
            child: const Text('Complete Payment'),
          ),
        ];

      case InvoiceStatus.paid:
      case InvoiceStatus.cancelled:
      case InvoiceStatus.overdue:
        return [
          const Center(
            child: Text(
              'No actions available.',
            ),
          ),
        ];
    }
  }

  String _date(DateTime value) {
    return value.toIso8601String().split('T').first;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      this.label,
      this.value,
      );

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium,
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}