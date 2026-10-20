import 'package:flutter/material.dart';

import '../../data/models/daily_site_diary.dart';
import '../../data/repositories/daily_site_diary_repository.dart';

class DailySiteDiaryEditScreen extends StatefulWidget {
  const DailySiteDiaryEditScreen({
    super.key,
    required this.diary,
    required this.repository,
  });

  final DailySiteDiary diary;
  final DailySiteDiaryRepository repository;

  @override
  State<DailySiteDiaryEditScreen> createState() =>
      _DailySiteDiaryEditScreenState();
}

class _DailySiteDiaryEditScreenState
    extends State<DailySiteDiaryEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _temperatureController;
  late final TextEditingController _workforceController;
  late final TextEditingController _equipmentController;
  late final TextEditingController _workPerformedController;
  late final TextEditingController _delayController;
  late final TextEditingController _safetyController;

  late DateTime _diaryDate;
  late WeatherType _weather;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final diary = widget.diary;

    _diaryDate = diary.diaryDate;
    _weather = diary.weather;

    _temperatureController =
        TextEditingController(text: diary.temperature.toString());

    _workforceController =
        TextEditingController(text: diary.workforceCount.toString());

    _equipmentController =
        TextEditingController(text: diary.equipmentInUse.toString());

    _workPerformedController =
        TextEditingController(text: diary.workPerformed);

    _delayController =
        TextEditingController(text: diary.delayReason ?? '');

    _safetyController =
        TextEditingController(text: diary.safetyObservation ?? '');
  }

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
      await widget.repository.update(
        diaryId: widget.diary.id,
        siteId: widget.diary.siteId,
        projectId: widget.diary.projectId,
        diaryDate: _diaryDate,
        weather: _weather,
        temperature: double.parse(_temperatureController.text),
        workforceCount: int.parse(_workforceController.text),
        equipmentInUse: int.parse(_equipmentController.text),
        workPerformed: _workPerformedController.text.trim(),
        delayReason: _delayController.text.trim().isEmpty
            ? null
            : _delayController.text.trim(),
        safetyObservation: _safetyController.text.trim().isEmpty
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

      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Daily Diary'),
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
              const TextInputType.numberWithOptions(decimal: true),
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
                _saving ? 'Saving...' : 'Update Diary',
              ),
            ),
          ],
        ),
      ),
    );
  }
}