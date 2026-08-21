import 'package:flutter/material.dart';

import '../data/models/budget_line.dart';
import '../data/models/cost_code.dart';
import '../data/repositories/budget_line_repository.dart';
import '../data/repositories/cost_code_repository.dart';

class BudgetLineCreateScreen extends StatefulWidget {
  const BudgetLineCreateScreen({
    super.key,
    required this.budgetId,
    required this.repository,
    this.costCodeRepository,
    this.line,
  });

  final String budgetId;
  final BudgetLineRepository repository;
  final CostCodeRepository? costCodeRepository;
  final BudgetLine? line;

  bool get isEditing => line != null;

  @override
  State<BudgetLineCreateScreen> createState() =>
      _BudgetLineCreateScreenState();
}

class _BudgetLineCreateScreenState
    extends State<BudgetLineCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _descriptionController;
  late final TextEditingController _budgetedAmountController;
  late final TextEditingController _revisedAmountController;

  late final CostCodeRepository _costCodeRepository;

  List<CostCode> _costCodes = [];
  CostCode? _selectedCostCode;

  bool _isLoadingCostCodes = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _costCodeRepository =
        widget.costCodeRepository ??
            CostCodeRepository();

    final line = widget.line;

    _descriptionController =
        TextEditingController(
      text: line?.description ?? '',
    );

    _budgetedAmountController =
        TextEditingController(
      text: line?.budgetedAmount.toString() ?? '',
    );

    _revisedAmountController =
        TextEditingController(
      text: line?.revisedAmount.toString() ?? '',
    );

    _loadCostCodes();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _budgetedAmountController.dispose();
    _revisedAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadCostCodes() async {
    setState(() {
      _isLoadingCostCodes = true;
      _errorMessage = null;
    });

    try {
      final costCodes =
          await _costCodeRepository.getAll();

      if (!mounted) return;

      final existingCostCodeId =
          widget.line?.costCodeId;

      CostCode? selected;

      if (existingCostCodeId != null) {
        for (final costCode in costCodes) {
          if (costCode.id == existingCostCodeId) {
            selected = costCode;
            break;
          }
        }
      }

      setState(() {
        _costCodes = costCodes
            .where((costCode) => costCode.isActive)
            .toList();

        _selectedCostCode = selected;
        _isLoadingCostCodes = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingCostCodes = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final selectedCostCode =
        _selectedCostCode;

    if (selectedCostCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Select a cost code.',
          ),
        ),
      );
      return;
    }

    final budgetedAmount = double.tryParse(
      _budgetedAmountController.text.trim(),
    );

    final revisedAmount = double.tryParse(
      _revisedAmountController.text.trim(),
    );

    if (budgetedAmount == null ||
        revisedAmount == null) {
      return;
    }

    if (budgetedAmount < 0 ||
        revisedAmount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Amounts cannot be negative.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final description =
          _descriptionController.text
                  .trim()
                  .isEmpty
              ? null
              : _descriptionController.text
                  .trim();

      if (widget.isEditing) {
        await widget.repository.update(
          budgetLineId: widget.line!.id,
          costCodeId: selectedCostCode.id,
          description: description,
          budgetedAmount: budgetedAmount,
          revisedAmount: revisedAmount,
        );
      } else {
        await widget.repository.create(
          budgetId: widget.budgetId,
          costCodeId: selectedCostCode.id,
          description: description,
          budgetedAmount: budgetedAmount,
          revisedAmount: revisedAmount,
        );
      }

      if (!mounted) return;

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
    final title = widget.isEditing
        ? 'Edit Budget Line'
        : 'Add Budget Line';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoadingCostCodes) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
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
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadCostCodes,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_costCodes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No active cost codes are available.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<String>(
            initialValue:
                _selectedCostCode?.id,
            decoration:
                const InputDecoration(
              labelText: 'Cost Code',
              border: OutlineInputBorder(),
            ),
            items: _costCodes
                .map(
                  (costCode) =>
                      DropdownMenuItem<String>(
                    value: costCode.id,
                    child: Text(
                      '${costCode.code} - '
                      '${costCode.name}',
                    ),
                  ),
                )
                .toList(),
            onChanged: _isSaving
                ? null
                : (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _selectedCostCode =
                          _costCodes.firstWhere(
                        (costCode) =>
                            costCode.id == value,
                      );
                    });
                  },
            validator: (value) {
              if (value == null ||
                  value.isEmpty) {
                return 'Select a cost code';
              }

              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            enabled: !_isSaving,
            maxLines: 3,
            decoration:
                const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller:
                _budgetedAmountController,
            enabled: !_isSaving,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration:
                const InputDecoration(
              labelText: 'Budgeted Amount',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final amount =
                  double.tryParse(
                value?.trim() ?? '',
              );

              if (amount == null ||
                  amount < 0) {
                return 'Enter a valid amount';
              }

              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller:
                _revisedAmountController,
            enabled: !_isSaving,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration:
                const InputDecoration(
              labelText: 'Revised Amount',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final amount =
                  double.tryParse(
                value?.trim() ?? '',
              );

              if (amount == null ||
                  amount < 0) {
                return 'Enter a valid amount';
              }

              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed:
                  _isSaving ? null : _save,
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
                    : widget.isEditing
                        ? 'Save Changes'
                        : 'Create Budget Line',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
