import 'package:flutter/material.dart';

import '../data/models/project_delay.dart';
import '../data/repositories/project_delay_repository.dart';

class ProjectDelayCreateScreen extends StatefulWidget {
  const ProjectDelayCreateScreen({
    super.key,
    required this.projectId,
    required this.siteId,
  });

  final String projectId;
  final String siteId;

  @override
  State<ProjectDelayCreateScreen> createState() =>
      _ProjectDelayCreateScreenState();
}

class _ProjectDelayCreateScreenState
    extends State<ProjectDelayCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = ProjectDelayRepository();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _daysController = TextEditingController(text: '1');
  final _actionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  DelayCategory _category = DelayCategory.weather;

  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _daysController.dispose();
    _actionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final delay = ProjectDelay(
        id: '',
        projectId: widget.projectId,
        siteId: widget.siteId,
        delayDate: _selectedDate,
        category: _category,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        timeImpactDays: int.parse(_daysController.text),
        costImpact: 0,
        mitigationAction: _actionController.text.trim().isEmpty
            ? null
            : _actionController.text.trim(),
        isResolved: false,
      );

      await _repository.create(delay);

      if (!mounted) return;
      Navigator.pop(context, true);
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
        title: const Text('New Project Delay'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Delay Date'),
              subtitle: Text(
                _selectedDate.toIso8601String().split('T').first,
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<DelayCategory>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: DelayCategory.values
                  .map(
                    (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e.name[0].toUpperCase() + e.name.substring(1),
                  ),
                ),
              )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _category = value!),
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              v == null || v.isEmpty ? 'Required' : null,
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              v == null || v.isEmpty ? 'Required' : null,
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _daysController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Time Impact (Days)',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (int.tryParse(v) == null) return 'Invalid number';
                return null;
              },
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _actionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Mitigation Action (Optional)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(_saving ? 'Saving...' : 'Save Delay'),
            ),
          ],
        ),
      ),
    );
  }
}