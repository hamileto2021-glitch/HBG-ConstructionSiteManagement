import 'package:flutter/material.dart';

import '../../projects/data/models/project.dart';
import '../../projects/data/repositories/project_repository.dart';
import '../../sites/data/models/site.dart';
import '../../sites/data/repositories/site_repository.dart';
import '../../procurement/data/models/vendor.dart';
import '../../procurement/data/repositories/vendor_repository.dart';
import '../data/models/invoice.dart';
import '../data/repositories/invoice_repository.dart';

class InvoiceCreateScreen extends StatefulWidget {
  const InvoiceCreateScreen({
    super.key,
    required this.repository,
    required this.siteRepository,
    required this.projectRepository,
    required this.vendorRepository,
    this.invoice,
  });

  final InvoiceRepository repository;
  final SiteRepository siteRepository;
  final ProjectRepository projectRepository;
  final VendorRepository vendorRepository;
  final Invoice? invoice;

  bool get isEdit => invoice != null;

  @override
  State<InvoiceCreateScreen> createState() =>
      _InvoiceCreateScreenState();
}

class _InvoiceCreateScreenState
    extends State<InvoiceCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _numberController = TextEditingController();
  final _subtotalController = TextEditingController();
  final _taxController = TextEditingController();
  final _currencyController =
      TextEditingController(text: 'ETB');
  final _exchangeController =
      TextEditingController(text: '1');
  final _descriptionController =
      TextEditingController();
  final _referenceController =
      TextEditingController();

  List<Site> _sites = [];
  List<Project> _projects = [];
  List<Vendor> _vendors = [];

  String? _selectedSiteId;
  String? _selectedProjectId;
  String? _selectedVendorId;

  InvoiceType _type = InvoiceType.client;

  DateTime _invoiceDate = DateTime.now();
  DateTime? _dueDate;

  bool _loading = true;
  bool _saving = false;

  double get _subtotal =>
      double.tryParse(_subtotalController.text) ?? 0;

  double get _tax =>
      double.tryParse(_taxController.text) ?? 0;

  double get _total => _subtotal + _tax;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final sites = await widget.siteRepository.getAll();
    final vendors =
        await widget.vendorRepository.getAll();
    final projects =
        await widget.projectRepository.getAll();

    if (!mounted) return;

    if (widget.isEdit) {
      final invoice = widget.invoice!;

      _type = invoice.type;
      _selectedSiteId = invoice.constructionSiteId;
      _selectedProjectId = invoice.projectId;
      _selectedVendorId = invoice.vendorId;
      _invoiceDate = invoice.invoiceDate;
      _dueDate = invoice.dueDate;

      _numberController.text = invoice.invoiceNumber;
      _subtotalController.text =
          invoice.subtotal.toStringAsFixed(2);
      _taxController.text =
          invoice.taxAmount.toStringAsFixed(2);
      _currencyController.text =
          invoice.currencyCode;
      _exchangeController.text =
          invoice.exchangeRate.toString();
      _descriptionController.text =
          invoice.description ?? '';
      _referenceController.text =
          invoice.externalReference ?? '';
    }

    setState(() {
      _sites = sites;
      _vendors = vendors;
      _projects = projects;
      _loading = false;
    });
  }

  Future<void> _pickInvoiceDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _invoiceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _invoiceDate = picked);
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? _invoiceDate,
      firstDate: _invoiceDate,
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSiteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Construction Site is required.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      if (widget.isEdit) {
        await widget.repository.update(
          invoiceId: widget.invoice!.id,
          constructionSiteId: _selectedSiteId!,
          projectId: _selectedProjectId,
          vendorId: _selectedVendorId,
          type: _type,
          invoiceDate: _invoiceDate,
          dueDate: _dueDate,
          subtotal: _subtotal,
          taxAmount: _tax,
          totalAmount: _total,
          currencyCode: _currencyController.text.trim(),
          exchangeRate: double.parse(
            _exchangeController.text,
          ),
          description:
              _descriptionController.text.trim(),
          externalReference:
              _referenceController.text.trim().isEmpty
                  ? null
                  : _referenceController.text.trim(),
        );
      } else {
        await widget.repository.create(
          constructionSiteId: _selectedSiteId!,
          projectId: _selectedProjectId,
          vendorId: _selectedVendorId,
          invoiceNumber: _numberController.text.trim(),
          type: _type,
          invoiceDate: _invoiceDate,
          dueDate: _dueDate,
          subtotal: _subtotal,
          taxAmount: _tax,
          totalAmount: _total,
          currencyCode: _currencyController.text.trim(),
          exchangeRate: double.parse(
            _exchangeController.text,
          ),
          description:
              _descriptionController.text.trim(),
          externalReference:
              _referenceController.text.trim().isEmpty
                  ? null
                  : _referenceController.text.trim(),
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

  String _date(DateTime value) =>
      value.toIso8601String().split('T').first;

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
        title: Text(
          widget.isEdit
              ? 'Edit Invoice'
              : 'Create Invoice',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<InvoiceType>(
              initialValue: _type,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Invoice Type',
                border: OutlineInputBorder(),
              ),
              items: InvoiceType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _type = value!);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedSiteId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Construction Site',
                border: OutlineInputBorder(),
              ),
              items: _sites
                  .map(
                    (site) => DropdownMenuItem(
                      value: site.id,
                      child: Text(
                        site.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedSiteId = value);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: _selectedProjectId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Project (Optional)',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('None'),
                ),
                ..._projects.map(
                  (project) => DropdownMenuItem(
                    value: project.id,
                    child: Text(
                      project.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedProjectId = value);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: _selectedVendorId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Vendor (Optional)',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('None'),
                ),
                ..._vendors.map(
                  (vendor) => DropdownMenuItem(
                    value: vendor.id,
                    child: Text(
                      vendor.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedVendorId = value);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _numberController,
              enabled: !widget.isEdit,
              decoration: const InputDecoration(
                labelText: 'Invoice Number',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty
                  ? 'Required'
                  : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickInvoiceDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_date(_invoiceDate)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDueDate,
                    icon: const Icon(Icons.event),
                    label: Text(
                      _dueDate == null
                          ? 'Due Date'
                          : _date(_dueDate!),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _subtotalController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
              decoration: const InputDecoration(
                labelText: 'Subtotal',
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
              controller: _taxController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
              decoration: const InputDecoration(
                labelText: 'Tax Amount',
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
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Total Amount',
                border: const OutlineInputBorder(),
                hintText: _total.toStringAsFixed(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _currencyController,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _exchangeController,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                    decoration: const InputDecoration(
                      labelText: 'Exchange Rate',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _referenceController,
              decoration: const InputDecoration(
                labelText: 'External Reference',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(
                widget.isEdit
                    ? 'Update Invoice'
                    : 'Create Invoice',
              ),
            ),
          ],
        ),
      ),
    );
  }
}