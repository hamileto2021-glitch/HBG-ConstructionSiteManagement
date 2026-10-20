import 'package:flutter/material.dart';

import '../data/safety_incident.dart';
import '../data/safety_incident_repository.dart';
import '../data/update_safety_incident_request.dart';

class EditSafetyIncidentScreen extends StatefulWidget {
  const EditSafetyIncidentScreen({
    super.key,
    required this.incident,
    required this.repository,
  });

  final SafetyIncident incident;
  final SafetyIncidentRepository repository;

  @override
  State<EditSafetyIncidentScreen> createState() =>
      _EditSafetyIncidentScreenState();
}

class _EditSafetyIncidentScreenState
    extends State<EditSafetyIncidentScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _incidentNumberController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _immediateActionController;
  late final TextEditingController _rootCauseController;
  late final TextEditingController _correctiveActionController;

  late DateTime _occurredAtUtc;
  late DateTime _reportedAtUtc;

  late String _severity;
  late String _status;

  late bool _injuryOccurred;
  late bool _medicalTreatmentRequired;
  late bool _lostTimeIncident;

  DateTime? _investigationCompletedAtUtc;
  DateTime? _closedAtUtc;

  bool _saving = false;

  static const List<String> _severityValues = [
    'NearMiss',
    'Minor',
    'Moderate',
    'Serious',
    'Critical',
    'Fatal',
  ];

  static const List<String> _statusValues = [
    'Reported',
    'UnderInvestigation',
    'CorrectiveActionRequired',
    'Resolved',
    'Closed',
  ];

  @override
  void initState() {
    super.initState();

    final incident = widget.incident;

    _incidentNumberController =
        TextEditingController(
          text: incident.incidentNumber,
        );

    _locationController =
        TextEditingController(
          text: incident.locationDescription,
        );

    _descriptionController =
        TextEditingController(
          text: incident.description,
        );

    _immediateActionController =
        TextEditingController(
          text: incident.immediateActionTaken ?? '',
        );

    _rootCauseController =
        TextEditingController(
          text: incident.rootCause ?? '',
        );

    _correctiveActionController =
        TextEditingController(
          text: incident.correctiveAction ?? '',
        );

    _occurredAtUtc =
        incident.occurredAtUtc;

    _reportedAtUtc =
        incident.reportedAtUtc;

    _severity = _severityValues.contains(
      incident.severity,
    )
        ? incident.severity
        : 'Minor';

    _status = _statusValues.contains(
      incident.status,
    )
        ? incident.status
        : 'Reported';

    _injuryOccurred =
        incident.injuryOccurred;

    _medicalTreatmentRequired =
        incident.medicalTreatmentRequired;

    _lostTimeIncident =
        incident.lostTimeIncident;

    _investigationCompletedAtUtc =
        incident.investigationCompletedAtUtc;

    _closedAtUtc =
        incident.closedAtUtc;
  }

  @override
  void dispose() {
    _incidentNumberController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _immediateActionController.dispose();
    _rootCauseController.dispose();
    _correctiveActionController.dispose();

    super.dispose();
  }

  String _displayStatus(String value) {
    switch (value) {
      case 'UnderInvestigation':
        return 'Under Investigation';

      case 'CorrectiveActionRequired':
        return 'Corrective Action Required';

      case 'NearMiss':
        return 'Near Miss';

      default:
        return value;
    }
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'Not set';
    }

    final local = value.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  Future<DateTime?> _pickDate(
      DateTime? current,
      ) async {
    final initialDate =
        current?.toLocal() ??
            DateTime.now();

    final selected =
    await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selected == null) {
      return current;
    }

    return DateTime.utc(
      selected.year,
      selected.month,
      selected.day,
      initialDate.hour,
      initialDate.minute,
      initialDate.second,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_medicalTreatmentRequired &&
        !_injuryOccurred) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Medical treatment requires an injury to have occurred.',
          ),
        ),
      );
      return;
    }

    if (_lostTimeIncident &&
        !_injuryOccurred) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A lost-time incident requires an injury to have occurred.',
          ),
        ),
      );
      return;
    }

    if (_status == 'Closed' &&
        _closedAtUtc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A closed safety incident must have a closure date.',
          ),
        ),
      );
      return;
    }

    if (_investigationCompletedAtUtc !=
        null &&
        _investigationCompletedAtUtc!
            .isBefore(_occurredAtUtc)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Investigation completion cannot be earlier than incident occurrence.',
          ),
        ),
      );
      return;
    }

    if (_closedAtUtc != null &&
        _closedAtUtc!
            .isBefore(_occurredAtUtc)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Closure cannot be earlier than incident occurrence.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final request =
      UpdateSafetyIncidentRequest(
        constructionSiteId:
        widget.incident
            .constructionSiteId,

        projectId:
        widget.incident.projectId,

        employeeId:
        widget.incident.employeeId,

        incidentNumber:
        _incidentNumberController
            .text
            .trim(),

        occurredAtUtc:
        _occurredAtUtc,

        reportedAtUtc:
        _reportedAtUtc,

        locationDescription:
        _locationController
            .text
            .trim(),

        description:
        _descriptionController
            .text
            .trim(),

        severity:
        _severity,

        status:
        _status,

        injuryOccurred:
        _injuryOccurred,

        medicalTreatmentRequired:
        _medicalTreatmentRequired,

        lostTimeIncident:
        _lostTimeIncident,

        immediateActionTaken:
        _clean(
          _immediateActionController
              .text,
        ),

        rootCause:
        _clean(
          _rootCauseController.text,
        ),

        correctiveAction:
        _clean(
          _correctiveActionController
              .text,
        ),

        investigatedBy:
        widget.incident.investigatedBy,

        investigationCompletedAtUtc:
        _investigationCompletedAtUtc,

        closedAtUtc:
        _closedAtUtc,
      );

      await widget.repository.update(
        widget.incident.id,
        request,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
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

  String? _clean(String value) {
    final result = value.trim();

    return result.isEmpty ? null : result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Safety Incident',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller:
              _incidentNumberController,
              decoration:
              const InputDecoration(
                labelText: 'Incident Number',
                border:
                OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Incident number is required';
                }

                if (value.trim().length > 50) {
                  return 'Maximum 50 characters';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            _DateField(
              label: 'Occurred Date',
              value: _formatDate(
                _occurredAtUtc,
              ),
              onTap: () async {
                final selected =
                await _pickDate(
                  _occurredAtUtc,
                );

                if (selected == null) {
                  return;
                }

                setState(() {
                  _occurredAtUtc =
                      selected;
                });
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller:
              _locationController,
              decoration:
              const InputDecoration(
                labelText:
                'Location Description',
                border:
                OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Location is required';
                }

                if (value.trim().length > 500) {
                  return 'Maximum 500 characters';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _severity,
              decoration:
              const InputDecoration(
                labelText: 'Severity',
                border:
                OutlineInputBorder(),
              ),
              items: _severityValues
                  .map(
                    (value) =>
                    DropdownMenuItem(
                      value: value,
                      child: Text(
                        _displayStatus(
                          value,
                        ),
                      ),
                    ),
              )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _severity = value;
                });
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration:
              const InputDecoration(
                labelText: 'Status',
                border:
                OutlineInputBorder(),
              ),
              items: _statusValues
                  .map(
                    (value) =>
                    DropdownMenuItem(
                      value: value,
                      child: Text(
                        _displayStatus(
                          value,
                        ),
                      ),
                    ),
              )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _status = value;
                });
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller:
              _descriptionController,
              maxLines: 5,
              decoration:
              const InputDecoration(
                labelText:
                'Incident Description',
                alignLabelWithHint: true,
                border:
                OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Description is required';
                }

                if (value.trim().length > 4000) {
                  return 'Maximum 4000 characters';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            SwitchListTile(
              contentPadding:
              EdgeInsets.zero,
              title: const Text(
                'Injury Occurred',
              ),
              value: _injuryOccurred,
              onChanged: (value) {
                setState(() {
                  _injuryOccurred =
                      value;

                  if (!value) {
                    _medicalTreatmentRequired =
                    false;
                    _lostTimeIncident =
                    false;
                  }
                });
              },
            ),

            SwitchListTile(
              contentPadding:
              EdgeInsets.zero,
              title: const Text(
                'Medical Treatment Required',
              ),
              value:
              _medicalTreatmentRequired,
              onChanged: !_injuryOccurred
                  ? null
                  : (value) {
                setState(() {
                  _medicalTreatmentRequired =
                      value;
                });
              },
            ),

            SwitchListTile(
              contentPadding:
              EdgeInsets.zero,
              title: const Text(
                'Lost Time Incident',
              ),
              value: _lostTimeIncident,
              onChanged: !_injuryOccurred
                  ? null
                  : (value) {
                setState(() {
                  _lostTimeIncident =
                      value;
                });
              },
            ),

            const SizedBox(height: 8),

            TextFormField(
              controller:
              _immediateActionController,
              maxLines: 3,
              decoration:
              const InputDecoration(
                labelText:
                'Immediate Action Taken',
                border:
                OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller:
              _rootCauseController,
              maxLines: 3,
              decoration:
              const InputDecoration(
                labelText: 'Root Cause',
                border:
                OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller:
              _correctiveActionController,
              maxLines: 3,
              decoration:
              const InputDecoration(
                labelText:
                'Corrective Action',
                border:
                OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            _DateField(
              label:
              'Investigation Completed',
              value: _formatDate(
                _investigationCompletedAtUtc,
              ),
              onTap: () async {
                final selected =
                await _pickDate(
                  _investigationCompletedAtUtc,
                );

                setState(() {
                  _investigationCompletedAtUtc =
                      selected;
                });
              },
              onClear: _investigationCompletedAtUtc ==
                  null
                  ? null
                  : () {
                setState(() {
                  _investigationCompletedAtUtc =
                  null;
                });
              },
            ),

            const SizedBox(height: 16),

            _DateField(
              label: 'Closed Date',
              value: _formatDate(
                _closedAtUtc,
              ),
              onTap: () async {
                final selected =
                await _pickDate(
                  _closedAtUtc,
                );

                setState(() {
                  _closedAtUtc =
                      selected;
                });
              },
              onClear: _closedAtUtc == null
                  ? null
                  : () {
                setState(() {
                  _closedAtUtc =
                  null;
                });
              },
            ),

            const SizedBox(height: 28),

            FilledButton.icon(
              onPressed:
              _saving ? null : _save,
              icon: const Icon(
                Icons.save,
              ),
              label: Text(
                _saving
                    ? 'Saving...'
                    : 'Save Changes',
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius:
      BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border:
          const OutlineInputBorder(),
          suffixIcon: onClear == null
              ? const Icon(
            Icons.calendar_today,
          )
              : IconButton(
            onPressed: onClear,
            icon: const Icon(
              Icons.clear,
            ),
          ),
        ),
        child: Text(value),
      ),
    );
  }
}