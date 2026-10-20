import 'package:flutter/material.dart';

import '../data/update_work_permit_request.dart';
import '../data/work_permit.dart';
import '../data/work_permit_repository.dart';

class EditWorkPermitScreen extends StatefulWidget {
  const EditWorkPermitScreen({
    super.key,
    required this.repository,
    required this.permit,
  });

  final WorkPermitRepository repository;
  final WorkPermit permit;

  @override
  State<EditWorkPermitScreen> createState() =>
      _EditWorkPermitScreenState();
}

class _EditWorkPermitScreenState
    extends State<EditWorkPermitScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _numberController;
  late final TextEditingController _nameController;
  late final TextEditingController _authorityController;
  late final TextEditingController _conditionsController;
  late final TextEditingController _notesController;

  late String _permitType;
  late String _status;

  late DateTime _applicationDate;
  late DateTime _issueDate;
  late DateTime _expiryDate;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final p = widget.permit;

    _numberController =
        TextEditingController(text: p.permitNumber);
    _nameController =
        TextEditingController(text: p.name);
    _authorityController =
        TextEditingController(text: p.issuingAuthority ?? '');
    _conditionsController =
        TextEditingController(text: p.conditions ?? '');
    _notesController =
        TextEditingController(text: p.notes ?? '');

    _permitType = p.permitType;
    _status = p.status;

    _applicationDate = p.applicationDate ?? DateTime.now();

    _issueDate =
        p.issueDate ?? p.applicationDate ?? DateTime.now();

    _expiryDate =
        p.expiryDate ??
            p.issueDate?.add(const Duration(days: 30)) ??
            DateTime.now().add(const Duration(days: 30));
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

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year}';

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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final request = UpdateWorkPermitRequest(
        constructionSiteId: widget.permit.constructionSiteId,
        projectId: widget.permit.projectId,
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
        expiryAlertDays: widget.permit.expiryAlertDays,
        conditions:
        _conditionsController.text.trim().isEmpty
            ? null
            : _conditionsController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      await widget.repository.update(
        widget.permit.id,
        request,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Work Permit'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _numberController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Permit Number',
                border: OutlineInputBorder(),
              ),
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
                  value: 'Pending',
                  child: Text('Pending'),
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
                  value: 'Suspended',
                  child: Text('Suspended'),
                ),
                DropdownMenuItem(
                  value: 'Revoked',
                  child: Text('Revoked'),
                ),
                DropdownMenuItem(
                  value: 'Closed',
                  child: Text('Closed'),
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
              label: Text(
                _saving
                    ? 'Updating...'
                    : 'Update Work Permit',
              ),
            ),
          ],
        ),
      ),
    );
  }
}