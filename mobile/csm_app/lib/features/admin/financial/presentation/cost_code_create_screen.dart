import 'package:flutter/material.dart';

import '../data/models/cost_code.dart';
import '../data/repositories/cost_code_repository.dart';

class CostCodeCreateScreen extends StatefulWidget {
  const CostCodeCreateScreen({
    super.key,
    required this.repository,
  });

  final CostCodeRepository repository;

  @override
  State<CostCodeCreateScreen> createState() =>
      _CostCodeCreateScreenState();
}

class _CostCodeCreateScreenState
    extends State<CostCodeCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<CostCode> _parentCostCodes = [];
  String? _parentCostCodeId;

  bool _isLoadingParents = true;
  bool _isSaving = false;
  String? _parentErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadParentCostCodes();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadParentCostCodes() async {
    try {
      final costCodes =
          await widget.repository.getAll();

      if (!mounted) return;

      setState(() {
        _parentCostCodes = costCodes;
        _isLoadingParents = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingParents = false;
        _parentErrorMessage = error.toString();
      });
    }
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.repository.create(
        code: _codeController.text.trim(),
        name: _nameController.text.trim(),
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
        parentCostCodeId: _parentCostCodeId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cost code created successfully.',
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
        title: const Text('Add Cost Code'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _codeController,
              enabled: !_isSaving,
              textCapitalization:
                  TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Code',
                hintText: 'e.g. MAT-001',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Enter a cost code';
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
                hintText: 'Cost code name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Enter a cost code name';
                }

                return null;
              },
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
            if (_isLoadingParents)
              const InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Parent Cost Code',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Loading cost codes...'),
                  ],
                ),
              )
            else
              DropdownButtonFormField<String?>(
                initialValue: _parentCostCodeId,
                decoration: const InputDecoration(
                  labelText: 'Parent Cost Code',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('None'),
                  ),
                  ..._parentCostCodes
                      .where(
                        (costCode) =>
                            costCode.isActive,
                      )
                      .map(
                        (costCode) =>
                            DropdownMenuItem<String?>(
                          value: costCode.id,
                          child: Text(
                            '${costCode.code} - ${costCode.name}',
                          ),
                        ),
                      ),
                ],
                onChanged: _isSaving
                    ? null
                    : (value) {
                        setState(() {
                          _parentCostCodeId = value;
                        });
                      },
              ),
            if (_parentErrorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                'Parent cost codes could not be loaded. '
                'You can still create this cost code without a parent.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall,
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed:
                    _isSaving ? null : _create,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.save_outlined,
                      ),
                label: Text(
                  _isSaving
                      ? 'Saving...'
                      : 'Create Cost Code',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
