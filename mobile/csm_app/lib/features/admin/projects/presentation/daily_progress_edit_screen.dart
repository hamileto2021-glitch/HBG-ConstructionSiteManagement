import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models/daily_progress.dart';
import '../data/repositories/daily_progress_repository.dart';

class DailyProgressEditScreen extends StatefulWidget {
  const DailyProgressEditScreen({
    super.key,
    required this.log,
    required this.repository,
  });

  final DailyProgressLog log;
  final DailyProgressRepository repository;

  @override
  State<DailyProgressEditScreen> createState() =>
      _DailyProgressEditScreenState();
}

class _DailyProgressEditScreenState
    extends State<DailyProgressEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _date = DateFormat('yyyy-MM-dd');

  late DateTime _logDate;

  late final TextEditingController _weather;
  late final TextEditingController _temperature;
  late final TextEditingController _labor;
  late final TextEditingController _contractor;
  late final TextEditingController _progress;
  late final TextEditingController _completed;
  late final TextEditingController _next;
  late final TextEditingController _materials;
  late final TextEditingController _equipment;
  late final TextEditingController _issues;
  late final TextEditingController _safety;
  late final TextEditingController _remarks;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final log = widget.log;

    _logDate = log.logDate;

    _weather = TextEditingController(text: log.weatherCondition ?? '');
    _temperature = TextEditingController(
      text: log.temperatureCelsius?.toString() ?? '',
    );
    _labor = TextEditingController(text: log.laborCount.toString());
    _contractor = TextEditingController(
      text: log.contractorLaborCount.toString(),
    );
    _progress = TextEditingController(
      text: log.progressPercentage.toStringAsFixed(0),
    );
    _completed = TextEditingController(text: log.workCompleted ?? '');
    _next = TextEditingController(text: log.workPlannedNext ?? '');
    _materials = TextEditingController(
      text: log.materialsUsedSummary ?? '',
    );
    _equipment = TextEditingController(
      text: log.equipmentUsedSummary ?? '',
    );
    _issues = TextEditingController(text: log.issues ?? '');
    _safety = TextEditingController(text: log.safetyNotes ?? '');
    _remarks = TextEditingController(text: log.remarks ?? '');
  }

  @override
  void dispose() {
    _weather.dispose();
    _temperature.dispose();
    _labor.dispose();
    _contractor.dispose();
    _progress.dispose();
    _completed.dispose();
    _next.dispose();
    _materials.dispose();
    _equipment.dispose();
    _issues.dispose();
    _safety.dispose();
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updated = await widget.repository.update(
        logId: widget.log.id,
        logDate: _logDate,
        weatherCondition: _weather.text.trim(),
        temperatureCelsius: double.tryParse(_temperature.text),
        laborCount: int.tryParse(_labor.text) ?? 0,
        contractorLaborCount:
        int.tryParse(_contractor.text) ?? 0,
        progressPercentage:
        double.tryParse(_progress.text) ?? 0,
        workCompleted: _completed.text.trim(),
        workPlannedNext: _next.text.trim(),
        materialsUsedSummary: _materials.text.trim(),
        equipmentUsedSummary: _equipment.text.trim(),
        issues: _issues.text.trim(),
        safetyNotes: _safety.text.trim(),
        remarks: _remarks.text.trim(),
      );

      if (!mounted) return;

      Navigator.pop(context, updated);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );

      setState(() => _isSaving = false);
    }
  }

  Widget _field(
      TextEditingController controller,
      String label, {
        int lines = 1,
        TextInputType? keyboard,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: lines,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Daily Progress'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Log Date'),
              subtitle: Text(_date.format(_logDate)),
              onTap: _isSaving
                  ? null
                  : () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _logDate,
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2035),
                );

                if (picked != null) {
                  setState(() => _logDate = picked);
                }
              },
            ),
            _field(_weather, 'Weather'),
            _field(
              _temperature,
              'Temperature (°C)',
              keyboard:
              const TextInputType.numberWithOptions(decimal: true),
            ),
            Row(
              children: [
                Expanded(
                  child: _field(
                    _labor,
                    'Labor',
                    keyboard: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    _contractor,
                    'Contractor',
                    keyboard: TextInputType.number,
                  ),
                ),
              ],
            ),
            _field(
              _progress,
              'Progress %',
              keyboard:
              const TextInputType.numberWithOptions(decimal: true),
            ),
            _field(_completed, 'Work Completed', lines: 3),
            _field(_next, 'Work Planned Next', lines: 3),
            _field(_materials, 'Materials Used', lines: 2),
            _field(_equipment, 'Equipment Used', lines: 2),
            _field(_issues, 'Issues', lines: 2),
            _field(_safety, 'Safety Notes', lines: 2),
            _field(_remarks, 'Remarks', lines: 2),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: const Icon(Icons.save),
              label: const Text('Update Daily Progress'),
            ),
          ],
        ),
      ),
    );
  }
}