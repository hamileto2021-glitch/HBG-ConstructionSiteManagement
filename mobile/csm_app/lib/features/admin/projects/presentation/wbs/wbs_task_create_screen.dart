import 'package:flutter/material.dart';

import '../../data/models/wbs_task.dart';
import '../../data/repositories/wbs_task_repository.dart';

class WbsTaskCreateScreen extends StatefulWidget {
  const WbsTaskCreateScreen({
    super.key,
    required this.repository,
  });

  final WbsTaskRepository repository;

  @override
  State<WbsTaskCreateScreen> createState() =>
      _WbsTaskCreateScreenState();
}

class _WbsTaskCreateScreenState
    extends State<WbsTaskCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _projectId = TextEditingController();
  final _milestoneId = TextEditingController();
  final _taskCode = TextEditingController();
  final _name = TextEditingController();
  final _description = TextEditingController();

  final _estimatedHours = TextEditingController(text: '8');

  DateTime _start = DateTime.now();
  DateTime _finish = DateTime.now().add(
    const Duration(days: 1),
  );

  bool _saving = false;

  @override
  void dispose() {
    _projectId.dispose();
    _milestoneId.dispose();
    _taskCode.dispose();
    _name.dispose();
    _description.dispose();
    _estimatedHours.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await widget.repository.create(
        projectId: _projectId.text.trim(),
        projectMilestoneId: _milestoneId.text.trim(),
        assignedEmployeeId: null,
        taskCode: _taskCode.text.trim(),
        name: _name.text.trim(),
        description: _description.text.trim(),
        plannedStartDate: _start,
        plannedFinishDate: _finish,
        actualStartDate: null,
        actualFinishDate: null,
        status: WbsTaskStatus.notStarted,
        priority: TaskPriority.medium,
        progressPercentage: 0,
        estimatedHours:
        double.parse(_estimatedHours.text),
        actualHours: 0,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() => _start = picked);
    }
  }

  Future<void> _pickFinish() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _finish,
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() => _finish = picked);
    }
  }

  String _date(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create WBS Task'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _projectId,
              decoration: const InputDecoration(
                labelText: 'Project ID',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _milestoneId,
              decoration: const InputDecoration(
                labelText: 'Milestone ID',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _taskCode,
              decoration: const InputDecoration(
                labelText: 'Task Code',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Task Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Start Date'),
              subtitle: Text(_date(_start)),
              trailing:
              const Icon(Icons.calendar_today),
              onTap: _pickStart,
            ),
            ListTile(
              title: const Text('Finish Date'),
              subtitle: Text(_date(_finish)),
              trailing:
              const Icon(Icons.calendar_today),
              onTap: _pickFinish,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _estimatedHours,
              keyboardType:
              TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Estimated Hours',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(
                _saving
                    ? 'Saving...'
                    : 'Create Task',
              ),
            ),
          ],
        ),
      ),
    );
  }
}