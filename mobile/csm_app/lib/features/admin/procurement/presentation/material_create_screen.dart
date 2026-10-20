import 'package:flutter/material.dart' hide MaterialType;

import '../data/models/material.dart';
import '../data/repositories/material_repository.dart';
import '../data/models/material_lookup.dart';



class MaterialCreateScreen extends StatefulWidget {
  const MaterialCreateScreen({
    super.key,
    required this.repository,
  });

  final MaterialRepository repository;

  @override
  State<MaterialCreateScreen> createState() =>
      _MaterialCreateScreenState();
}

class _MaterialCreateScreenState
    extends State<MaterialCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _materialCodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _defaultCostCodeIdController = TextEditingController();
  final _standardUnitCostController = TextEditingController();

  bool _isActive = true;
  bool _isSaving = false;

  List<MaterialLookup> _categories = [];
  List<MaterialLookup> _units = [];
  List<MaterialLookup> _materialTypes = [];

  String? _selectedCategory;
  String? _selectedUnit;
  String? _selectedMaterialType;

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    try {
      final categories = await widget.repository.getCategories();
      final units = await widget.repository.getUnits();
      final types = await widget.repository.getMaterialTypes();

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _units = units;
        _materialTypes = types;

        if (categories.isNotEmpty) {
          _selectedCategory = categories.first.value;
        }

        if (units.isNotEmpty) {
          _selectedUnit = units.first.value;
        }

        if (types.isNotEmpty) {
          _selectedMaterialType = types.first.value;
        }
      });
    } catch (_) {}
  }
  @override
  void dispose() {
    _materialCodeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();

    _defaultCostCodeIdController.dispose();
    _standardUnitCostController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final standardUnitCostText =
          _standardUnitCostController.text.trim();

      final standardUnitCost =
          standardUnitCostText.isEmpty
              ? null
              : double.tryParse(standardUnitCostText);

      if (standardUnitCostText.isNotEmpty &&
          standardUnitCost == null) {
        throw const FormatException(
          'Standard unit cost must be a valid number.',
        );
      }

      await widget.repository.create(
        materialCode:
            _materialCodeController.text.trim(),
        name: _nameController.text.trim(),
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
          category: _selectedCategory!,
          unitOfMeasure: _selectedUnit!,
        materialType: MaterialType.values.firstWhere(
              (e) =>
          e.name.toLowerCase() ==
              (_selectedMaterialType ?? 'Bulk').toLowerCase(),
          orElse: () => MaterialType.bulk,
        ),
        defaultCostCodeId:
            _defaultCostCodeIdController.text
                    .trim()
                    .isEmpty
                ? null
                : _defaultCostCodeIdController.text
                    .trim(),
        standardUnitCost: standardUnitCost,
        isActive: _isActive,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Material created successfully.'),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

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
        title: const Text('Create Material'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _materialCodeController,
              decoration: const InputDecoration(
                labelText: 'Material Code',
                border: OutlineInputBorder(),
              ),
              textInputAction:
                  TextInputAction.next,
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Material code is required.';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              textInputAction:
                  TextInputAction.next,
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
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textInputAction:
                  TextInputAction.next,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories
                  .map(
                    (e) => DropdownMenuItem(
                  value: e.value,
                  child: Text(e.name),
                ),
              )
                  .toList(),
              validator: (v) =>
              v == null ? 'Category is required.' : null,
              onChanged: (v) => setState(() {
                _selectedCategory = v;
              }),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedUnit,
              decoration: const InputDecoration(
                labelText: 'Unit of Measure',
                border: OutlineInputBorder(),
              ),
              items: _units
                  .map(
                    (e) => DropdownMenuItem(
                  value: e.value,
                  child: Text(e.name),
                ),
              )
                  .toList(),
              validator: (v) => v == null
                  ? 'Unit of measure is required.'
                  : null,
              onChanged: (v) => setState(() {
                _selectedUnit = v;
              }),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedMaterialType,
              decoration: const InputDecoration(
                labelText: 'Material Type',
                border: OutlineInputBorder(),
              ),
              items: _materialTypes
                  .map(
                    (e) => DropdownMenuItem(
                  value: e.value,
                  child: Text(e.name),
                ),
              )
                  .toList(),
              validator: (v) =>
              v == null ? 'Material type is required.' : null,
              onChanged: (v) => setState(() {
                _selectedMaterialType = v;
              }),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller:
                  _defaultCostCodeIdController,
              decoration: const InputDecoration(
                labelText: 'Default Cost Code ID',
                border: OutlineInputBorder(),
                hintText: 'Optional',
              ),
              textInputAction:
                  TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller:
                  _standardUnitCostController,
              decoration: const InputDecoration(
                labelText: 'Standard Unit Cost',
                border: OutlineInputBorder(),
                hintText: 'Optional',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction:
                  TextInputAction.done,
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
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _isSaving
                      ? 'Saving...'
                      : 'Create Material',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}






