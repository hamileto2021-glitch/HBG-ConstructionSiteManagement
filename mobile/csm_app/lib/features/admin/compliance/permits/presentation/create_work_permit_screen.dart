import 'package:flutter/material.dart';


import 'package:csm_app/features/admin/sites/data/models/site.dart';
import 'package:csm_app/features/admin/sites/data/repositories/site_repository.dart';

import '../data/create_work_permit_request.dart';
import '../data/work_permit_repository.dart';
class CreateWorkPermitScreen extends StatefulWidget {
  const CreateWorkPermitScreen({
    super.key,
    required this.repository,
  });

  final WorkPermitRepository repository;

  @override
  State<CreateWorkPermitScreen> createState() =>
      _CreateWorkPermitScreenState();
}

class _CreateWorkPermitScreenState
    extends State<CreateWorkPermitScreen> {
  final _formKey = GlobalKey<FormState>();

  final _numberController = TextEditingController();
  final _nameController = TextEditingController();
  final _authorityController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _notesController = TextEditingController();

  final _siteRepository = SiteRepository();

  List<Site> _sites = [];
  String? _selectedSiteId;

  String _permitType = 'Hot Work';
  String _status = 'Draft';

  DateTime _applicationDate = DateTime.now();
  DateTime _issueDate = DateTime.now();
  DateTime _expiryDate = DateTime.now().add(
    const Duration(days: 30),
  );

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSites();
  }

  Future<void> _loadSites() async {
    try {
      final sites = await _siteRepository.getAll();

      if (!mounted) return;

      setState(() {
        _sites = sites;
        if (sites.isNotEmpty) {
          _selectedSiteId = sites.first.id;
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _numberController.dispose();
    _nameController.dispose();
    _authorityController.dispose();
    _conditionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int _statusValue(String value) {
    switch (value) {
      case 'Draft':
        return 1;
      case 'Pending':
        return 2;
      case 'Active':
        return 3;
      case 'Expired':
        return 4;
      case 'Suspended':
        return 5;
      case 'Revoked':
        return 6;
      case 'Closed':
        return 7;
      default:
        return 1;
    }
  }

  Future<void> _pickDate({
    required DateTime current,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      onSelected(picked);
    }
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year}';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSiteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a construction site'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final request = CreateWorkPermitRequest(
        constructionSiteId: _selectedSiteId!,
        permitNumber: _numberController.text.trim(),
        permitType: _permitType,
        name: _nameController.text.trim(),
        applicationDate: _applicationDate,
        issueDate: _issueDate,
        expiryDate: _expiryDate,
        issuingAuthority:
        _authorityController.text.trim().isEmpty
            ? null
            : _authorityController.text.trim(),
        status: _statusValue(_status),
        conditions:
        _conditionsController.text.trim().isEmpty
            ? null
            : _conditionsController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      await widget.repository.create(request);

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
        title: const Text('Create Work Permit'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedSiteId,
              decoration: const InputDecoration(
                labelText: 'Construction Site',
                border: OutlineInputBorder(),
              ),
              items: _sites
                  .map(
                    (site) => DropdownMenuItem<String>(
                  value: site.id,
                  child: Text(site.name),
                ),
              )
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedSiteId = v),
              validator: (v) =>
              v == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _numberController,
              decoration: const InputDecoration(
                labelText: 'Permit Number',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Permit Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _permitType,
              decoration: const InputDecoration(
                labelText: 'Permit Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Hot Work',
                  child: Text('Hot Work'),
                ),
                DropdownMenuItem(
                  value: 'Electrical',
                  child: Text('Electrical'),
                ),
                DropdownMenuItem(
                  value: 'Confined Space',
                  child: Text('Confined Space'),
                ),
                DropdownMenuItem(
                  value: 'Working at Height',
                  child: Text('Working at Height'),
                ),
                DropdownMenuItem(
                  value: 'Excavation',
                  child: Text('Excavation'),
                ),
              ],
              onChanged: (v) =>
                  setState(() => _permitType = v!),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Draft',
                  child: Text('Draft'),
                ),
                DropdownMenuItem(
                  value: 'Active',
                  child: Text('Active'),
                ),
                DropdownMenuItem(
                  value: 'Expired',
                  child: Text('Expired'),
                ),
                DropdownMenuItem(
                  value: 'Closed',
                  child: Text('Closed'),
                ),
                DropdownMenuItem(
                  value: 'Cancelled',
                  child: Text('Cancelled'),
                ),
              ],
              onChanged: (v) =>
                  setState(() => _status = v!),
            ),
            const SizedBox(height: 16),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Application Date'),
              subtitle: Text(_fmt(_applicationDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(
                current: _applicationDate,
                onSelected: (d) =>
                    setState(() => _applicationDate = d),
              ),
            ),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Issue Date'),
              subtitle: Text(_fmt(_issueDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(
                current: _issueDate,
                onSelected: (d) =>
                    setState(() => _issueDate = d),
              ),
            ),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Expiry Date'),
              subtitle: Text(_fmt(_expiryDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(
                current: _expiryDate,
                onSelected: (d) =>
                    setState(() => _expiryDate = d),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _authorityController,
              decoration: const InputDecoration(
                labelText: 'Issuing Authority',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _conditionsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Conditions',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(
                _saving
                    ? 'Creating...'
                    : 'Create Work Permit',
              ),
            ),
          ],
        ),
      ),
    );
  }
}