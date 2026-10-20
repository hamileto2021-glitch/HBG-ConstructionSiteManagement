import 'package:flutter/material.dart';
import 'package:csm_app/core/network/api_client.dart';

import '../data/non_conformance_report.dart';
import '../data/non_conformance_report_repository.dart';
import '../data/update_non_conformance_report_request.dart';

class EditNonConformanceReportScreen extends StatefulWidget {
  const EditNonConformanceReportScreen({
    super.key,
    required this.report,
  });

  final NonConformanceReport report;

  @override
  State<EditNonConformanceReportScreen> createState() =>
      _EditNonConformanceReportScreenState();
}

class _EditNonConformanceReportScreenState
    extends State<EditNonConformanceReportScreen> {
  final _formKey = GlobalKey<FormState>();

  late final NonConformanceReportRepository _repository;

  late final TextEditingController _title;
  late final TextEditingController _location;
  late final TextEditingController _description;
  late final TextEditingController _rootCause;
  late final TextEditingController _corrective;
  late final TextEditingController _preventive;

  late String _severity;
  late String _status;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _repository = NonConformanceReportRepository(ApiClient());

    final r = widget.report;

    _title = TextEditingController(text: r.title);
    _location = TextEditingController(text: r.location);
    _description = TextEditingController(text: r.description);
    _rootCause = TextEditingController(text: r.rootCause ?? '');
    _corrective =
        TextEditingController(text: r.correctiveAction ?? '');
    _preventive =
        TextEditingController(text: r.preventiveAction ?? '');

    _severity = r.severity;
    _status = r.status;
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _description.dispose();
    _rootCause.dispose();
    _corrective.dispose();
    _preventive.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final r = widget.report;

    await _repository.update(
      r.id,
      UpdateNonConformanceReportRequest(
        constructionSiteId: r.constructionSiteId,
        projectId: r.projectId,
        assignedToEmployeeId: r.assignedToEmployeeId,
        ncrNumber: r.ncrNumber,
        title: _title.text.trim(),
        description: _description.text.trim(),
        location: _location.text.trim(),
        severity: _severity,
        status: _status,
        reportedDate: r.reportedDate,
        dueDate: r.dueDate,
        closedDate:
        _status == 'Closed' ? DateTime.now().toUtc() : null,
        rootCause:
        _rootCause.text.trim().isEmpty ? null : _rootCause.text.trim(),
        correctiveAction:
        _corrective.text.trim().isEmpty ? null : _corrective.text.trim(),
        preventiveAction:
        _preventive.text.trim().isEmpty ? null : _preventive.text.trim(),
      ),
    );

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.report;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit NCR'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              r.constructionSiteName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(r.ncrNumber),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                'Open',
                'InProgress',
                'Closed',
              ]
                  .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e),
              ))
                  .toList(),
              onChanged: (v) => setState(() => _status = v!),
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
                  .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e),
              ))
                  .toList(),
              onChanged: (v) => setState(() => _severity = v!),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _location,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _description,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _rootCause,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Root Cause',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _corrective,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Corrective Action',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _preventive,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Preventive Action',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(_saving ? 'Saving...' : 'Update NCR'),
            ),
          ],
        ),
      ),
    );
  }
}