import 'package:flutter/material.dart';

import '../data/models/project.dart';
import '../data/repositories/project_repository.dart';

class ProjectEditScreen extends StatefulWidget {
  const ProjectEditScreen({
    super.key,
    required this.project,
    required this.repository,
  });

  final Project project;
  final ProjectRepository repository;

  @override
  State<ProjectEditScreen> createState() => _ProjectEditScreenState();
}

class _ProjectEditScreenState extends State<ProjectEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _contractValueController;

  DateTime? _plannedStartDate;
  DateTime? _plannedEndDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.project.name,
    );

    _descriptionController = TextEditingController(
      text: widget.project.description ?? '',
    );

    _contractValueController = TextEditingController(
      text: widget.project.contractValue.toStringAsFixed(2),
    );

    _plannedStartDate = widget.project.plannedStartDate;
    _plannedEndDate = widget.project.plannedEndDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _contractValueController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final date = await _selectDate(
      initialDate: _plannedStartDate ?? DateTime.now(),
    );

    if (date == null || !mounted) {
      return;
    }

    setState(() {
      _plannedStartDate = date;

      if (_plannedEndDate != null &&
          _plannedEndDate!.isBefore(date)) {
        _plannedEndDate = null;
      }
    });
  }

  Future<void> _selectEndDate() async {
    final date = await _selectDate(
      initialDate:
          _plannedEndDate ??
          _plannedStartDate ??
          DateTime.now(),
      firstDate: _plannedStartDate ?? DateTime(2000),
    );

    if (date == null || !mounted) {
      return;
    }

    setState(() {
      _plannedEndDate = date;
    });
  }

  Future<DateTime?> _selectDate({
    required DateTime initialDate,
    DateTime? firstDate,
  }) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: DateTime(2100),
    );
  }

  Future<void> _updateProject() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final contractValue = double.tryParse(
      _contractValueController.text.trim(),
    );

    if (contractValue == null || contractValue < 0) {
      _showMessage('Enter a valid contract value.');
      return;
    }

    if (_plannedStartDate != null &&
        _plannedEndDate != null &&
        _plannedEndDate!.isBefore(_plannedStartDate!)) {
      _showMessage(
        'Planned end date cannot be before planned start date.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedProject = await widget.repository.update(
        projectId: widget.project.id,
        name: _nameController.text.trim(),
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
        plannedStartDate: _plannedStartDate,
        plannedEndDate: _plannedEndDate,
        contractValue: contractValue,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(updatedProject);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      _showMessage(error.toString());
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Not selected';
    }

    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Project'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              initialValue: widget.project.projectCode,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Project Code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: widget.project.constructionSiteId,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Construction Site ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Project Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Project name is required.';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contractValueController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Contract Value',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final amount = double.tryParse(
                  value?.trim() ?? '',
                );

                if (amount == null || amount < 0) {
                  return 'Enter a valid contract value.';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                title: const Text('Planned Start'),
                subtitle: Text(
                  _formatDate(_plannedStartDate),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _isSaving ? null : _selectStartDate,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text('Planned End'),
                subtitle: Text(
                  _formatDate(_plannedEndDate),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _isSaving ? null : _selectEndDate,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _updateProject,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(
                _isSaving ? 'Saving...' : 'Save Changes',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
