import 'package:flutter/material.dart';

import '../../data/models/phases/project_phase.dart';
import '../../data/repositories/project_phase_repository.dart';

class ProjectPhaseEditScreen extends StatefulWidget {
  const ProjectPhaseEditScreen({
    super.key,
    required this.phase,
    required this.repository,
  });

  final ProjectPhase phase;
  final ProjectPhaseRepository repository;

  @override
  State<ProjectPhaseEditScreen> createState() =>
      _ProjectPhaseEditScreenState();
}

class _ProjectPhaseEditScreenState
    extends State<ProjectPhaseEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _sequenceController;

  DateTime? _plannedStartDate;
  DateTime? _plannedEndDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.phase.name,
    );

    _descriptionController = TextEditingController(
      text: widget.phase.description ?? '',
    );

    _sequenceController = TextEditingController(
      text: widget.phase.sequence.toString(),
    );

    _plannedStartDate = widget.phase.plannedStartDate;
    _plannedEndDate = widget.phase.plannedEndDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _sequenceController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: _plannedStartDate ?? DateTime.now(),
    );

    if (selected != null && mounted) {
      setState(() {
        _plannedStartDate = selected;

        if (_plannedEndDate != null &&
            _plannedEndDate!.isBefore(selected)) {
          _plannedEndDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: _plannedStartDate ?? DateTime(2000),
      lastDate: DateTime(2100),
      initialDate:
          _plannedEndDate ?? _plannedStartDate ?? DateTime.now(),
    );

    if (selected != null && mounted) {
      setState(() {
        _plannedEndDate = selected;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedPhase = await widget.repository.update(
        phaseId: widget.phase.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        sequence: int.parse(_sequenceController.text.trim()),
        plannedStartDate: _plannedStartDate,
        plannedEndDate: _plannedEndDate,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop<ProjectPhase>(updatedPhase);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Project Phase'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Phase name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Phase name is required.';
                }

                return null;
              },
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
            TextFormField(
              controller: _sequenceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Sequence',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final sequence = int.tryParse(
                  value?.trim() ?? '',
                );

                if (sequence == null || sequence <= 0) {
                  return 'Enter a sequence greater than 0.';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            _DateField(
              label: 'Planned start date',
              value: _formatDate(_plannedStartDate),
              onPressed: _selectStartDate,
            ),
            const SizedBox(height: 12),
            _DateField(
              label: 'Planned end date',
              value: _formatDate(_plannedEndDate),
              onPressed: _selectEndDate,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(
                _isSaving ? 'Saving...' : 'Save Changes',
              ),
            ),
            if (_isSaving) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Not set';
    }

    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final String label;
  final String value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(value),
            ),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }
}