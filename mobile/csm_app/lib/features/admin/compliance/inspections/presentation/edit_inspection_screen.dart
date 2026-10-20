import 'package:flutter/material.dart';

import '../data/inspection.dart';
import '../data/inspection_repository.dart';
import '../data/update_inspection_request.dart';

class EditInspectionScreen extends StatefulWidget {
  const EditInspectionScreen({
    super.key,
    required this.repository,
    required this.inspection,
  });

  final InspectionRepository repository;
  final Inspection inspection;

  @override
  State<EditInspectionScreen> createState() =>
      _EditInspectionScreenState();
}

class _EditInspectionScreenState
    extends State<EditInspectionScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _numberController;
  late final TextEditingController _titleController;
  late final TextEditingController _summaryController;

  late String _inspectionType;
  late String _status;

  late List<UpdateInspectionChecklistItemRequest> _checklist;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final inspection = widget.inspection;

    _numberController = TextEditingController(
      text: inspection.inspectionNumber,
    );

    _titleController = TextEditingController(
      text: inspection.title,
    );

    _summaryController = TextEditingController(
      text: inspection.summary ?? '',
    );

    _inspectionType = inspection.inspectionType;
    _status = inspection.status;

    _checklist = inspection.checklistItems
        .map(
          (item) => UpdateInspectionChecklistItemRequest(
        sequence: item.sequence,
        requirement: item.requirement,
        isCompliant: item.isCompliant,
        observation: item.observation,
        correctiveAction: item.correctiveAction,
        dueDate: item.dueDate,
        isResolved: item.isResolved,
      ),
    )
        .toList();
  }

  @override
  void dispose() {
    _numberController.dispose();
    _titleController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  void _recalculateStatus() {
    if (_checklist.isEmpty) {
      return;
    }

    final hasPending = _checklist.any(
          (item) => item.isCompliant == null,
    );

    final hasFailed = _checklist.any(
          (item) => item.isCompliant == false,
    );

    if (hasPending) {
      _status = 'In Progress';
    } else if (hasFailed) {
      final hasCorrectiveAction = _checklist.any(
            (item) =>
        item.isCompliant == false &&
            item.correctiveAction != null &&
            item.correctiveAction!.trim().isNotEmpty,
      );

      _status = hasCorrectiveAction
          ? 'Corrective Action Required'
          : 'Failed';
    } else {
      _status = 'Passed';
    }
  }

  int _statusValue(String status) {
    switch (status) {
      case 'In Progress':
        return 2;
      case 'Passed':
        return 3;
      case 'Passed With Observations':
        return 4;
      case 'Failed':
        return 5;
      case 'Corrective Action Required':
        return 6;
      case 'Closed':
        return 7;
      case 'Cancelled':
        return 8;
      default:
        return 1;
    }
  }

  Color _statusColor() {
    switch (_status) {
      case 'Passed':
        return Colors.green;
      case 'Failed':
        return Colors.red;
      case 'In Progress':
        return Colors.orange;
      case 'Corrective Action Required':
        return Colors.deepOrange;
      case 'Closed':
        return Colors.blueGrey;
      case 'Cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Future<void> _addChecklistItem() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('New Checklist Item'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Requirement',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();

                if (value.isEmpty) {
                  return;
                }

                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (!mounted || result == null || result.isEmpty) {
      return;
    }

    setState(() {
      _checklist.add(
        UpdateInspectionChecklistItemRequest(
          sequence: _checklist.length + 1,
          requirement: result,
        ),
      );

      _recalculateStatus();
    });
  }

  Future<void> _editChecklistItem(int index) async {
    final item = _checklist[index];

    final result =
    await showDialog<UpdateInspectionChecklistItemRequest>(
      context: context,
      builder: (dialogContext) {
        return _ChecklistItemEditDialog(
          item: item,
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _checklist[index] = result;
      _recalculateStatus();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      DateTime? startedAtUtc =
          widget.inspection.startedAtUtc;

      DateTime? completedAtUtc =
          widget.inspection.completedAtUtc;

      final statusValue = _statusValue(_status);

      if (statusValue == 2 &&
          startedAtUtc == null) {
        startedAtUtc = DateTime.now().toUtc();
      }

      if ((statusValue == 3 ||
          statusValue == 4 ||
          statusValue == 5 ||
          statusValue == 7) &&
          completedAtUtc == null) {
        completedAtUtc = DateTime.now().toUtc();
      }

      final hasCorrectiveAction = _checklist.any(
            (item) =>
        item.isCompliant == false &&
            item.correctiveAction != null &&
            item.correctiveAction!.trim().isNotEmpty,
      );





      final request = UpdateInspectionRequest(
        constructionSiteId:
        widget.inspection.constructionSiteId,
        projectId:
        widget.inspection.projectId,
        inspectionNumber:
        _numberController.text.trim(),
        inspectionType:
        _inspectionType,
        title:
        _titleController.text.trim(),
        scheduledAtUtc:
        widget.inspection.scheduledAtUtc,
        startedAtUtc:
        startedAtUtc,
        completedAtUtc:
        completedAtUtc,
        inspectorEmployeeId:
        widget.inspection.inspectorEmployeeId,
        externalInspectorName:
        widget.inspection.externalInspectorName,
        externalOrganization:
        widget.inspection.externalOrganization,
        status:
        statusValue,
        summary:
        _summaryController.text.trim().isEmpty
            ? null
            : _summaryController.text.trim(),
        correctiveActionRequired:
        hasCorrectiveAction
            ? 'Corrective action required.'
            : widget.inspection.correctiveActionRequired,
        correctiveActionDueDate:
        (_status == 'Corrective Action Required' ||
            _status == 'Passed With Observations' ||
            _status == 'Failed')
            ? widget.inspection.correctiveActionDueDate
            : null,
        signedOffBy:
        widget.inspection.signedOffBy,
        signedOffAtUtc:
        widget.inspection.signedOffAtUtc,
        checklistItems:
        _checklist,
      );

      await widget.repository.update(
        widget.inspection.id,
        request,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Inspection'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _numberController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Inspection Number',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Inspection Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Required';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _inspectionType,
              decoration: const InputDecoration(
                labelText: 'Inspection Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Safety',
                  child: Text('Safety'),
                ),
                DropdownMenuItem(
                  value: 'Quality',
                  child: Text('Quality'),
                ),
                DropdownMenuItem(
                  value: 'Environmental',
                  child: Text('Environmental'),
                ),
                DropdownMenuItem(
                  value: 'Equipment',
                  child: Text('Equipment'),
                ),
                DropdownMenuItem(
                  value: 'Compliance',
                  child: Text('Compliance'),
                ),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _inspectionType = value;
                });
              },
            ),

            const SizedBox(height: 16),

            Card(
              color: _statusColor().withValues(
                alpha: 0.08,
              ),
              child: ListTile(
                leading: Icon(
                  Icons.fact_check,
                  color: _statusColor(),
                ),
                title: const Text(
                  'Inspection Status',
                ),
                subtitle: Text(_status),
              ),
            ),

            const SizedBox(height: 8),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.calendar_today,
              ),
              title: const Text('Scheduled'),
              subtitle: Text(
                _formatDate(
                  widget.inspection.scheduledAtUtc,
                ),
              ),
            ),

            const Divider(),

            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Checklist',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  tooltip: 'Add checklist item',
                  onPressed: _addChecklistItem,
                  icon: const Icon(
                    Icons.add_circle,
                  ),
                ),
              ],
            ),

            if (_checklist.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 8,
                ),
                child: Text(
                  'No checklist items',
                ),
              ),

            ..._checklist.asMap().entries.map(
                  (entry) {
                final index = entry.key;
                final item = entry.value;

                IconData icon =
                    Icons.radio_button_unchecked;

                Color color = Colors.grey;

                if (item.isCompliant == true) {
                  icon = Icons.check_circle;
                  color = Colors.green;
                } else if (item.isCompliant == false) {
                  icon = Icons.cancel;
                  color = Colors.red;
                }

                return Card(
                  child: ListTile(
                    leading: Icon(
                      icon,
                      color: color,
                    ),
                    title: Text(
                      item.requirement,
                    ),
                    subtitle: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.isCompliant == null
                              ? 'Pending'
                              : item.isCompliant!
                              ? 'Compliant'
                              : 'Non-Compliant',
                        ),

                        if (item.observation != null &&
                            item.observation!
                                .trim()
                                .isNotEmpty)
                          Text(
                            'Observation: ${item.observation}',
                          ),

                        if (item.correctiveAction !=
                            null &&
                            item.correctiveAction!
                                .trim()
                                .isNotEmpty)
                          Text(
                            'Corrective Action: '
                                '${item.correctiveAction}',
                          ),

                        if (item.dueDate != null)
                          Text(
                            'Due: '
                                '${_formatDate(item.dueDate!)}',
                          ),

                        if (item.isResolved)
                          const Text(
                            'Corrective Action: Resolved',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight:
                              FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    trailing: const Icon(
                      Icons.edit,
                    ),
                    onTap: () {
                      _editChecklistItem(index);
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _summaryController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Summary',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed:
              _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(
                _saving
                    ? 'Updating...'
                    : 'Update Inspection',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistItemEditDialog
    extends StatefulWidget {
  const _ChecklistItemEditDialog({
    required this.item,
  });

  final UpdateInspectionChecklistItemRequest item;

  @override
  State<_ChecklistItemEditDialog> createState() =>
      _ChecklistItemEditDialogState();
}

class _ChecklistItemEditDialogState
    extends State<_ChecklistItemEditDialog> {
  late final TextEditingController
  _observationController;

  late final TextEditingController
  _correctiveController;

  bool? _compliant;
  bool _isResolved = false;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();

    final item = widget.item;

    _observationController =
        TextEditingController(
          text: item.observation ?? '',
        );

    _correctiveController =
        TextEditingController(
          text: item.correctiveAction ?? '',
        );

    _compliant = item.isCompliant;
    _isResolved = item.isResolved;
    _dueDate = item.dueDate;

    if (_compliant != true) {
      _isResolved = false;
    }
  }

  @override
  void dispose() {
    _observationController.dispose();
    _correctiveController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
      _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (!mounted || picked == null) {
      return;
    }

    setState(() {
      _dueDate = picked;
    });
  }

  void _save() {
    if (_compliant == false &&
        _correctiveController.text
            .trim()
            .isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Corrective action is required for a non-compliant item.',
          ),
        ),
      );
      return;
    }

    if (_isResolved &&
        _compliant != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A resolved checklist item must be compliant.',
          ),
        ),
      );
      return;
    }

    if (_isResolved &&
        _dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Due date is required before resolving the corrective action.',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      UpdateInspectionChecklistItemRequest(
        sequence:
        widget.item.sequence,
        requirement:
        widget.item.requirement,
        isCompliant:
        _compliant,
        observation:
        _observationController.text
            .trim()
            .isEmpty
            ? null
            : _observationController.text
            .trim(),
        correctiveAction:
        _correctiveController.text
            .trim()
            .isEmpty
            ? null
            : _correctiveController.text
            .trim(),
        dueDate: _dueDate,
        isResolved:
        _isResolved,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.item.requirement,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<bool?>(
              initialValue: _compliant,
              decoration:
              const InputDecoration(
                labelText: 'Result',
                border:
                OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem<bool?>(
                  value: null,
                  child: Text('Pending'),
                ),
                DropdownMenuItem<bool?>(
                  value: true,
                  child: Text('Compliant'),
                ),
                DropdownMenuItem<bool?>(
                  value: false,
                  child: Text('Non-Compliant'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _compliant = value;

                  if (value != true) {
                    _isResolved = false;
                  }
                });
              },
            ),

            const SizedBox(height: 16),

            TextField(
              controller:
              _observationController,
              maxLines: 3,
              decoration:
              const InputDecoration(
                labelText: 'Observation',
                border:
                OutlineInputBorder(),
                alignLabelWithHint:
                true,
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller:
              _correctiveController,
              maxLines: 3,
              decoration:
              const InputDecoration(
                labelText:
                'Corrective Action',
                border:
                OutlineInputBorder(),
                alignLabelWithHint:
                true,
              ),
            ),

            if (_correctiveController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 16),

              ListTile(
                contentPadding:
                EdgeInsets.zero,
                leading:
                const Icon(Icons.event),
                title: const Text(
                  'Corrective Action Due Date',
                ),
                subtitle: Text(
                  _dueDate == null
                      ? 'Not set'
                      : _formatDate(
                    _dueDate!,
                  ),
                ),
                trailing: const Icon(
                  Icons.calendar_today,
                ),
                onTap: _pickDueDate,
              ),
            ],

            if (_compliant == true &&
                _correctiveController.text
                    .trim()
                    .isNotEmpty) ...[
              const SizedBox(height: 8),

              CheckboxListTile(
                contentPadding:
                EdgeInsets.zero,
                title: const Text(
                  'Corrective Action Resolved',
                ),
                value: _isResolved,
                onChanged: (value) {
                  setState(() {
                    _isResolved =
                        value ?? false;
                  });
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}