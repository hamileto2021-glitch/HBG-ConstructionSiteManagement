import 'package:flutter/material.dart';

import '../data/models/equipment.dart';
import '../data/repositories/equipment_maintenance_repository.dart';
import '../data/repositories/equipment_repository.dart';

class EquipmentMaintenanceCreateScreen extends StatefulWidget {
  EquipmentMaintenanceCreateScreen({
    super.key,
    EquipmentMaintenanceRepository? maintenanceRepository,
    EquipmentRepository? equipmentRepository,
  })  : maintenanceRepository =
            maintenanceRepository ??
                EquipmentMaintenanceRepository(),
        equipmentRepository =
            equipmentRepository ?? EquipmentRepository();

  final EquipmentMaintenanceRepository maintenanceRepository;
  final EquipmentRepository equipmentRepository;

  @override
  State<EquipmentMaintenanceCreateScreen> createState() =>
      _EquipmentMaintenanceCreateScreenState();
}

class _EquipmentMaintenanceCreateScreenState
    extends State<EquipmentMaintenanceCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _meterController = TextEditingController();
  final _costController = TextEditingController();
  final _currencyController =
      TextEditingController(text: 'ETB');
  final _providerController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _partsController = TextEditingController();
  final _nextMeterController = TextEditingController();

  List<Equipment> _equipment = [];
  Equipment? _selectedEquipment;

  String _maintenanceType = 'Preventive';
  DateTime _scheduledAt = DateTime.now();
  DateTime? _nextMaintenanceAt;

  bool _isLoadingEquipment = true;
  bool _isSaving = false;
  String? _equipmentError;

  @override
  void initState() {
    super.initState();
    _loadEquipment();
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

  Future<void> _loadEquipment() async {
    setState(() {
      _isLoadingEquipment = true;
      _equipmentError = null;
    });

    try {
      final equipment =
          await widget.equipmentRepository.getAll(
        isActive: true,
      );

      if (!mounted) return;

      setState(() {
        _equipment = equipment;
        _isLoadingEquipment = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingEquipment = false;
        _equipmentError = error.toString();
      });
    }
  }

  Future<void> _pickScheduledAt() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (!mounted || date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _scheduledAt,
      ),
    );

    if (!mounted || time == null) return;

    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _pickNextMaintenanceAt() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _nextMaintenanceAt ?? _scheduledAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (!mounted || date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _nextMaintenanceAt ?? _scheduledAt,
      ),
    );

    if (!mounted || time == null) return;

    setState(() {
      _nextMaintenanceAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();

    String two(int value) =>
        value.toString().padLeft(2, '0');

    return '${local.year}-${two(local.month)}-'
        '${two(local.day)} ${two(local.hour)}:'
        '${two(local.minute)}';
  }

  double? _parseOptionalNumber(
    TextEditingController controller,
  ) {
    final value = controller.text.trim();

    if (value.isEmpty) {
      return null;
    }

    return double.tryParse(value);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedEquipment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select equipment.'),
        ),
      );
      return;
    }

    final meterReading =
        _parseOptionalNumber(_meterController);
    final cost = _parseOptionalNumber(_costController);
    final nextMeterReading =
        _parseOptionalNumber(_nextMeterController);

    if (_meterController.text.trim().isNotEmpty &&
        meterReading == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Enter a valid meter reading.'),
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
      await widget.maintenanceRepository.create(
        equipmentId: _selectedEquipment!.id,
        maintenanceType: _maintenanceType,
        scheduledAtUtc: _scheduledAt.toUtc(),
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
            'Equipment maintenance created successfully.',
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Equipment Maintenance'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoadingEquipment) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_equipmentError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _equipmentError!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadEquipment,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<Equipment>(
            initialValue: _selectedEquipment,
            decoration: const InputDecoration(
              labelText: 'Equipment',
              border: OutlineInputBorder(),
            ),
            items: _equipment
                .map(
                  (equipment) =>
                      DropdownMenuItem<Equipment>(
                    value: equipment,
                    child: Text(
                      '${equipment.equipmentCode} - '
                      '${equipment.name}',
                    ),
                  ),
                )
                .toList(),
            onChanged: _isSaving
                ? null
                : (value) {
                    setState(() {
                      _selectedEquipment = value;
                    });
                  },
            validator: (value) {
              if (value == null) {
                return 'Select equipment';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
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
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Scheduled At'),
            subtitle: Text(
              _formatDateTime(_scheduledAt),
            ),
            trailing: const Icon(
              Icons.calendar_month_outlined,
            ),
            onTap: _isSaving
                ? null
                : _pickScheduledAt,
          ),
          const Divider(),
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
              hintText: 'Optional',
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
              hintText: 'Optional',
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
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Next Maintenance At',
            ),
            subtitle: Text(
              _nextMaintenanceAt == null
                  ? 'Not scheduled'
                  : _formatDateTime(
                      _nextMaintenanceAt!,
                    ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_nextMaintenanceAt != null)
                  IconButton(
                    tooltip: 'Clear',
                    onPressed: _isSaving
                        ? null
                        : () {
                            setState(() {
                              _nextMaintenanceAt =
                                  null;
                            });
                          },
                    icon: const Icon(Icons.clear),
                  ),
                IconButton(
                  tooltip: 'Select date',
                  onPressed: _isSaving
                      ? null
                      : _pickNextMaintenanceAt,
                  icon: const Icon(
                    Icons.calendar_month_outlined,
                  ),
                ),
              ],
            ),
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
              hintText: 'Optional',
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
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                _isSaving
                    ? 'Saving...'
                    : 'Save Maintenance',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
