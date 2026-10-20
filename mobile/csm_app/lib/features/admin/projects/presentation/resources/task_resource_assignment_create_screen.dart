import 'package:flutter/material.dart';

import '../../data/models/task_resource_assignment.dart';
import '../../data/repositories/task_resource_assignment_repository.dart';

class TaskResourceAssignmentCreateScreen extends StatefulWidget {
  const TaskResourceAssignmentCreateScreen({
    super.key,
    required this.wbsTaskId,
    required this.repository,
  });

  final String wbsTaskId;
  final TaskResourceAssignmentRepository repository;

  @override
  State<TaskResourceAssignmentCreateScreen> createState() =>
      _TaskResourceAssignmentCreateScreenState();
}

class _TaskResourceAssignmentCreateScreenState
    extends State<TaskResourceAssignmentCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _employeeIdController = TextEditingController();
  final _employeeNameController = TextEditingController();
  final _roleController = TextEditingController();
  final _plannedHoursController = TextEditingController(text: '8');
  final _remarksController = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _employeeIdController.dispose();
    _employeeNameController.dispose();
    _roleController.dispose();
    _plannedHoursController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final assignment = TaskResourceAssignment(
        id: '',
        wbsTaskId: widget.wbsTaskId,
        employeeId: _employeeIdController.text.trim(),
        employeeName: _employeeNameController.text.trim(),
        role: _roleController.text.trim(),
        plannedHours:
        double.tryParse(_plannedHoursController.text) ?? 0,
        actualHours: 0,
        assignedDate: DateTime.now(),
        remarks: _remarksController.text.trim().isEmpty
            ? null
            : _remarksController.text.trim(),
      );

      await widget.repository.create(assignment);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );

      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Employee'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _employeeIdController,
              decoration: const InputDecoration(
                labelText: 'Employee ID',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _employeeNameController,
              decoration: const InputDecoration(
                labelText: 'Employee Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _roleController,
              decoration: const InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _plannedHoursController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Planned Hours',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _remarksController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Remarks',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(
                _saving ? 'Saving...' : 'Create Assignment',
              ),
            ),
          ],
        ),
      ),
    );
  }
}