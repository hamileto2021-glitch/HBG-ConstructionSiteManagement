import 'package:flutter/material.dart';

import '../data/models/equipment.dart';
import '../data/repositories/equipment_repository.dart';

class EquipmentDetailScreen extends StatefulWidget {
  EquipmentDetailScreen({
    super.key,
    required this.equipment,
    EquipmentRepository? repository,
  }) : repository = repository ?? EquipmentRepository();

  final Equipment equipment;
  final EquipmentRepository repository;

  @override
  State<EquipmentDetailScreen> createState() =>
      _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState
    extends State<EquipmentDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _equipmentCodeController;
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _makeController;
  late final TextEditingController _modelController;
  late final TextEditingController _serialNumberController;
  late final TextEditingController _registrationNumberController;
  late final TextEditingController _vendorIdController;
  late final TextEditingController _purchaseCostController;
  late final TextEditingController _rentalRateController;
  late final TextEditingController _meterReadingController;

  late String _ownershipType;
  late String _status;
  late String _meterUnit;
  String? _rentalRateUnit;
  late bool _isActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final equipment = widget.equipment;

    _equipmentCodeController =
        TextEditingController(text: equipment.equipmentCode);
    _nameController =
        TextEditingController(text: equipment.name);
    _categoryController =
        TextEditingController(text: equipment.category ?? '');
    _makeController =
        TextEditingController(text: equipment.make ?? '');
    _modelController =
        TextEditingController(text: equipment.model ?? '');
    _serialNumberController =
        TextEditingController(text: equipment.serialNumber ?? '');
    _registrationNumberController =
        TextEditingController(
      text: equipment.registrationNumber ?? '',
    );
    _vendorIdController =
        TextEditingController(text: equipment.vendorId ?? '');
    _purchaseCostController = TextEditingController(
      text: equipment.purchaseCost?.toString() ?? '',
    );
    _rentalRateController = TextEditingController(
      text: equipment.rentalRate?.toString() ?? '',
    );
    _meterReadingController = TextEditingController(
      text: equipment.currentMeterReading.toString(),
    );

    _ownershipType = equipment.ownershipType;
    _status = equipment.status;
    _meterUnit = equipment.meterUnit;
    _rentalRateUnit = equipment.rentalRateUnit;
    _isActive = equipment.isActive;
  }

  @override
  void dispose() {
    _equipmentCodeController.dispose();
    _nameController.dispose();
    _categoryController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _serialNumberController.dispose();
    _registrationNumberController.dispose();
    _vendorIdController.dispose();
    _purchaseCostController.dispose();
    _rentalRateController.dispose();
    _meterReadingController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final meterReading =
        double.tryParse(_meterReadingController.text.trim());

    if (meterReading == null || meterReading < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a valid non-negative meter reading.',
          ),
        ),
      );
      return;
    }

    final purchaseCost =
        double.tryParse(_purchaseCostController.text.trim());

    final rentalRate =
        double.tryParse(_rentalRateController.text.trim());

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.repository.update(
        equipmentId: widget.equipment.id,
        equipmentCode:
            _equipmentCodeController.text.trim(),
        name: _nameController.text.trim(),
        category: _nullable(_categoryController.text),
        make: _nullable(_makeController.text),
        model: _nullable(_modelController.text),
        serialNumber:
            _nullable(_serialNumberController.text),
        registrationNumber:
            _nullable(_registrationNumberController.text),
        ownershipType: _ownershipType,
        status: _status,
        vendorId: _nullable(_vendorIdController.text),
        purchaseCost: purchaseCost,
        rentalRate: rentalRate,
        rentalRateUnit: _rentalRateUnit,
        currentMeterReading: meterReading,
        meterUnit: _meterUnit,
        isActive: _isActive,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Equipment updated successfully.'),
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

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment Details'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _equipmentCodeController,
              enabled: !_isSaving,
              decoration: const InputDecoration(
                labelText: 'Equipment Code',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Equipment code is required.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              enabled: !_isSaving,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Name is required.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoryController,
              enabled: !_isSaving,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _makeController,
              enabled: !_isSaving,
              decoration: const InputDecoration(
                labelText: 'Make',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _modelController,
              enabled: !_isSaving,
              decoration: const InputDecoration(
                labelText: 'Model',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _serialNumberController,
              enabled: !_isSaving,
              decoration: const InputDecoration(
                labelText: 'Serial Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _registrationNumberController,
              enabled: !_isSaving,
              decoration: const InputDecoration(
                labelText: 'Registration Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _ownershipType,
              decoration: const InputDecoration(
                labelText: 'Ownership Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Owned',
                  child: Text('Owned'),
                ),
                DropdownMenuItem(
                  value: 'Rented',
                  child: Text('Rented'),
                ),
              ],
              onChanged: _isSaving
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _ownershipType = value;
                      });
                    },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Available',
                  child: Text('Available'),
                ),
                DropdownMenuItem(
                  value: 'InUse',
                  child: Text('In Use'),
                ),
                DropdownMenuItem(
                  value: 'Maintenance',
                  child: Text('Maintenance'),
                ),
                DropdownMenuItem(
                  value: 'Retired',
                  child: Text('Retired'),
                ),
              ],
              onChanged: _isSaving
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _status = value;
                      });
                    },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _vendorIdController,
              enabled: !_isSaving,
              decoration: const InputDecoration(
                labelText: 'Vendor ID',
                border: OutlineInputBorder(),
                hintText: 'Optional',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _purchaseCostController,
              enabled: !_isSaving,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Purchase Cost',
                border: OutlineInputBorder(),
                hintText: 'Optional',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _rentalRateController,
              enabled: !_isSaving,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Rental Rate',
                border: OutlineInputBorder(),
                hintText: 'Optional',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: _rentalRateUnit,
              decoration: const InputDecoration(
                labelText: 'Rental Rate Unit',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Not specified'),
                ),
                DropdownMenuItem<String?>(
                  value: 'Hour',
                  child: Text('Hour'),
                ),
                DropdownMenuItem<String?>(
                  value: 'Day',
                  child: Text('Day'),
                ),
                DropdownMenuItem<String?>(
                  value: 'Month',
                  child: Text('Month'),
                ),
              ],
              onChanged: _isSaving
                  ? null
                  : (value) {
                      setState(() {
                        _rentalRateUnit = value;
                      });
                    },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _meterReadingController,
              enabled: !_isSaving,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Current Meter Reading',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Meter reading is required.';
                }

                final parsed =
                    double.tryParse(value.trim());

                if (parsed == null || parsed < 0) {
                  return 'Enter a valid non-negative number.';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _meterUnit,
              decoration: const InputDecoration(
                labelText: 'Meter Unit',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Hours',
                  child: Text('Hours'),
                ),
                DropdownMenuItem(
                  value: 'Kilometers',
                  child: Text('Kilometers'),
                ),
                DropdownMenuItem(
                  value: 'Miles',
                  child: Text('Miles'),
                ),
              ],
              onChanged: _isSaving
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _meterUnit = value;
                      });
                    },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              value: _isActive,
              onChanged: _isSaving
                  ? null
                  : (value) {
                      setState(() {
                        _isActive = value;
                      });
                    },
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
                  _isSaving ? 'Saving...' : 'Save Changes',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
