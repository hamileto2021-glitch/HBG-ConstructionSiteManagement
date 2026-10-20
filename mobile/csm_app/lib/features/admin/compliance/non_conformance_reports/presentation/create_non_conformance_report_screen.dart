import 'package:flutter/material.dart';
import 'package:csm_app/core/network/api_client.dart';

import '../../../sites/data/models/site.dart';
import '../../../sites/data/repositories/site_repository.dart';
import '../data/create_non_conformance_report_request.dart';
import '../data/non_conformance_report_repository.dart';

class CreateNonConformanceReportScreen extends StatefulWidget {
  const CreateNonConformanceReportScreen({super.key});

  @override
  State<CreateNonConformanceReportScreen> createState() =>
      _CreateNonConformanceReportScreenState();
}

class _CreateNonConformanceReportScreenState
    extends State<CreateNonConformanceReportScreen> {
  final _formKey = GlobalKey<FormState>();

  late final NonConformanceReportRepository _repository;
  late final SiteRepository _siteRepository;

  final _number = TextEditingController();
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _description = TextEditingController();

  List<Site> _sites = [];
  String? _siteId;

  String _severity = 'Minor';

  DateTime _reportedDate = DateTime.now();
  DateTime? _dueDate;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final api = ApiClient();

    _repository = NonConformanceReportRepository(api);
    _siteRepository = SiteRepository(apiClient: api);

    _loadSites();
  }

  Future<void> _loadSites() async {
    try {
      final data = await _siteRepository.getAll();

      if (!mounted) return;

      setState(() {
        _sites = data;
        if (data.isNotEmpty) {
          _siteId = data.first.id;
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _number.dispose();
    _title.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickReportedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _reportedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _reportedDate = picked);
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_siteId == null) return;

    setState(() => _saving = true);

    try {
      await _repository.create(
        CreateNonConformanceReportRequest(
          constructionSiteId: _siteId!,
          ncrNumber: _number.text.trim(),
          title: _title.text.trim(),
          description: _description.text.trim(),
          location: _location.text.trim(),
          severity: _severity,
          reportedDate: _reportedDate,
          dueDate: _dueDate,
        ),
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

  String _date(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New NCR'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _siteId,
              decoration: const InputDecoration(
                labelText: 'Construction Site',
                border: OutlineInputBorder(),
              ),
              items: _sites
                  .map(
                    (s) => DropdownMenuItem(
                  value: s.id,
                  child: Text(s.name),
                ),
              )
                  .toList(),
              onChanged: (v) => setState(() => _siteId = v),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _number,
              decoration: const InputDecoration(
                labelText: 'NCR Number',
                hintText: 'NCR-001',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              v == null || v.isEmpty ? 'Required' : null,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              v == null || v.isEmpty ? 'Required' : null,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _location,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              v == null || v.isEmpty ? 'Required' : null,
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _severity,
              decoration: const InputDecoration(
                labelText: 'Severity',
                border: OutlineInputBorder(),
              ),
              items: const [
                'Minor',
                'Major',
                'Critical',
              ]
                  .map(
                    (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e),
                ),
              )
                  .toList(),
              onChanged: (v) => setState(() => _severity = v!),
            ),

            const SizedBox(height: 16),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Reported Date'),
              subtitle: Text(_date(_reportedDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickReportedDate,
            ),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Due Date'),
              subtitle: Text(
                _dueDate == null ? 'Not set' : _date(_dueDate!),
              ),
              trailing: const Icon(Icons.event),
              onTap: _pickDueDate,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _description,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (v) =>
              v == null || v.isEmpty ? 'Required' : null,
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(
                _saving ? 'Saving...' : 'Create NCR',
              ),
            ),
          ],
        ),
      ),
    );
  }
}