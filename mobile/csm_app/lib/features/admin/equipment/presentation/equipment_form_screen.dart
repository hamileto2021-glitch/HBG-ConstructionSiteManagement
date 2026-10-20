import 'package:flutter/material.dart';

import '../data/equipment_repository.dart';
import '../data/models/equipment_model.dart';

class EquipmentFormScreen extends StatefulWidget {
  const EquipmentFormScreen({super.key});

  @override
  State<EquipmentFormScreen> createState() => _EquipmentFormScreenState();
}

class _EquipmentFormScreenState extends State<EquipmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = EquipmentRepository();

  final _code = TextEditingController();
  final _name = TextEditingController();
  final _category = TextEditingController();
  final _manufacturer = TextEditingController();
  final _model = TextEditingController();
  final _serial = TextEditingController();
  final _supplier = TextEditingController();

  bool _isRented = false;
  bool _saving = false;

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _category.dispose();
    _manufacturer.dispose();
    _model.dispose();
    _serial.dispose();
    _supplier.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final equipment = EquipmentModel(
        id: '',
        equipmentCode: _code.text.trim(),
        name: _name.text.trim(),
        category: _category.text.trim(),
        manufacturer: _manufacturer.text.trim().isEmpty
            ? null
            : _manufacturer.text.trim(),
        model: _model.text.trim().isEmpty ? null : _model.text.trim(),
        serialNumber: _serial.text.trim().isEmpty ? null : _serial.text.trim(),
        isRented: _isRented,
        supplierName:
        _supplier.text.trim().isEmpty ? null : _supplier.text.trim(),
        purchaseDate: null,
        nextMaintenanceDate: null,
        isActive: true,
      );

      await _repository.create(equipment);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _field(
      TextEditingController controller,
      String label, {
        bool required = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        validator: required
            ? (v) => (v == null || v.trim().isEmpty)
            ? '$label is required'
            : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
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
          padding: const EdgeInsets.all(16),
          children: [
            _field(_code, 'Equipment Code', required: true),
            _field(_name, 'Equipment Name', required: true),
            _field(_category, 'Category', required: true),
            _field(_manufacturer, 'Manufacturer'),
            _field(_model, 'Model'),
            _field(_serial, 'Serial Number'),
            _field(_supplier, 'Supplier'),

            SwitchListTile(
              value: _isRented,
              onChanged: (v) => setState(() => _isRented = v),
              title: const Text('Rented Equipment'),
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Saving...' : 'Save Equipment'),
            ),
          ],
        ),
      ),
    );
  }
}