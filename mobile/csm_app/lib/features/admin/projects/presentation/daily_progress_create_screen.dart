import 'package:flutter/material.dart';

import '../data/repositories/daily_progress_repository.dart';
import 'package:intl/intl.dart';



class DailyProgressCreateScreen extends StatefulWidget {
  const DailyProgressCreateScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.repository,
  });

  final String projectId;
  final String projectName;
  final DailyProgressRepository repository;

  @override
  State<DailyProgressCreateScreen> createState() =>
      _DailyProgressCreateScreenState();
}

class _DailyProgressCreateScreenState
    extends State<DailyProgressCreateScreen> {

  final _formKey = GlobalKey<FormState>();

  final _weatherController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _laborController = TextEditingController(text: '0');
  final _contractorController = TextEditingController(text: '0');
  final _progressController = TextEditingController(text: '0');
  final _workCompletedController = TextEditingController();
  final _workNextController = TextEditingController();
  final _materialsController = TextEditingController();
  final _equipmentController = TextEditingController();
  final _issuesController = TextEditingController();
  final _safetyController = TextEditingController();
  final _remarksController = TextEditingController();

  DateTime _logDate = DateTime.now();
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Progress'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              widget.projectName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Log Date'),
              subtitle: Text(
                DateFormat('yyyy-MM-dd').format(_logDate),
              ),
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

            const SizedBox(height: 12),

            TextFormField(
              controller: _weatherController,
              decoration: const InputDecoration(
                labelText: 'Weather',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _temperatureController,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Temperature (°C)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _laborController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Labor',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _contractorController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Contractor',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _progressController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Progress %',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _workCompletedController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Work Completed',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _workNextController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Work Planned Next',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _materialsController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Materials Used',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _equipmentController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Equipment Used',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _issuesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Issues / Delays',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _safetyController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Safety Notes',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _remarksController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Remarks',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: const Icon(Icons.save),
              label: const Text('Save Daily Progress'),
            ),
          ],
        ),
      ),
    );
  }
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await widget.repository.create(
        projectId: widget.projectId,
        logDate: _logDate,
        weatherCondition: _weatherController.text.trim(),
        temperatureCelsius:
        double.tryParse(_temperatureController.text),
        laborCount: int.tryParse(_laborController.text) ?? 0,
        contractorLaborCount:
        int.tryParse(_contractorController.text) ?? 0,
        progressPercentage:
        double.tryParse(_progressController.text) ?? 0,
        workCompleted: _workCompletedController.text.trim(),
        workPlannedNext: _workNextController.text.trim(),
        materialsUsedSummary: _materialsController.text.trim(),
        equipmentUsedSummary: _equipmentController.text.trim(),
        issues: _issuesController.text.trim(),
        safetyNotes: _safetyController.text.trim(),
        remarks: _remarksController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );

      setState(() => _isSaving = false);
    }
  }
}