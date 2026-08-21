import 'package:flutter/material.dart';

import '../data/models/cost_code.dart';
import '../data/repositories/cost_code_repository.dart';

class CostCodeDetailScreen extends StatefulWidget {
  const CostCodeDetailScreen({
    super.key,
    required this.costCode,
    required this.repository,
  });

  final CostCode costCode;
  final CostCodeRepository repository;

  @override
  State<CostCodeDetailScreen> createState() =>
      _CostCodeDetailScreenState();
}

class _CostCodeDetailScreenState
    extends State<CostCodeDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  List<CostCode> _parentCostCodes = [];
  String? _parentCostCodeId;

  late bool _isActive;

  bool _isLoadingParents = true;
  bool _isSaving = false;
  bool _isChangingStatus = false;
  String? _parentErrorMessage;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.costCode.name,
    );

    _descriptionController = TextEditingController(
      text: widget.costCode.description ?? '',
    );

    _parentCostCodeId =
        widget.costCode.parentCostCodeId;

    _isActive = widget.costCode.isActive;

    _loadParentCostCodes();
  }

  @override
  void dispose() {
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
        _parentCostCodes = costCodes
            .where(
              (costCode) =>
                  costCode.id != widget.costCode.id,
            )
            .toList();

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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.repository.update(
        costCodeId: widget.costCode.id,
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
            'Cost code updated successfully.',
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

  Future<void> _changeActiveStatus(
    bool value,
  ) async {
    setState(() {
      _isChangingStatus = true;
    });

    try {
      await widget.repository.changeActiveStatus(
        costCodeId: widget.costCode.id,
        isActive: value,
      );

      if (!mounted) return;

      setState(() {
        _isActive = value;
        _isChangingStatus = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Cost code activated.'
                : 'Cost code deactivated.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isChangingStatus = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
        ),
      );
    }
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();

    String two(int number) =>
        number.toString().padLeft(2, '0');

    return '${local.year}-${two(local.month)}-'
        '${two(local.day)}';
  }

  @override
  Widget build(BuildContext context) {
    final costCode = widget.costCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(costCode.code),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(12),
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                      ),
                      child: Icon(
                        Icons.account_tree_outlined,
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            costCode.code,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isActive
                                ? 'Active'
                                : 'Inactive',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isActive,
                      onChanged:
                          _isSaving ||
                                  _isChangingStatus
                              ? null
                              : _changeActiveStatus,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              initialValue: costCode.code,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              enabled:
                  !_isSaving && !_isChangingStatus,
              decoration: const InputDecoration(
                labelText: 'Name',
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
              enabled:
                  !_isSaving && !_isChangingStatus,
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
                        (item) => item.isActive,
                      )
                      .map(
                        (item) =>
                            DropdownMenuItem<String?>(
                          value: item.id,
                          child: Text(
                            '${item.code} - ${item.name}',
                          ),
                        ),
                      ),
                ],
                onChanged:
                    _isSaving ||
                            _isChangingStatus
                        ? null
                        : (value) {
                            setState(() {
                              _parentCostCodeId =
                                  value;
                            });
                          },
              ),
            if (_parentErrorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                'Parent cost codes could not be loaded. '
                'You can still edit this cost code without changing its parent.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall,
              ),
            ],
            const SizedBox(height: 20),
            if (costCode.createdAtUtc
                .toString()
                .isNotEmpty)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.calendar_today_outlined,
                ),
                title: const Text('Created'),
                subtitle: Text(
                  _formatDate(
                    costCode.createdAtUtc,
                  ),
                ),
              ),
            if (costCode.updatedAtUtc != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.update_outlined,
                ),
                title: const Text('Last Updated'),
                subtitle: Text(
                  _formatDate(
                    costCode.updatedAtUtc!,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed:
                    _isSaving ||
                            _isChangingStatus
                        ? null
                        : _save,
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
