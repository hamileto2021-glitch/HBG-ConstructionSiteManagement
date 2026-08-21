import 'package:flutter/material.dart' hide Material, MaterialType;

import '../data/models/material.dart';
import '../data/repositories/material_repository.dart';

class MaterialDetailScreen extends StatefulWidget {
  const MaterialDetailScreen({
    super.key,
    required this.materialId,
    required this.repository,
  });

  final String materialId;
  final MaterialRepository repository;

  @override
  State<MaterialDetailScreen> createState() =>
      _MaterialDetailScreenState();
}

class _MaterialDetailScreenState
    extends State<MaterialDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  final _materialCodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _unitOfMeasureController = TextEditingController();
  final _defaultCostCodeIdController = TextEditingController();
  final _standardUnitCostController = TextEditingController();

  Material? _material;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  bool _isActive = true;
  MaterialType _materialType = MaterialType.bulk;

  @override
  void initState() {
    super.initState();
    _loadMaterial();
  }

  @override
  void dispose() {
    _materialCodeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _unitOfMeasureController.dispose();
    _defaultCostCodeIdController.dispose();
    _standardUnitCostController.dispose();
    super.dispose();
  }

  Future<void> _loadMaterial() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final material =
          await widget.repository.getById(
        widget.materialId,
      );

      if (!mounted) {
        return;
      }

      _material = material;
      _materialCodeController.text =
          material.materialCode;
      _nameController.text = material.name;
      _descriptionController.text =
          material.description ?? '';
      _categoryController.text = material.category;
      _unitOfMeasureController.text =
          material.unitOfMeasure;
      _defaultCostCodeIdController.text =
          material.defaultCostCodeId ?? '';
      _standardUnitCostController.text =
          material.standardUnitCost?.toString() ?? '';
      _isActive = material.isActive;
      _materialType = material.materialType;

      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final costText =
          _standardUnitCostController.text.trim();

      final standardUnitCost = costText.isEmpty
          ? null
          : double.tryParse(costText);

      if (costText.isNotEmpty &&
          standardUnitCost == null) {
        throw const FormatException(
          'Standard unit cost must be a valid number.',
        );
      }

      await widget.repository.update(
        materialId: widget.materialId,
        materialCode:
            _materialCodeController.text.trim(),
        name: _nameController.text.trim(),
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
        category:
            _categoryController.text.trim(),
        unitOfMeasure:
            _unitOfMeasureController.text.trim(),
        materialType: _materialType,
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
          content: Text('Material updated successfully.'),
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
        title: const Text('Material Details'),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
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
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadMaterial,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_material == null) {
      return const Center(
        child: Text('Material not found.'),
      );
    }

    return Form(
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
            validator: _requiredValidator,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            validator: _requiredValidator,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _categoryController,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            validator: _requiredValidator,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _unitOfMeasureController,
            decoration: const InputDecoration(
              labelText: 'Unit of Measure',
              border: OutlineInputBorder(),
            ),
            validator: _requiredValidator,
          ),
          const SizedBox(height: 16),
            DropdownButtonFormField<MaterialType>(
              initialValue: _materialType,
              decoration: const InputDecoration(
                labelText: 'Material Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: MaterialType.bulk,
                  child: Text('Bulk'),
                ),
                DropdownMenuItem(
                  value: MaterialType.rebarLinear,
                  child: Text('Rebar Linear'),
                ),
              ],
              onChanged: _isSaving
                  ? null
                  : (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        _materialType = value;
                      });
                    },
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
                      child: CircularProgressIndicator(
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
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }

    return null;
  }
}












