import 'package:flutter/material.dart';

import '../../data/models/milestones/milestone.dart';
import '../../data/repositories/milestone_repository.dart';

class MilestoneEditScreen extends StatefulWidget {
  const MilestoneEditScreen({
    super.key,
    required this.milestone,
    required this.repository,
  });

  final Milestone milestone;
  final MilestoneRepository repository;

  @override
  State<MilestoneEditScreen> createState() =>
      _MilestoneEditScreenState();
}

class _MilestoneEditScreenState
    extends State<MilestoneEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  late DateTime _plannedDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.milestone.name,
    );

    _descriptionController = TextEditingController(
      text: widget.milestone.description ?? '',
    );

    _plannedDate = widget.milestone.plannedDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectPlannedDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: _plannedDate,
    );

    if (selected != null && mounted) {
      setState(() {
        _plannedDate = selected;
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
      final milestone = await widget.repository.update(
        milestoneId: widget.milestone.id,
        projectPhaseId: widget.milestone.projectPhaseId,
        name: _nameController.text.trim(),
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
        plannedDate: _plannedDate,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop<Milestone>(milestone);
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
        title: const Text('Edit Milestone'),
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
                labelText: 'Milestone name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Milestone name is required.';
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
            _DateField(
              label: 'Planned date',
              value: _formatDate(_plannedDate),
              onPressed: _selectPlannedDate,
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

  static String _formatDate(DateTime date) {
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