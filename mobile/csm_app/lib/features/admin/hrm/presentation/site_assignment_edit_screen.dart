import 'package:flutter/material.dart';

import '../data/models/site_assignment/site_assignment.dart';
import '../data/repositories/site_assignment_repository.dart';

class SiteAssignmentEditScreen extends StatefulWidget {
  const SiteAssignmentEditScreen({
    super.key,
    required this.assignment,
    required this.repository,
  });

  final SiteAssignment assignment;
  final SiteAssignmentRepository repository;

  @override
  State<SiteAssignmentEditScreen> createState() =>
      _SiteAssignmentEditScreenState();
}

class _SiteAssignmentEditScreenState
    extends State<SiteAssignmentEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _startDate;
  DateTime? _endDate;

  late final TextEditingController _roleController;
  late final TextEditingController _remarksController;

  late bool _isPrimaryAssignment;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _startDate = widget.assignment.startDate;
    _endDate = widget.assignment.endDate;

    _roleController = TextEditingController(
      text: widget.assignment.roleAtSite ?? '',
    );

    _remarksController = TextEditingController(
      text: widget.assignment.remarks ?? '',
    );

    _isPrimaryAssignment =
        widget.assignment.isPrimaryAssignment;
  }

  @override
  void dispose() {
    _roleController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _startDate = selected;

      if (_endDate != null &&
          _endDate!.isBefore(selected)) {
        _endDate = null;
      }
    });
  }

  Future<void> _selectEndDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _endDate = selected;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_endDate != null &&
        _endDate!.isBefore(_startDate)) {
      _showMessage(
        'End date cannot be earlier than start date.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedAssignment =
          await widget.repository.update(
        assignmentId: widget.assignment.id,
        startDate: _startDate,
        endDate: _endDate,
        roleAtSite:
            _roleController.text.trim().isEmpty
                ? null
                : _roleController.text.trim(),
        isPrimaryAssignment: _isPrimaryAssignment,
        remarks:
            _remarksController.text.trim().isEmpty
                ? null
                : _remarksController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Site assignment updated successfully.',
          ),
        ),
      );

      Navigator.of(context).pop(
        updatedAssignment,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      _showMessage(
        'Update failed: $error',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();

    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Site Assignment'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assignment',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _ReadOnlyField(
                      label: 'Employee',
                      value:
                          '${widget.assignment.employeeNumber} - '
                          '${widget.assignment.employeeName}',
                    ),
                    const SizedBox(height: 16),
                    _ReadOnlyField(
                      label: 'Construction site',
                      value: widget.assignment.siteName,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _roleController,
                      enabled: !_isSaving,
                      decoration: const InputDecoration(
                        labelText: 'Role at site',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _isSaving
                          ? null
                          : _selectStartDate,
                      icon: const Icon(
                        Icons.calendar_today,
                      ),
                      label: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Start date: '
                          '${_formatDate(_startDate)}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isSaving
                          ? null
                          : _selectEndDate,
                      icon: const Icon(
                        Icons.event_available,
                      ),
                      label: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'End date: '
                          '${_endDate == null ? 'None' : _formatDate(_endDate!)}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Primary assignment',
                      ),
                      subtitle: const Text(
                        'Employee can have only one overlapping '
                        'primary site assignment.',
                      ),
                      value: _isPrimaryAssignment,
                      onChanged: _isSaving
                          ? null
                          : (value) {
                              setState(() {
                                _isPrimaryAssignment =
                                    value;
                              });
                            },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _remarksController,
                      enabled: !_isSaving,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Remarks',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _save,
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
                  _isSaving
                      ? 'Saving...'
                      : 'Save Changes',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: Text(
        value,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
