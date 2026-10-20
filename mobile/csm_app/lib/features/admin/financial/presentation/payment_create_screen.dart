import 'package:flutter/material.dart';

import '../data/models/payment.dart';
import '../data/repositories/payment_repository.dart';
import '../data/repositories/invoice_repository.dart';

import '../../procurement/data/models/vendor.dart';
import '../../procurement/data/repositories/vendor_repository.dart';

import '../../projects/data/models/project.dart';
import '../../projects/data/repositories/project_repository.dart';

import '../../sites/data/models/site.dart';
import '../../sites/data/repositories/site_repository.dart';

import '../data/models/invoice.dart';




class PaymentCreateScreen extends StatefulWidget {
  const PaymentCreateScreen({
    super.key,
    required this.repository,
    required this.invoiceRepository,
    required this.vendorRepository,
  });

  final PaymentRepository repository;
  final InvoiceRepository invoiceRepository;
  final VendorRepository vendorRepository;

  @override
  State<PaymentCreateScreen> createState() =>
      _PaymentCreateScreenState();
}

class _PaymentCreateScreenState
    extends State<PaymentCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _numberController = TextEditingController();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  final DateTime _paymentDate = DateTime.now();

  PaymentDirection _direction =
      PaymentDirection.incoming;

  final String _currency = 'ETB';

  String? _paymentMethod;

  List<Site> _sites = [];
  List<Project> _projects = [];
  List<Project> _filteredProjects = [];
  List<Invoice> _invoices = [];
  List<Vendor> _vendors = [];

  String? _selectedSite;
  String? _selectedProject;
  String? _selectedInvoice;
  String? _selectedVendor;

  bool _loading = true;
  bool _saving = false;

  final _methods = const [
    'Cash',
    'Bank Transfer',
    'Cheque',
    'Mobile Money',
  ];

  final _siteRepository = SiteRepository();
  final _projectRepository = ProjectRepository();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _siteRepository.getAll(),
        _projectRepository.getAll(),
        widget.invoiceRepository.getAll(),
        widget.vendorRepository.getAll(),
      ]);

      if (!mounted) return;

      setState(() {
        _sites = results[0] as List<Site>;
        _projects = results[1] as List<Project>;
        _invoices = results[2] as List<Invoice>;
        _vendors = results[3] as List<Vendor>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _onSiteChanged(String? siteId) {
    setState(() {
      _selectedSite = siteId;
      _selectedProject = null;

      _filteredProjects = _projects
          .where(
            (p) => p.constructionSiteId == siteId,
      )
          .toList();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await widget.repository.create(
        constructionSiteId: _selectedSite!,
        projectId: _selectedProject,
        invoiceId: _selectedInvoice,
        vendorId: _selectedVendor,
        paymentNumber: _numberController.text.trim(),
        paymentDate: _paymentDate,
        direction: _direction,
        amount: double.parse(_amountController.text),
        currencyCode: _currency,
        exchangeRate: 1,
        paymentMethod: _paymentMethod,
        referenceNumber:
        _referenceController.text.trim().isEmpty
            ? null
            : _referenceController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
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
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Payment'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _numberController,
              decoration: const InputDecoration(
                labelText: 'Payment Number',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<PaymentDirection>(
              initialValue: _direction,
              decoration: const InputDecoration(
                labelText: 'Direction',
                border: OutlineInputBorder(),
              ),
              items: PaymentDirection.values
                  .map(
                    (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e.displayName),
                ),
              )
                  .toList(),
              onChanged: (v) =>
                  setState(() => _direction = v!),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedSite,
              decoration: const InputDecoration(
                labelText: 'Construction Site',
                border: OutlineInputBorder(),
              ),
              items: _sites
                  .map(
                    (s) => DropdownMenuItem(
                  value: s.id,
                      child: Text(
                        '${s.siteCode} - ${s.name}',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                ),
              )
                  .toList(),
              validator: (v) =>
              v == null ? 'Select a site' : null,
              onChanged: _onSiteChanged,
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedProject,
              decoration: const InputDecoration(
                labelText: 'Project (Optional)',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('None'),
                ),
                ..._filteredProjects.map(
                      (p) => DropdownMenuItem(
                    value: p.id,
                    child: Text(
                      '${p.projectCode} - ${p.name}',
                    ),
                  ),
                ),
              ],
              onChanged: (v) =>
                  setState(() => _selectedProject = v),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedInvoice,
              decoration: const InputDecoration(
                labelText: 'Invoice',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('None'),
                ),
                ..._invoices.map(
                      (e) => DropdownMenuItem(
                    value: e.id,
                    child: Text(e.invoiceNumber),
                  ),
                ),
              ],
              onChanged: (v) =>
                  setState(() => _selectedInvoice = v),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedVendor,
              decoration: const InputDecoration(
                labelText: 'Vendor',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('None'),
                ),
                ..._vendors.map(
                      (e) => DropdownMenuItem(
                    value: e.id,
                    child: Text(
                      '${e.vendorCode} - ${e.name}',
                    ),
                  ),
                ),
              ],
              onChanged: (v) =>
                  setState(() => _selectedVendor = v),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _amountController,
              keyboardType:
              const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              decoration: const InputDecoration(
                labelText: 'Payment Method',
                border: OutlineInputBorder(),
              ),
              items: _methods
                  .map(
                    (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e),
                ),
              )
                  .toList(),
              onChanged: (v) =>
                  setState(() => _paymentMethod = v),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _referenceController,
              decoration: const InputDecoration(
                labelText: 'Reference Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: const Text('Create Payment'),
            ),
          ],
        ),
      ),
    );
  }
}