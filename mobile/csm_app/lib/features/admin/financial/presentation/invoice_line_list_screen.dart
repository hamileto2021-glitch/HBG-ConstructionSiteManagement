import 'package:flutter/material.dart';

import '../data/models/invoice_line.dart';
import '../data/repositories/invoice_line_repository.dart';
import 'invoice_line_create_screen.dart';

class InvoiceLineListScreen extends StatefulWidget {
  const InvoiceLineListScreen({
    super.key,
    required this.invoiceId,
    required this.repository,
  });

  final String invoiceId;
  final InvoiceLineRepository repository;

  @override
  State<InvoiceLineListScreen> createState() =>
      _InvoiceLineListScreenState();
}

class _InvoiceLineListScreenState
    extends State<InvoiceLineListScreen> {
  List<InvoiceLine> _lines = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLines();
  }

  Future<void> _loadLines() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final lines = await widget.repository.getByInvoice(
        widget.invoiceId,
      );

      if (!mounted) return;

      setState(() {
        _lines = lines;
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

  double get _grandTotal => _lines.fold(
        0,
        (sum, line) => sum + line.lineTotal,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Lines'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadLines,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created =
          await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => InvoiceLineCreateScreen(
                invoiceId: widget.invoiceId,
                repository: widget.repository,
              ),
            ),
          );

          if (created == true && mounted) {
            await _loadLines();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Line'),
      ),
      body: _buildBody(),
      bottomNavigationBar: _loading || _lines.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Invoice Total',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _grandTotal.toStringAsFixed(2),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
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
              FilledButton(
                onPressed: _loadLines,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_lines.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadLines,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'No invoice lines found.',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLines,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          100,
        ),
        itemCount: _lines.length,
        itemBuilder: (context, index) {
          return _InvoiceLineCard(
            line: _lines[index],
            onTap: () async {
              final updated =
              await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => InvoiceLineCreateScreen(
                    invoiceId: widget.invoiceId,
                    repository: widget.repository,
                    line: _lines[index],
                  ),
                ),
              );

              if (updated == true && mounted) {
                await _loadLines();
              }
            },
          );
        },
      ),
    );
  }
}

class _InvoiceLineCard extends StatelessWidget {
  const _InvoiceLineCard({
    required this.line,
    required this.onTap,
  });

  final InvoiceLine line;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: theme.colorScheme.primaryContainer,
                    ),
                    child: Icon(
                      Icons.receipt_long_outlined,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      line.description,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _InfoRow(
                label: 'Quantity',
                value: line.quantity.toStringAsFixed(2),
              ),
              _InfoRow(
                label: 'Unit Price',
                value: line.unitPrice.toStringAsFixed(2),
              ),
              _InfoRow(
                label: 'Line Total',
                value: line.lineTotal.toStringAsFixed(2),
              ),
            ],
          ),
        ),
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
      padding:
          const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium,
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