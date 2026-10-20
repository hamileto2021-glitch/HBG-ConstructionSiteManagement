import 'package:flutter/material.dart';

import '../../data/models/daily_site_diary.dart';
import '../../data/repositories/daily_site_diary_repository.dart';

class DailySiteDiaryCreateScreen extends StatefulWidget {
  const DailySiteDiaryCreateScreen({
    super.key,
    required this.projectId,
    required this.constructionSiteId,
    required this.repository,
  });

  final String projectId;
  final String constructionSiteId;
  final DailySiteDiaryRepository repository;

  @override
  State<DailySiteDiaryCreateScreen> createState() =>
      _DailySiteDiaryCreateScreenState();
}

class _DailySiteDiaryCreateScreenState
    extends State<DailySiteDiaryCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _temperatureController = TextEditingController();
  final _workforceController = TextEditingController();
  final _equipmentController = TextEditingController();
  final _workPerformedController = TextEditingController();
  final _delayController = TextEditingController();
  final _safetyController = TextEditingController();

  DateTime _diaryDate = DateTime.now();
  WeatherType _weather = WeatherType.sunny;
  bool _saving = false;

  @override
  void dispose() {
    _temperatureController.dispose();
    _workforceController.dispose();
    _equipmentController.dispose();
    _workPerformedController.dispose();
    _delayController.dispose();
    _safetyController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _diaryDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() => _diaryDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await widget.repository.create(
        siteId: widget.constructionSiteId,
        projectId: widget.projectId,
        diaryDate: _diaryDate,
        weather: _weather,
        temperature:
        double.parse(_temperatureController.text.trim()),
        workforceCount:
        int.parse(_workforceController.text.trim()),
        equipmentInUse:
        int.parse(_equipmentController.text.trim()),
        workPerformed:
        _workPerformedController.text.trim(),
        delayReason: _delayController.text.trim().isEmpty
            ? null
            : _delayController.text.trim(),
        safetyObservation:
        _safetyController.text.trim().isEmpty
            ? null
            : _safetyController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    if (mounted) {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Daily Site Diary'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Diary Date'),
              subtitle: Text(
                '${_diaryDate.day}/${_diaryDate.month}/${_diaryDate.year}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<WeatherType>(
              initialValue: _weather,
              decoration: const InputDecoration(
                labelText: 'Weather',
                border: OutlineInputBorder(),
              ),
              items: WeatherType.values
                  .map(
                    (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e.name[0].toUpperCase() +
                        e.name.substring(1),
                  ),
                ),
              )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _weather = value);
                }
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _temperatureController,
              keyboardType:
              const TextInputType.numberWithOptions(
                  decimal: true),
              decoration: const InputDecoration(
                labelText: 'Temperature (°C)',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _workforceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Workforce Count',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _equipmentController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Equipment In Use',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _workPerformedController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Work Performed',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _delayController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Delay Reason',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _safetyController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Safety Observation',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(
                _saving ? 'Saving...' : 'Create Diary',
              ),
            ),
          ],
        ),
      ),
    );
  }
}