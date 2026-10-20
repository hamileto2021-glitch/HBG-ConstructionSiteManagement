import 'package:flutter/material.dart';

import '../../data/models/project_milestone.dart';
import '../../data/repositories/project_milestone_repository.dart';

class ProjectMilestoneEditScreen extends StatefulWidget {
  const ProjectMilestoneEditScreen({
    super.key,
    required this.milestone,
    required this.repository,
  });

  final ProjectMilestone milestone;
  final ProjectMilestoneRepository repository;

  @override
  State<ProjectMilestoneEditScreen> createState() =>
      _ProjectMilestoneEditScreenState();
}

class _ProjectMilestoneEditScreenState
    extends State<ProjectMilestoneEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _progressController;
  late final TextEditingController _notesController;

  late DateTime _plannedDate;
  DateTime? _actualDate;
  late MilestoneStatus _status;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _nameController =
        TextEditingController(text: widget.milestone.name);

    _descriptionController = TextEditingController(
      text: widget.milestone.description ?? '',
    );

    _progressController = TextEditingController(
      text: widget.milestone.progressPercentage
          .toStringAsFixed(0),
    );

    _notesController = TextEditingController(
      text: widget.milestone.notes ?? '',
    );

    _plannedDate = widget.milestone.plannedDate;
    _actualDate = widget.milestone.actualDate;
    _status = widget.milestone.status;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _progressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickPlannedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _plannedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() => _plannedDate = picked);
    }
  }

  Future<void> _pickActualDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _actualDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() => _actualDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final updated = await widget.repository.update(
        milestoneId: widget.milestone.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        plannedDate: _plannedDate,
        actualDate: _actualDate,
        status: _status,
        progressPercentage: double.parse(
          _progressController.text.trim(),
        ),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pop(context, updated);
    } catch (e) {
      if (!mounted) return;

      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  String _date(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Project Milestone'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Milestone Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Planned Date'),
              subtitle: Text(_date(_plannedDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickPlannedDate,
            ),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Actual Date'),
              subtitle: Text(
                _actualDate == null
                    ? 'Not set'
                    : _date(_actualDate!),
              ),
              trailing: const Icon(Icons.event_available),
              onTap: _pickActualDate,
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<MilestoneStatus>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: MilestoneStatus.values
                  .map(
                    (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    switch (e) {
                      MilestoneStatus.pending => 'Pending',
                      MilestoneStatus.inProgress =>
                      'In Progress',
                      MilestoneStatus.completed =>
                      'Completed',
                      MilestoneStatus.delayed => 'Delayed',
                    },
                  ),
                ),
              )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _status = value);
                }
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _progressController,
              keyboardType:
              const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Progress %',
                suffixText: '%',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final p = double.tryParse(value ?? '');
                if (p == null) return 'Required';
                if (p < 0 || p > 100) {
                  return '0–100 only';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(
                _saving ? 'Saving...' : 'Save Changes',
              ),
            ),
          ],
        ),
      ),
    );
  }
}