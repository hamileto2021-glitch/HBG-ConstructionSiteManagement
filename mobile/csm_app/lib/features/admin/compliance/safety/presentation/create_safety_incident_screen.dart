import 'package:flutter/material.dart';


import '../../../sites/data/repositories/site_repository.dart';
import '../data/create_safety_incident_request.dart';
import '../data/safety_incident_repository.dart';

class CreateSafetyIncidentScreen extends StatefulWidget {
  const CreateSafetyIncidentScreen({
    super.key,
    required this.repository,
  });

  final SafetyIncidentRepository repository;

  @override
  State<CreateSafetyIncidentScreen> createState() =>
      _CreateSafetyIncidentScreenState();
}

class _CreateSafetyIncidentScreenState
    extends State<CreateSafetyIncidentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _siteRepository = SiteRepository();

  final _incidentNumberController =
  TextEditingController();

  final _titleController =
  TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _injuredController = TextEditingController();

  List<dynamic> _sites = [];
  String? _selectedSiteId;

  final DateTime _incidentDate = DateTime.now();

  String _severity = 'Minor';

  bool _saving = false;
  bool _loadingSites = true;

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
        _sites = sites.where((e) => e.isActive == true).toList();

        if (_sites.isNotEmpty) {
          _selectedSiteId = _sites.first.id as String;
        }

        _loadingSites = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingSites = false;
      });
    }
  }

  @override
  void dispose() {
    _incidentNumberController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _injuredController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSiteId == null) return;

    setState(() => _saving = true);

    try {
      await widget.repository.create(
        CreateSafetyIncidentRequest(
          constructionSiteId: _selectedSiteId!,
          incidentNumber:
          _incidentNumberController.text.trim(),
          occurredAtUtc: _incidentDate,
          locationDescription:
          _locationController.text.trim(),
          description: _descriptionController.text.trim(),
          severity: _severity,
          injuryOccurred:
          _injuredController.text.trim().isNotEmpty,
          medicalTreatmentRequired: false,
          lostTimeIncident: false,
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
        title: const Text('New Safety Incident'),
      ),
      body: _loadingSites
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _incidentNumberController,
              decoration: const InputDecoration(
                labelText: 'Incident Number',
                hintText: 'e.g. SI-001',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Incident number is required';
                }

                if (value.trim().length > 50) {
                  return 'Maximum 50 characters';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Incident Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
              value == null || value.isEmpty
                  ? 'Required'
                  : null,
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _selectedSiteId,
              decoration: const InputDecoration(
                labelText: 'Construction Site',
                border: OutlineInputBorder(),
              ),
              items: _sites.map((site) {
                return DropdownMenuItem<String>(
                  value: site.id as String,
                  child: Text(site.name as String),
                );
              }).toList(),
              validator: (value) => value == null
                  ? 'Please select a site'
                  : null,
              onChanged: (value) {
                setState(() {
                  _selectedSiteId = value;
                });
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location Description',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
              value == null || value.isEmpty
                  ? 'Required'
                  : null,
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _severity,
              decoration: const InputDecoration(
                labelText: 'Severity',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'NearMiss',
                  child: Text('Near Miss'),
                ),
                DropdownMenuItem(
                  value: 'Minor',
                  child: Text('Minor'),
                ),
                DropdownMenuItem(
                  value: 'Moderate',
                  child: Text('Moderate'),
                ),
                DropdownMenuItem(
                  value: 'Serious',
                  child: Text('Serious'),
                ),
                DropdownMenuItem(
                  value: 'Critical',
                  child: Text('Critical'),
                ),
                DropdownMenuItem(
                  value: 'Fatal',
                  child: Text('Fatal'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _severity = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _injuredController,
              decoration: const InputDecoration(
                labelText:
                'Injured Employee (Optional)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Incident Description',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
              value == null || value.isEmpty
                  ? 'Required'
                  : null,
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(
                _saving
                    ? 'Saving...'
                    : 'Create Incident',
              ),
            ),
          ],
        ),
      ),
    );
  }
}