import 'package:flutter/material.dart';

import '../../../../../core/network/api_client.dart';
import '../data/safety_observation.dart';
import '../data/safety_observation_repository.dart';
import '../data/update_safety_observation_request.dart';

class EditSafetyObservationScreen extends StatefulWidget {
  const EditSafetyObservationScreen({
    super.key,
    required this.observation,
  });

  final SafetyObservation observation;

  @override
  State<EditSafetyObservationScreen> createState() =>
      _EditSafetyObservationScreenState();
}

class _EditSafetyObservationScreenState
    extends State<EditSafetyObservationScreen> {
  final _formKey = GlobalKey<FormState>();

  late final SafetyObservationRepository _repository;

  late final TextEditingController _location;
  late final TextEditingController _description;
  late final TextEditingController _immediate;
  late final TextEditingController _recommended;

  late String _status;
  late String _risk;
  late bool _positive;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _repository = SafetyObservationRepository(ApiClient());

    final o = widget.observation;

    _location = TextEditingController(text: o.location);
    _description = TextEditingController(text: o.description);
    _immediate = TextEditingController(text: o.immediateAction ?? '');
    _recommended =
        TextEditingController(text: o.recommendedAction ?? '');

    _status = o.status;
    _risk = o.riskLevel;
    _positive = o.positiveObservation;
  }

  @override
  void dispose() {
    _location.dispose();
    _description.dispose();
    _immediate.dispose();
    _recommended.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final o = widget.observation;

    await _repository.update(
      o.id,
      UpdateSafetyObservationRequest(
        constructionSiteId: o.constructionSiteId,
        projectId: o.projectId,
        employeeId: o.employeeId,
        observationNumber: o.observationNumber,
        category: o.category,
        observationDate: o.observationDate,
        location: _location.text.trim(),
        description: _description.text.trim(),
        riskLevel: _risk,
        positiveObservation: _positive,
        immediateAction:
        _immediate.text.trim().isEmpty ? null : _immediate.text.trim(),
        recommendedAction:
        _recommended.text.trim().isEmpty ? null : _recommended.text.trim(),
        status: _status,
        closedAtUtc: _status == 'Closed'
            ? DateTime.now().toUtc()
            : null,
      ),
    );

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Observation'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              widget.observation.constructionSiteName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(widget.observation.observationNumber),

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
              initialValue: _risk,
              decoration: const InputDecoration(
                labelText: 'Risk Level',
                border: OutlineInputBorder(),
              ),
              items: const [
                'Low',
                'Medium',
                'High',
                'Critical',
              ]
                  .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e),
              ))
                  .toList(),
              onChanged: (v) => setState(() => _risk = v!),
            ),

            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Positive Observation'),
              value: _positive,
              onChanged: (v) => setState(() => _positive = v),
            ),

            const SizedBox(height: 8),

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
              controller: _immediate,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Immediate Action',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _recommended,
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
              label: Text(_saving ? 'Saving...' : 'Update Observation'),
            ),
          ],
        ),
      ),
    );
  }
}