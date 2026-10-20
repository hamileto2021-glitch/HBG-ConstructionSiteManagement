
import 'package:flutter/material.dart';

import '../../data/models/work_task.dart';
import '../../data/repositories/work_task_repository.dart';

class WorkTaskEditScreen extends StatefulWidget {
  const WorkTaskEditScreen({
    super.key,
    required this.task,
    required this.repository,
  });

  final WorkTask task;
  final WorkTaskRepository repository;

  @override
  State<WorkTaskEditScreen> createState() =>
      _WorkTaskEditScreenState();
}

class _WorkTaskEditScreenState
    extends State<WorkTaskEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _taskNumberController;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  late DateTime? _plannedStartDate;
  late DateTime? _plannedEndDate;
  late Priority _priority;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _taskNumberController = TextEditingController(
      text: widget.task.taskNumber,
    );

    _titleController = TextEditingController(
      text: widget.task.title,
    );

    _descriptionController = TextEditingController(
      text: widget.task.description ?? '',
    );

    _plannedStartDate = widget.task.plannedStartDate;
    _plannedEndDate = widget.task.plannedEndDate;
    _priority = widget.task.priority;
  }

  @override
  void dispose() {
    _taskNumberController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: _plannedStartDate ?? DateTime.now(),
    );

    if (date != null && mounted) {
      setState(() {
        _plannedStartDate = date;

        if (_plannedEndDate != null &&
            _plannedEndDate!.isBefore(date)) {
          _plannedEndDate = null;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: _plannedStartDate ?? DateTime(2000),
      lastDate: DateTime(2100),
      initialDate:
      _plannedEndDate ??
          _plannedStartDate ??
          DateTime.now(),
    );

    if (date != null && mounted) {
      setState(() => _plannedEndDate = date);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updatedTask = await widget.repository.update(
        taskId: widget.task.id,
        projectPhaseId: widget.task.projectPhaseId,
        taskNumber: _taskNumberController.text.trim(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        plannedStartDate: _plannedStartDate,
        plannedEndDate: _plannedEndDate,
        priority: _priority,
      );

      if (!mounted) return;

      Navigator.pop(context, updatedTask);
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Work Task'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _taskNumberController,
              decoration: const InputDecoration(
                labelText: 'Task Number',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              v == null || v.trim().isEmpty
                  ? 'Task Number is required'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              v == null || v.trim().isEmpty
                  ? 'Task Title is required'
                  : null,
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
            DropdownButtonFormField<Priority>(
              initialValue: _priority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
              items: Priority.values
                  .map(
                    (p) => DropdownMenuItem(
                  value: p,
                  child: Text(_priorityLabel(p)),
                ),
              )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _priority = value);
                }
              },
            ),
            const SizedBox(height: 16),
            _DateField(
              label: 'Planned Start',
              value: _formatDate(_plannedStartDate),
              onTap: _pickStartDate,
            ),
            const SizedBox(height: 12),
            _DateField(
              label: 'Planned End',
              value: _formatDate(_plannedEndDate),
              onTap: _pickEndDate,
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

  static String _priorityLabel(Priority p) {
    switch (p) {
      case Priority.low:
        return 'Low';
      case Priority.normal:
        return 'Normal';
      case Priority.high:
        return 'High';
      case Priority.critical:
        return 'Critical';
    }
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';

    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Row(
          children: [
            Expanded(child: Text(value)),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }
}