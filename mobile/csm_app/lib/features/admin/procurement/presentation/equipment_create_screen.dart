import 'package:flutter/material.dart';

import '../data/repositories/equipment_repository.dart';

class EquipmentCreateScreen extends StatefulWidget {
  EquipmentCreateScreen({
    super.key,
    EquipmentRepository? repository,
  }) : repository = repository ?? EquipmentRepository();

  final EquipmentRepository repository;

  @override
  State<EquipmentCreateScreen> createState() =>
      _EquipmentCreateScreenState();
}

class _EquipmentCreateScreenState
    extends State<EquipmentCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _equipmentCodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _vendorIdController = TextEditingController();
  final _purchaseCostController = TextEditingController();
  final _rentalRateController = TextEditingController();
  final _meterReadingController =
      TextEditingController(text: '0');

  String _ownershipType = 'Owned';
  String _status = 'Available';
  String _meterUnit = 'Hours';
  String? _rentalRateUnit;
  bool _isActive = true;
  bool _isSaving = false;

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
      await widget.repository.create(
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
          content: Text('Equipment created successfully.'),
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
        title: const Text('Add Equipment'),
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
              textInputAction: TextInputAction.next,
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
              textInputAction: TextInputAction.next,
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
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _makeController,
              enabled: !_isSaving,
              decoration: const InputDecoration(
                labelText: 'Make',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _modelController,
              enabled: !_isSaving,
              decoration: const InputDecoration(
                labelText: 'Model',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _serialNumberController,
              enabled: !_isSaving,
              decoration: const InputDecoration(
                labelText: 'Serial Number',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _registrationNumberController,
              enabled: !_isSaving,
              decoration: const InputDecoration(
                labelText: 'Registration Number',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
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
              textInputAction: TextInputAction.next,
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
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _isSaving
                      ? 'Saving...'
                      : 'Create Equipment',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
