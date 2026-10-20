import 'package:flutter/material.dart';

import '../../../../../core/network/api_client.dart';
import 'package:csm_app/features/admin/sites/data/models/site.dart';
import 'package:csm_app/features/admin/sites/data/repositories/site_repository.dart';
import '../data/create_safety_observation_request.dart';
import '../data/safety_observation_repository.dart';

class CreateSafetyObservationScreen extends StatefulWidget {
  const CreateSafetyObservationScreen({super.key});

  @override
  State<CreateSafetyObservationScreen> createState() =>
      _CreateSafetyObservationScreenState();
}

class _CreateSafetyObservationScreenState
    extends State<CreateSafetyObservationScreen> {
  final _formKey = GlobalKey<FormState>();

  late final SafetyObservationRepository _repository;
  late final SiteRepository _siteRepository;

  final _numberController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _immediateController = TextEditingController();
  final _recommendedController = TextEditingController();

  List<Site> _sites = [];
  String? _siteId;

  DateTime _date = DateTime.now();

  String _category = 'Housekeeping';
  String _risk = 'Low';

  bool _positive = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final api = ApiClient();

    _repository = SafetyObservationRepository(api);
    _siteRepository = SiteRepository(
      apiClient: api,
    );

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
    _numberController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _immediateController.dispose();
    _recommendedController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      _date = picked;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_siteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a construction site'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await _repository.create(
        CreateSafetyObservationRequest(
          constructionSiteId: _siteId!,
          observationNumber: _numberController.text.trim(),
          category: _category,
          observationDate: _date,
          location: _locationController.text.trim(),
          description: _descriptionController.text.trim(),
          riskLevel: _risk,
          positiveObservation: _positive,
          immediateAction: _immediateController.text.trim().isEmpty
              ? null
              : _immediateController.text.trim(),
          recommendedAction: _recommendedController.text.trim().isEmpty
              ? null
              : _recommendedController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Safety Observation'),
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
                  .map<DropdownMenuItem<String>>(
                    (site) => DropdownMenuItem<String>(
                  value: site.id,
                  child: Text(site.name),
                ),
              )
                  .toList(),
              onChanged: (v) => setState(() => _siteId = v),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _numberController,
              decoration: const InputDecoration(
                labelText: 'Observation Number',
                hintText: 'SO-001',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              v == null || v.trim().isEmpty ? 'Required' : null,
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: const [
                'Housekeeping',
                'PPE',
                'WorkingAtHeight',
                'Electrical',
                'Excavation',
                'Lifting',
                'FireSafety',
                'Environmental',
                'Other',
              ]
                  .map(
                    (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e),
                ),
              )
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _risk,
              decoration: const InputDecoration(
                labelText: 'Risk Level',
                border: OutlineInputBorder(),
              ),
              items: const ['Low', 'Medium', 'High', 'Critical']
                  .map(
                    (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e),
                ),
              )
                  .toList(),
              onChanged: (v) => setState(() => _risk = v!),
            ),

            const SizedBox(height: 16),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Observation Date'),
              subtitle: Text(
                '${_date.day}/${_date.month}/${_date.year}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              v == null || v.trim().isEmpty ? 'Required' : null,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (v) =>
              v == null || v.trim().isEmpty ? 'Required' : null,
            ),

            const SizedBox(height: 16),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Positive Observation'),
              value: _positive,
              onChanged: (v) => setState(() => _positive = v),
            ),

            const SizedBox(height: 8),

            TextFormField(
              controller: _immediateController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Immediate Action',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _recommendedController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Recommended Action',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(
                _saving ? 'Saving...' : 'Create Observation',
              ),
            ),
          ],
        ),
      ),
    );
  }
}