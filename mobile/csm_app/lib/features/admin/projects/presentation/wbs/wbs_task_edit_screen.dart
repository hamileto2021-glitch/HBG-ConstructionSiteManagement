import 'package:flutter/material.dart';

import '../../data/models/wbs_task.dart';
import '../../data/repositories/wbs_task_repository.dart';

class WbsTaskEditScreen extends StatefulWidget {
  const WbsTaskEditScreen({
    super.key,
    required this.task,
    required this.repository,
  });

  final WbsTask task;
  final WbsTaskRepository repository;

  @override
  State<WbsTaskEditScreen> createState() =>
      _WbsTaskEditScreenState();
}

class _WbsTaskEditScreenState
    extends State<WbsTaskEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _estimatedHours;
  late final TextEditingController _actualHours;
  late final TextEditingController _progress;

  late DateTime _start;
  late DateTime _finish;
  late WbsTaskStatus _status;
  late TaskPriority _priority;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _name = TextEditingController(text: widget.task.name);
    _description = TextEditingController(
      text: widget.task.description ?? '',
    );
    _estimatedHours = TextEditingController(
      text: widget.task.estimatedHours.toString(),
    );
    _actualHours = TextEditingController(
      text: widget.task.actualHours.toString(),
    );
    _progress = TextEditingController(
      text: widget.task.progressPercentage.toStringAsFixed(0),
    );

    _start = widget.task.plannedStartDate;
    _finish = widget.task.plannedFinishDate;
    _status = widget.task.status;
    _priority = widget.task.priority;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _estimatedHours.dispose();
    _actualHours.dispose();
    _progress.dispose();
    super.dispose();
  }

  String _date(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';

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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final updated = await widget.repository.update(
        taskId: widget.task.id,
        projectId: widget.task.projectId,
        projectMilestoneId: widget.task.projectMilestoneId,
        assignedEmployeeId: widget.task.assignedEmployeeId,
        taskCode: widget.task.taskCode,
        name: _name.text.trim(),
        description: _description.text.trim(),
        plannedStartDate: _start,
        plannedFinishDate: _finish,
        actualStartDate: widget.task.actualStartDate,
        actualFinishDate: widget.task.actualFinishDate,
        status: _status,
        priority: _priority,
        progressPercentage:
        double.parse(_progress.text),
        estimatedHours:
        double.parse(_estimatedHours.text),
        actualHours:
        double.parse(_actualHours.text),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit WBS Task'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Task Name',
                border: OutlineInputBorder(),
              ),
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
            DropdownButtonFormField<WbsTaskStatus>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: WbsTaskStatus.values
                  .map(
                    (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e.name),
                ),
              )
                  .toList(),
              onChanged: (v) =>
                  setState(() => _status = v!),
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
                    (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e.name),
                ),
              )
                  .toList(),
              onChanged: (v) =>
                  setState(() => _priority = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _progress,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Progress %',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _estimatedHours,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Estimated Hours',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _actualHours,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Actual Hours',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Planned Start'),
              subtitle: Text(_date(_start)),
              trailing:
              const Icon(Icons.calendar_today),
              onTap: _pickStart,
            ),
            ListTile(
              title: const Text('Planned Finish'),
              subtitle: Text(_date(_finish)),
              trailing:
              const Icon(Icons.calendar_today),
              onTap: _pickFinish,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(
                _saving
                    ? 'Saving...'
                    : 'Save Changes',
              ),
            ),
          ],
        ),
      ),
    );
  }
}