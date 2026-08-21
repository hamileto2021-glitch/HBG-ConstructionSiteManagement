import 'package:flutter/material.dart';

import '../../data/models/work_task.dart';
import '../../data/repositories/work_task_repository.dart';

class WorkTaskCreateScreen extends StatefulWidget {
  const WorkTaskCreateScreen({
    super.key,
    required this.projectId,
    required this.projectPhaseId,
    required this.repository,
  });

  final String projectId;
  final String projectPhaseId;
  final WorkTaskRepository repository;

  @override
  State<WorkTaskCreateScreen> createState() =>
      _WorkTaskCreateScreenState();
}

class _WorkTaskCreateScreenState
    extends State<WorkTaskCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _taskNumberController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _plannedStartDate;
  DateTime? _plannedEndDate;
  TaskPriority _priority = TaskPriority.normal;
  bool _isSaving = false;

  @override
  void dispose() {
    _taskNumberController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
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
      final task = await widget.repository.create(
        projectId: widget.projectId,
        projectPhaseId: widget.projectPhaseId,
        taskNumber: _taskNumberController.text.trim(),
        title: _titleController.text.trim(),
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
        plannedStartDate: _plannedStartDate,
        plannedEndDate: _plannedEndDate,
        priority: _priority,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop<WorkTask>(task);
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
        title: const Text('Create Work Task'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _taskNumberController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Task number',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Task number is required.';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Task title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Task title is required.';
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
            DropdownButtonFormField<TaskPriority>(
              initialValue: _priority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
              items: TaskPriority.values
                  .map(
                    (priority) => DropdownMenuItem<TaskPriority>(
                      value: priority,
                      child: Text(_priorityLabel(priority)),
                    ),
                  )
                  .toList(),
              onChanged: _isSaving
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() {
                          _priority = value;
                        });
                      }
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
                _isSaving ? 'Saving...' : 'Create Task',
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

  static String _priorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.normal:
        return 'Normal';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.critical:
        return 'Critical';
    }
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
