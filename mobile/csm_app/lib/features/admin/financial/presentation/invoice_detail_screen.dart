import 'package:flutter/material.dart';

import '../../procurement/data/models/vendor.dart';
import '../../procurement/data/repositories/vendor_repository.dart';
import '../../projects/data/models/project.dart';
import '../../projects/data/repositories/project_repository.dart';
import '../../sites/data/models/site.dart';
import '../../sites/data/repositories/site_repository.dart';
import '../data/models/invoice.dart';
import '../data/repositories/invoice_repository.dart';
import '../data/repositories/invoice_line_repository.dart';
import 'invoice_line_list_screen.dart';

class InvoiceDetailScreen extends StatefulWidget {
  const InvoiceDetailScreen({
    super.key,
    required this.invoiceId,
    required this.repository,
    this.siteRepository,
    this.projectRepository,
    this.vendorRepository,
  });

  final String invoiceId;
  final InvoiceRepository repository;

  final SiteRepository? siteRepository;
  final ProjectRepository? projectRepository;
  final VendorRepository? vendorRepository;

  @override
  State<InvoiceDetailScreen> createState() =>
      _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState
    extends State<InvoiceDetailScreen> {
  Invoice? _invoice;

  Site? _site;
  Project? _project;
  Vendor? _vendor;

  bool _loading = true;
  bool _updating = false;
  String? _error;

  late final SiteRepository _siteRepository;
  late final ProjectRepository _projectRepository;
  late final VendorRepository _vendorRepository;

  @override
  void initState() {
    super.initState();

    _siteRepository =
        widget.siteRepository ?? SiteRepository();

    _projectRepository =
        widget.projectRepository ?? ProjectRepository();

    _vendorRepository =
        widget.vendorRepository ?? VendorRepository();

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

      Site? site;
      Project? project;
      Vendor? vendor;

      try {
        site = await _siteRepository.getById(
          invoice.constructionSiteId,
        );
      } catch (_) {
        site = null;
      }

      if (invoice.projectId != null &&
          invoice.projectId!.isNotEmpty) {
        try {
          project = await _projectRepository.getById(
            invoice.projectId!,
          );
        } catch (_) {
          project = null;
        }
      }

      if (invoice.vendorId != null &&
          invoice.vendorId!.isNotEmpty) {
        try {
          vendor = await _vendorRepository.getById(
            invoice.vendorId!,
          );
        } catch (_) {
          vendor = null;
        }
      }

      if (!mounted) return;

      setState(() {
        _invoice = invoice;
        _site = site;
        _project = project;
        _vendor = vendor;
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
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _updating = false);
      }
    }
  }

  String _siteDisplayName() {
    if (_site == null) {
      return '—';
    }

    return '${_site!.siteCode} - ${_site!.name}';
  }

  String _projectDisplayName() {
    if (_invoice?.projectId == null) {
      return '—';
    }

    if (_project == null) {
      return '—';
    }

    return '${_project!.projectCode} - ${_project!.name}';
  }

  String _vendorDisplayName() {
    if (_invoice?.vendorId == null) {
      return 'No Vendor';
    }

    if (_vendor == null) {
      return '—';
    }

    return '${_vendor!.vendorCode} - ${_vendor!.name}';
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
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final invoice = _invoice!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(invoice.invoiceNumber),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading
                ? null
                : _loadInvoice,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadInvoice,
        child: ListView(
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
                      color:
                      theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      invoice.invoiceNumber,
                      style: theme
                          .textTheme
                          .headlineSmall,
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

            _SectionTitle(
              'Invoice Information',
            ),

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

            _SectionTitle(
              'Project & Vendor',
            ),

            _InfoRow(
              'Construction Site',
              _siteDisplayName(),
            ),

            _InfoRow(
              'Project',
              _projectDisplayName(),
            ),

            _InfoRow(
              'Vendor',
              _vendorDisplayName(),
            ),

            const SizedBox(height: 16),

            _SectionTitle(
              'Financial Summary',
            ),

            _InfoRow(
              'Subtotal',
              invoice.subtotal
                  .toStringAsFixed(2),
            ),

            _InfoRow(
              'Tax',
              invoice.taxAmount
                  .toStringAsFixed(2),
            ),

            _InfoRow(
              'Total',
              invoice.totalAmount
                  .toStringAsFixed(2),
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: () async {
                await Navigator.of(context)
                    .push(
                  MaterialPageRoute(
                    builder: (_) =>
                        InvoiceLineListScreen(
                          invoiceId: invoice.id,
                          repository:
                          InvoiceLineRepository(),
                        ),
                  ),
                );

                if (mounted) {
                  await _loadInvoice();
                }
              },
              icon: const Icon(
                Icons.receipt_long,
              ),
              label: const Text(
                'View Invoice Lines',
              ),
            ),

            const SizedBox(height: 16),

            _SectionTitle(
              'Additional',
            ),

            _InfoRow(
              'Description',
              invoice.description?.isEmpty ??
                  true
                  ? '—'
                  : invoice.description!,
            ),

            _InfoRow(
              'Reference',
              invoice.externalReference
                  ?.isEmpty ??
                  true
                  ? '—'
                  : invoice.externalReference!,
            ),

            const SizedBox(height: 24),

            if (_updating)
              const Center(
                child:
                CircularProgressIndicator(),
              )
            else
              ..._statusButtons(invoice),
          ],
        ),
      ),
    );
  }

  List<Widget> _statusButtons(
      Invoice invoice,
      ) {
    switch (invoice.status) {
      case InvoiceStatus.draft:
        return [
          FilledButton(
            onPressed: () =>
                _changeStatus(
                  InvoiceStatus.issued,
                ),
            child: const Text(
              'Issue Invoice',
            ),
          ),
        ];

      case InvoiceStatus.issued:
        return [
          FilledButton(
            onPressed: () =>
                _changeStatus(
                  InvoiceStatus.partiallyPaid,
                ),
            child: const Text(
              'Mark Partially Paid',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () =>
                _changeStatus(
                  InvoiceStatus.paid,
                ),
            child: const Text(
              'Mark Paid',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () =>
                _changeStatus(
                  InvoiceStatus.cancelled,
                ),
            child: const Text(
              'Cancel Invoice',
            ),
          ),
        ];

      case InvoiceStatus.partiallyPaid:
        return [
          FilledButton(
            onPressed: () =>
                _changeStatus(
                  InvoiceStatus.paid,
                ),
            child: const Text(
              'Complete Payment',
            ),
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
    return value
        .toIso8601String()
        .split('T')
        .first;
  }
}

class _SectionTitle
    extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(
          fontWeight:
          FontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoRow
    extends StatelessWidget {
  const _InfoRow(
      this.label,
      this.value,
      );

  final String label;
  final String value;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
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
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}