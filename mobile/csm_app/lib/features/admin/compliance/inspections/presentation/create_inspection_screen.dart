import 'package:flutter/material.dart';
import 'package:csm_app/features/admin/sites/data/models/site.dart';
import 'package:csm_app/features/admin/sites/data/repositories/site_repository.dart';

import '../data/create_inspection_request.dart';
import '../data/inspection.dart';
import '../data/inspection_repository.dart';
import '../data/update_inspection_request.dart';

class CreateInspectionScreen extends StatefulWidget {
  const CreateInspectionScreen({
    super.key,
    required this.repository,
    this.inspection,
  });

  final InspectionRepository repository;
  final Inspection? inspection;

  bool get isEdit => inspection != null;

  @override
  State<CreateInspectionScreen> createState() =>
      _CreateInspectionScreenState();
}

class _CreateInspectionScreenState
    extends State<CreateInspectionScreen> {
  final _formKey = GlobalKey<FormState>();

  final _siteRepository = SiteRepository();

  final _numberController = TextEditingController();
  final _titleController = TextEditingController();
  final _externalInspectorController = TextEditingController();
  final _organizationController = TextEditingController();
  final _summaryController = TextEditingController();

  List<Site> _sites = [];
  String? _selectedSiteId;

  String _inspectionType = 'Safety';
  int _status = 1; // Scheduled

  DateTime _scheduled =
  DateTime.now().add(const Duration(days: 1));
  DateTime? _startedAt;
  DateTime? _completedAt;

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    if (widget.isEdit) {
      final inspection = widget.inspection!;

      _numberController.text = inspection.inspectionNumber;
      _titleController.text = inspection.title;
      _externalInspectorController.text =
          inspection.externalInspectorName ?? '';
      _organizationController.text =
          inspection.externalOrganization ?? '';
      _summaryController.text = inspection.summary ?? '';

      _selectedSiteId = inspection.constructionSiteId;
      _inspectionType = inspection.inspectionType;

      _scheduled = inspection.scheduledAtUtc;
      _startedAt = inspection.startedAtUtc;
      _completedAt = inspection.completedAtUtc;

      switch (inspection.status) {
        case 'In Progress':
          _status = 2;
          break;
        case 'Passed':
          _status = 3;
          break;
        case 'Passed With Observations':
          _status = 4;
          break;
        case 'Failed':
          _status = 5;
          break;
        case 'Corrective Action Required':
          _status = 6;
          break;
        case 'Closed':
          _status = 7;
          break;
        case 'Cancelled':
          _status = 8;
          break;
        default:
          _status = 1;
      }
    } else {
      _numberController.text =
      'INSP-${DateTime.now().year}-001';
    }

    _loadSites();
  }

  Future<void> _loadSites() async {
    try {
      final data = await _siteRepository.getAll();

      if (!mounted) return;

      setState(() {
        _sites = data.where((e) => e.isActive).toList();

        if (_selectedSiteId == null &&
            _sites.isNotEmpty) {
          _selectedSiteId = _sites.first.id;
        }

        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _pickScheduledDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduled,
      firstDate: DateTime.now(),
      lastDate:
      DateTime.now().add(const Duration(days: 365)),
    );

    if (date == null) return;

    setState(() {
      _scheduled = DateTime(
        date.year,
        date.month,
        date.day,
        9,
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSiteId == null) return;

    if (_status == 2 && _startedAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Start time is required for In Progress',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {


      if (widget.isEdit) {
        final updateRequest = UpdateInspectionRequest(
          constructionSiteId: _selectedSiteId!,
          projectId: null,
          inspectionNumber: _numberController.text.trim(),
          inspectionType: _inspectionType,
          title: _titleController.text.trim(),
          scheduledAtUtc: _scheduled,
          startedAtUtc: _startedAt,
          completedAtUtc: _completedAt,
          inspectorEmployeeId: null,
          externalInspectorName:
          _externalInspectorController.text.trim().isEmpty
              ? null
              : _externalInspectorController.text.trim(),
          externalOrganization:
          _organizationController.text.trim().isEmpty
              ? null
              : _organizationController.text.trim(),
          status: _status,
          summary: _summaryController.text.trim().isEmpty
              ? null
              : _summaryController.text.trim(),
          correctiveActionRequired: null,
          correctiveActionDueDate: null,
          signedOffBy: null,
          signedOffAtUtc: null,
          checklistItems: const [],
        );

        await widget.repository.update(
          widget.inspection!.id,
          updateRequest,
        );
      } else {
        final createRequest = CreateInspectionRequest(
          constructionSiteId: _selectedSiteId!,
          inspectionNumber: _numberController.text.trim(),
          inspectionType: _inspectionType,
          title: _titleController.text.trim(),
          scheduledAtUtc: _scheduled,
          externalInspectorName:
          _externalInspectorController.text.trim().isEmpty
              ? null
              : _externalInspectorController.text.trim(),
          externalOrganization:
          _organizationController.text.trim().isEmpty
              ? null
              : _organizationController.text.trim(),
          summary: _summaryController.text.trim().isEmpty
              ? null
              : _summaryController.text.trim(),
          status: _status,
          checklistItems: const [],
        );

        await widget.repository.create(createRequest);
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

  @override
  void dispose() {
    _numberController.dispose();
    _titleController.dispose();
    _externalInspectorController.dispose();
    _organizationController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
          '${value.month.toString().padLeft(2, '0')}/'
          '${value.year}';

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
              ? 'Edit Inspection'
              : 'New Inspection',
        ),
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
                    (e) => DropdownMenuItem(
                  value: e.id,
                  child: Text(e.name),
                ),
              )
                  .toList(),
              validator: (v) =>
              v == null ? 'Select a site' : null,
              onChanged: (v) =>
                  setState(() => _selectedSiteId = v),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _numberController,
              decoration: const InputDecoration(
                labelText: 'Inspection Number',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              v == null || v.isEmpty
                  ? 'Required'
                  : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Inspection Title',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              v == null || v.isEmpty
                  ? 'Required'
                  : null,
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _inspectionType,
              decoration: const InputDecoration(
                labelText: 'Inspection Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Safety',
                  child: Text('Safety'),
                ),
                DropdownMenuItem(
                  value: 'Quality',
                  child: Text('Quality'),
                ),
                DropdownMenuItem(
                  value: 'Environmental',
                  child: Text('Environmental'),
                ),
                DropdownMenuItem(
                  value: 'Equipment',
                  child: Text('Equipment'),
                ),
                DropdownMenuItem(
                  value: 'Compliance',
                  child: Text('Compliance'),
                ),
              ],
              onChanged: (v) =>
                  setState(() => _inspectionType = v!),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<int>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 1,
                  child: Text('Scheduled'),
                ),
                DropdownMenuItem(
                  value: 2,
                  child: Text('In Progress'),
                ),
                DropdownMenuItem(
                  value: 3,
                  child: Text('Passed'),
                ),
                DropdownMenuItem(
                  value: 4,
                  child:
                  Text('Passed With Observations'),
                ),
                DropdownMenuItem(
                  value: 5,
                  child: Text('Failed'),
                ),
                DropdownMenuItem(
                  value: 6,
                  child: Text(
                    'Corrective Action Required',
                  ),
                ),
                DropdownMenuItem(
                  value: 7,
                  child: Text('Closed'),
                ),
                DropdownMenuItem(
                  value: 8,
                  child: Text('Cancelled'),
                ),
              ],
              onChanged: (v) {
                if (v == null) return;

                setState(() {
                  _status = v;

                  if (_status == 2 && _startedAt == null) {
                    _startedAt = _scheduled;
                  }

                  if ((_status == 3 || _status == 4 || _status == 5 || _status == 7) &&
                      _completedAt == null) {
                    _completedAt = _startedAt ?? _scheduled;
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Scheduled Date'),
              subtitle: Text(_date(_scheduled)),
              onTap: _pickScheduledDate,
            ),

            if (_status >= 2) ...[
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.play_circle_outline,
                ),
                title: const Text('Started'),
                subtitle: Text(
                  _startedAt == null
                      ? 'Not started'
                      : '${_date(_startedAt!)} '
                      '${_startedAt!.hour.toString().padLeft(2, '0')}:'
                      '${_startedAt!.minute.toString().padLeft(2, '0')}',
                ),
              ),
            ],

            if (_status >= 3) ...[
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.task_alt),
                title: const Text('Completed'),
                subtitle: Text(
                  _completedAt == null
                      ? 'Not completed'
                      : '${_date(_completedAt!)} '
                      '${_completedAt!.hour.toString().padLeft(2, '0')}:'
                      '${_completedAt!.minute.toString().padLeft(2, '0')}',
                ),
              ),
            ],

            const Divider(),

            TextFormField(
              controller:
              _externalInspectorController,
              decoration: const InputDecoration(
                labelText:
                'External Inspector (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _organizationController,
              decoration: const InputDecoration(
                labelText:
                'Organization (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _summaryController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Inspection Summary',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(
                _saving
                    ? (widget.isEdit
                    ? 'Updating...'
                    : 'Creating...')
                    : (widget.isEdit
                    ? 'Update Inspection'
                    : 'Create Inspection'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}