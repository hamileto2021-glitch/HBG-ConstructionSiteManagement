import 'package:flutter/material.dart';

import '../data/models/equipment_maintenance.dart';
import '../data/repositories/equipment_maintenance_repository.dart';

class EquipmentMaintenanceDetailScreen extends StatefulWidget {
  EquipmentMaintenanceDetailScreen({
    super.key,
    required this.maintenance,
    EquipmentMaintenanceRepository? repository,
  }) : repository =
            repository ?? EquipmentMaintenanceRepository();

  final EquipmentMaintenance maintenance;
  final EquipmentMaintenanceRepository repository;

  @override
  State<EquipmentMaintenanceDetailScreen> createState() =>
      _EquipmentMaintenanceDetailScreenState();
}

class _EquipmentMaintenanceDetailScreenState
    extends State<EquipmentMaintenanceDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _maintenanceType;
  late DateTime _scheduledAt;

  DateTime? _startedAt;
  DateTime? _completedAt;
  DateTime? _nextMaintenanceAt;

  late final TextEditingController _meterController;
  late final TextEditingController _costController;
  late final TextEditingController _currencyController;
  late final TextEditingController _providerController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _partsController;
  late final TextEditingController _nextMeterController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final maintenance = widget.maintenance;

    _maintenanceType = maintenance.maintenanceType;
    _scheduledAt = maintenance.scheduledAtUtc;
    _startedAt = maintenance.startedAtUtc;
    _completedAt = maintenance.completedAtUtc;
    _nextMaintenanceAt = maintenance.nextMaintenanceAtUtc;

    _meterController = TextEditingController(
      text: maintenance.meterReading?.toString() ?? '',
    );

    _costController = TextEditingController(
      text: maintenance.cost?.toString() ?? '',
    );

    _currencyController = TextEditingController(
      text: maintenance.currencyCode,
    );

    _providerController = TextEditingController(
      text: maintenance.serviceProvider ?? '',
    );

    _descriptionController = TextEditingController(
      text: maintenance.description ?? '',
    );

    _partsController = TextEditingController(
      text: maintenance.partsReplaced ?? '',
    );

    _nextMeterController = TextEditingController(
      text:
          maintenance.nextMaintenanceMeterReading?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _meterController.dispose();
    _costController.dispose();
    _currencyController.dispose();
    _providerController.dispose();
    _descriptionController.dispose();
    _partsController.dispose();
    _nextMeterController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();

    String two(int value) =>
        value.toString().padLeft(2, '0');

    return '${local.year}-${two(local.month)}-'
        '${two(local.day)} ${two(local.hour)}:'
        '${two(local.minute)}';
  }

  double? _parseNumber(
    TextEditingController controller,
  ) {
    final value = controller.text.trim();

    if (value.isEmpty) {
      return null;
    }

    return double.tryParse(value);
  }

  Future<DateTime?> _pickDateTime({
    required DateTime initialDate,
  }) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate.toLocal(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (!mounted || date == null) {
      return null;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        initialDate.toLocal(),
      ),
    );

    if (!mounted || time == null) {
      return null;
    }

    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  Future<void> _pickScheduledAt() async {
    final value = await _pickDateTime(
      initialDate: _scheduledAt,
    );

    if (!mounted || value == null) {
      return;
    }

    setState(() {
      _scheduledAt = value;
    });
  }

  Future<void> _pickStartedAt() async {
    final value = await _pickDateTime(
      initialDate: _startedAt ?? _scheduledAt,
    );

    if (!mounted || value == null) {
      return;
    }

    setState(() {
      _startedAt = value;
    });
  }

  Future<void> _pickCompletedAt() async {
    final value = await _pickDateTime(
      initialDate:
          _completedAt ?? _startedAt ?? _scheduledAt,
    );

    if (!mounted || value == null) {
      return;
    }

    setState(() {
      _completedAt = value;
    });
  }

  Future<void> _pickNextMaintenanceAt() async {
    final value = await _pickDateTime(
      initialDate:
          _nextMaintenanceAt ?? _scheduledAt,
    );

    if (!mounted || value == null) {
      return;
    }

    setState(() {
      _nextMaintenanceAt = value;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final meterReading =
        _parseNumber(_meterController);
    final cost = _parseNumber(_costController);
    final nextMeterReading =
        _parseNumber(_nextMeterController);

    if (_meterController.text.trim().isNotEmpty &&
        meterReading == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a valid meter reading.',
          ),
        ),
      );
      return;
    }

    if (_costController.text.trim().isNotEmpty &&
        cost == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid cost.'),
        ),
      );
      return;
    }

    if (_nextMeterController.text.trim().isNotEmpty &&
        nextMeterReading == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a valid next maintenance meter reading.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.repository.update(
        maintenanceId: widget.maintenance.id,
        maintenanceType: _maintenanceType,
        scheduledAtUtc: _scheduledAt.toUtc(),
        startedAtUtc: _startedAt?.toUtc(),
        completedAtUtc: _completedAt?.toUtc(),
        meterReading: meterReading,
        cost: cost,
        currencyCode:
            _currencyController.text.trim(),
        serviceProvider:
            _providerController.text.trim().isEmpty
                ? null
                : _providerController.text.trim(),
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
        partsReplaced:
            _partsController.text.trim().isEmpty
                ? null
                : _partsController.text.trim(),
        nextMaintenanceAtUtc:
            _nextMaintenanceAt?.toUtc(),
        nextMaintenanceMeterReading:
            nextMeterReading,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Equipment maintenance updated successfully.',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

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
    final maintenance = widget.maintenance;
    final isCompleted =
        maintenance.completedAtUtc != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${maintenance.equipmentCode} Maintenance',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      maintenance.equipmentCode,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      maintenance.equipmentName,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge,
                    ),
                    const SizedBox(height: 12),
                    Chip(
                      label: Text(
                        isCompleted
                            ? 'Completed'
                            : 'Pending',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _maintenanceType,
              decoration: const InputDecoration(
                labelText: 'Maintenance Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Preventive',
                  child: Text('Preventive'),
                ),
                DropdownMenuItem(
                  value: 'Corrective',
                  child: Text('Corrective'),
                ),
                DropdownMenuItem(
                  value: 'Inspection',
                  child: Text('Inspection'),
                ),
                DropdownMenuItem(
                  value: 'Repair',
                  child: Text('Repair'),
                ),
                DropdownMenuItem(
                  value: 'Other',
                  child: Text('Other'),
                ),
              ],
              onChanged: _isSaving
                  ? null
                  : (value) {
                      if (value == null) return;

                      setState(() {
                        _maintenanceType = value;
                      });
                    },
            ),
            const SizedBox(height: 16),
            _DateTile(
              title: 'Scheduled At',
              value: _formatDateTime(_scheduledAt),
              onTap:
                  _isSaving ? null : _pickScheduledAt,
            ),
            const Divider(),
            _DateTile(
              title: 'Started At',
              value: _startedAt == null
                  ? 'Not started'
                  : _formatDateTime(_startedAt!),
              onTap:
                  _isSaving ? null : _pickStartedAt,
              onClear: _startedAt == null
                  ? null
                  : () {
                      setState(() {
                        _startedAt = null;
                      });
                    },
            ),
            const Divider(),
            _DateTile(
              title: 'Completed At',
              value: _completedAt == null
                  ? 'Not completed'
                  : _formatDateTime(
                      _completedAt!,
                    ),
              onTap:
                  _isSaving ? null : _pickCompletedAt,
              onClear: _completedAt == null
                  ? null
                  : () {
                      setState(() {
                        _completedAt = null;
                      });
                    },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _meterController,
              enabled: !_isSaving,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Meter Reading',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _costController,
              enabled: !_isSaving,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Cost',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _currencyController,
              enabled: !_isSaving,
              textCapitalization:
                  TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Currency',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Enter currency code';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _providerController,
              enabled: !_isSaving,
              decoration: const InputDecoration(
                labelText: 'Service Provider',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              enabled: !_isSaving,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _partsController,
              enabled: !_isSaving,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Parts Replaced',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _DateTile(
              title: 'Next Maintenance At',
              value: _nextMaintenanceAt == null
                  ? 'Not scheduled'
                  : _formatDateTime(
                      _nextMaintenanceAt!,
                    ),
              onTap: _isSaving
                  ? null
                  : _pickNextMaintenanceAt,
              onClear: _nextMaintenanceAt == null
                  ? null
                  : () {
                      setState(() {
                        _nextMaintenanceAt = null;
                      });
                    },
            ),
            const Divider(),
            TextFormField(
              controller: _nextMeterController,
              enabled: !_isSaving,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText:
                    'Next Maintenance Meter Reading',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
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

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.title,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String title;
  final String value;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(value),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onClear != null)
            IconButton(
              tooltip: 'Clear',
              onPressed: onClear,
              icon: const Icon(Icons.clear),
            ),
          IconButton(
            tooltip: 'Select date',
            onPressed: onTap,
            icon: const Icon(
              Icons.calendar_month_outlined,
            ),
          ),
        ],
      ),
    );
  }
}
