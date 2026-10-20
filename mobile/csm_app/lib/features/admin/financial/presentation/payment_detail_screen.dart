import 'package:flutter/material.dart';

import '../data/models/payment.dart';
import '../data/repositories/payment_repository.dart';
import '../data/models/invoice.dart';
import '../data/repositories/invoice_repository.dart';

import '../../procurement/data/models/vendor.dart';
import '../../procurement/data/repositories/vendor_repository.dart';

import '../../projects/data/models/project.dart';
import '../../projects/data/repositories/project_repository.dart';

import '../../sites/data/models/site.dart';
import '../../sites/data/repositories/site_repository.dart';

class PaymentDetailScreen extends StatefulWidget {
  const PaymentDetailScreen({
    super.key,
    required this.paymentId,
    required this.repository,
    this.invoiceRepository,
    this.vendorRepository,
  });

  final String paymentId;
  final PaymentRepository repository;
  final InvoiceRepository? invoiceRepository;
  final VendorRepository? vendorRepository;

  @override
  State<PaymentDetailScreen> createState() =>
      _PaymentDetailScreenState();
}

class _PaymentDetailScreenState
    extends State<PaymentDetailScreen> {
  Payment? _payment;

  Invoice? _invoice;
  Vendor? _vendor;
  Site? _site;
  Project? _project;

  bool _loading = true;
  bool _updating = false;
  String? _error;

  late final InvoiceRepository _invoiceRepository;
  late final VendorRepository _vendorRepository;
  late final SiteRepository _siteRepository;
  late final ProjectRepository _projectRepository;

  @override
  void initState() {
    super.initState();

    _invoiceRepository =
        widget.invoiceRepository ?? InvoiceRepository();

    _vendorRepository =
        widget.vendorRepository ?? VendorRepository();

    _siteRepository = SiteRepository();
    _projectRepository = ProjectRepository();

    _loadPayment();
  }

  Future<void> _loadPayment() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final payment =
      await widget.repository.getById(
        widget.paymentId,
      );

      Invoice? invoice;
      Vendor? vendor;
      Site? site;
      Project? project;

      // Resolve Invoice.
      if (payment.invoiceId != null &&
          payment.invoiceId!.isNotEmpty) {
        try {
          invoice =
          await _invoiceRepository.getById(
            payment.invoiceId!,
          );
        } catch (_) {
          invoice = null;
        }
      }

      // Resolve Vendor.
      if (payment.vendorId != null &&
          payment.vendorId!.isNotEmpty) {
        try {
          vendor =
          await _vendorRepository.getById(
            payment.vendorId!,
          );
        } catch (_) {
          vendor = null;
        }
      }

      // Site and Project are resolved through the Invoice.
      if (invoice != null) {
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
            project =
            await _projectRepository.getById(
              invoice.projectId!,
            );
          } catch (_) {
            project = null;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _payment = payment;
        _invoice = invoice;
        _vendor = vendor;
        _site = site;
        _project = project;
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
      PaymentStatus status,
      ) async {
    if (_payment == null) return;

    setState(() {
      _updating = true;
    });

    try {
      final updated =
      await widget.repository.changeStatus(
        paymentId: _payment!.id,
        status: status,
      );

      if (!mounted) return;

      setState(() {
        _payment = updated;
      });

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
        setState(() {
          _updating = false;
        });
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

  String _invoiceDisplayName() {
    if (_payment?.invoiceId == null) {
      return '—';
    }

    if (_invoice == null) {
      return '—';
    }

    return _invoice!.invoiceNumber;
  }

  String _vendorDisplayName() {
    if (_payment?.vendorId == null) {
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
          title: const Text('Payment'),
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

    final payment = _payment!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(payment.paymentNumber),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
            _loading ? null : _loadPayment,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPayment,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      payment.direction ==
                          PaymentDirection.incoming
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      size: 48,
                      color: payment.direction ==
                          PaymentDirection.incoming
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      payment.paymentNumber,
                      style:
                      theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(
                        payment.status.displayName,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            const _SectionTitle(
              'Payment Information',
            ),

            _InfoRow(
              'Direction',
              payment.direction.displayName,
            ),

            _InfoRow(
              'Date',
              _formatDate(payment.paymentDate),
            ),

            _InfoRow(
              'Currency',
              payment.currencyCode,
            ),

            _InfoRow(
              'Method',
              payment.paymentMethod ?? '—',
            ),

            _InfoRow(
              'Reference',
              payment.referenceNumber ?? '—',
            ),

            const SizedBox(height: 16),

            const _SectionTitle(
              'Site & Project',
            ),

            _InfoRow(
              'Construction Site',
              _siteDisplayName(),
            ),

            _InfoRow(
              'Project',
              _projectDisplayName(),
            ),

            const SizedBox(height: 16),

            const _SectionTitle(
              'Invoice & Vendor',
            ),

            _InfoRow(
              'Invoice',
              _invoiceDisplayName(),
            ),

            _InfoRow(
              'Vendor',
              _vendorDisplayName(),
            ),

            const SizedBox(height: 16),

            const _SectionTitle(
              'Amount',
            ),

            _InfoRow(
              'Amount',
              '${payment.amount.toStringAsFixed(2)} '
                  '${payment.currencyCode}',
            ),

            const SizedBox(height: 16),

            const _SectionTitle(
              'Notes',
            ),

            Text(
              payment.notes == null ||
                  payment.notes!.trim().isEmpty
                  ? 'No notes'
                  : payment.notes!,
            ),

            const SizedBox(height: 24),

            if (_updating)
              const Center(
                child: CircularProgressIndicator(),
              )
            else
              ..._statusButtons(payment),
          ],
        ),
      ),
    );
  }

  List<Widget> _statusButtons(
      Payment payment,
      ) {
    switch (payment.status) {
      case PaymentStatus.pending:
        return [
          FilledButton(
            onPressed: () =>
                _changeStatus(
                  PaymentStatus.completed,
                ),
            child: const Text(
              'Complete Payment',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () =>
                _changeStatus(
                  PaymentStatus.cancelled,
                ),
            child: const Text(
              'Cancel Payment',
            ),
          ),
        ];

      case PaymentStatus.completed:
      case PaymentStatus.cancelled:
        return const [
          Center(
            child: Text(
              'No actions available.',
            ),
          ),
        ];
    }
  }

  String _formatDate(DateTime value) {
    return value
        .toIso8601String()
        .split('T')
        .first;
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
      const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}