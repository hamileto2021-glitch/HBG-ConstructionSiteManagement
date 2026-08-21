import 'package:flutter/material.dart';

import '../data/models/budget.dart';
import '../data/repositories/budget_repository.dart';
import '../data/repositories/budget_line_repository.dart';
import 'budget_line_list_screen.dart';

class BudgetDetailScreen extends StatefulWidget {
  const BudgetDetailScreen({
    super.key,
    required this.budget,
    required this.repository,
  });

  final Budget budget;
  final BudgetRepository repository;

  @override
  State<BudgetDetailScreen> createState() =>
      _BudgetDetailScreenState();
}

class _BudgetDetailScreenState
    extends State<BudgetDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _totalAmountController;
  late final TextEditingController _currencyCodeController;

  late Budget _budget;

  DateTime? _effectiveFrom;
  DateTime? _effectiveTo;

  bool _isSaving = false;
  bool _isChangingStatus = false;

  @override
  void initState() {
    super.initState();

    _budget = widget.budget;

    _nameController =
        TextEditingController(text: _budget.name);

    _descriptionController =
        TextEditingController(
      text: _budget.description ?? '',
    );

    _totalAmountController =
        TextEditingController(
      text: _budget.totalAmount.toString(),
    );

    _currencyCodeController =
        TextEditingController(
      text: _budget.currencyCode,
    );

    _effectiveFrom = _budget.effectiveFrom;
    _effectiveTo = _budget.effectiveTo;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _totalAmountController.dispose();
    _currencyCodeController.dispose();
    super.dispose();
  }

  bool get _canEdit {
    return _budget.status == BudgetStatus.draft ||
        _budget.status ==
            BudgetStatus.pendingApproval;
  }

  List<BudgetStatus> get _allowedTransitions {
    switch (_budget.status) {
      case BudgetStatus.draft:
        return [
          BudgetStatus.pendingApproval,
          BudgetStatus.cancelled,
        ];

      case BudgetStatus.pendingApproval:
        return [
          BudgetStatus.approved,
          BudgetStatus.draft,
          BudgetStatus.cancelled,
        ];

      case BudgetStatus.approved:
        return [
          BudgetStatus.active,
          BudgetStatus.cancelled,
        ];

      case BudgetStatus.active:
        return [
          BudgetStatus.closed,
        ];

      case BudgetStatus.closed:
      case BudgetStatus.cancelled:
        return [];
    }
  }

  Future<void> _selectDate({
    required bool isStart,
  }) async {
    if (!_canEdit || _isSaving) {
      return;
    }

    final initialDate = isStart
        ? (_effectiveFrom ?? DateTime.now())
        : (_effectiveTo ??
            _effectiveFrom ??
            DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (!mounted || picked == null) {
      return;
    }

    setState(() {
      if (isStart) {
        _effectiveFrom = picked;

        if (_effectiveTo != null &&
            _effectiveTo!.isBefore(picked)) {
          _effectiveTo = null;
        }
      } else {
        _effectiveTo = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_canEdit) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final totalAmount = double.tryParse(
      _totalAmountController.text.trim(),
    );

    if (totalAmount == null ||
        totalAmount < 0) {
      return;
    }

    if (_effectiveFrom != null &&
        _effectiveTo != null &&
        _effectiveTo!.isBefore(_effectiveFrom!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Effective To cannot be before Effective From.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updated =
          await widget.repository.update(
        budgetId: _budget.id,
        name: _nameController.text.trim(),
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
        totalAmount: totalAmount,
        currencyCode:
            _currencyCodeController.text
                .trim()
                .toUpperCase(),
        effectiveFrom: _effectiveFrom,
        effectiveTo: _effectiveTo,
      );

      if (!mounted) return;

      setState(() {
        _budget = updated;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Budget updated successfully.',
          ),
        ),
      );
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

  Future<void> _changeStatus(
    BudgetStatus status,
  ) async {
    if (_isChangingStatus) {
      return;
    }

    final confirmed =
        await _confirmStatusChange(status);

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _isChangingStatus = true;
    });

    try {
      final updated =
          await widget.repository.changeStatus(
        budgetId: _budget.id,
        status: status,
      );

      if (!mounted) return;

      setState(() {
        _budget = updated;
        _isChangingStatus = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Budget status changed to '
            '${_statusLabel(status)}.',
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

  Future<bool> _confirmStatusChange(
    BudgetStatus status,
  ) async {
    final action = _statusActionLabel(status);

    final result =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(action),
          content: Text(
            'Change budget "${_budget.budgetNumber}" '
            'from ${_statusLabel(_budget.status)} '
            'to ${_statusLabel(status)}?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(true),
              child: Text(action),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  String _statusLabel(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.draft:
        return 'Draft';
      case BudgetStatus.pendingApproval:
        return 'Pending Approval';
      case BudgetStatus.approved:
        return 'Approved';
      case BudgetStatus.active:
        return 'Active';
      case BudgetStatus.closed:
        return 'Closed';
      case BudgetStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _statusActionLabel(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.pendingApproval:
        return 'Submit for Approval';
      case BudgetStatus.approved:
        return 'Approve';
      case BudgetStatus.active:
        return 'Activate';
      case BudgetStatus.closed:
        return 'Close';
      case BudgetStatus.draft:
        return 'Return to Draft';
      case BudgetStatus.cancelled:
        return 'Cancel Budget';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Not set';
    }

    String two(int value) =>
        value.toString().padLeft(2, '0');

    return '${date.year}-${two(date.month)}-'
        '${two(date.day)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_budget.budgetNumber),
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
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 36,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            _budget.name,
                            style: theme
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _statusLabel(
                              _budget.status,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(
                        _statusLabel(
                          _budget.status,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _ReadOnlyField(
              label: 'Budget Number',
              value: _budget.budgetNumber,
            ),
            const SizedBox(height: 16),
            _ReadOnlyField(
              label: 'Construction Site',
              value: _budget.constructionSiteId,
            ),
            const SizedBox(height: 16),
            _ReadOnlyField(
              label: 'Project',
              value:
                  _budget.projectId ?? 'No Project',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              enabled: _canEdit && !_isSaving,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Enter a budget name';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              enabled: _canEdit && !_isSaving,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _totalAmountController,
              enabled: _canEdit && !_isSaving,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Total Amount',
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
              controller: _currencyCodeController,
              enabled: _canEdit && !_isSaving,
              textCapitalization:
                  TextCapitalization.characters,
              maxLength: 3,
              decoration: const InputDecoration(
                labelText: 'Currency Code',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().length != 3) {
                  return 'Use a 3-letter currency code';
                }

                return null;
              },
            ),
            const SizedBox(height: 8),
            _DateField(
              label: 'Effective From',
              value:
                  _formatDate(_effectiveFrom),
              enabled: _canEdit && !_isSaving,
              onTap: () =>
                  _selectDate(isStart: true),
            ),
            const SizedBox(height: 12),
            _DateField(
              label: 'Effective To',
              value:
                  _formatDate(_effectiveTo),
              enabled: _canEdit && !_isSaving,
              onTap: () =>
                  _selectDate(isStart: false),
            ),
            const SizedBox(height: 24),
            if (_canEdit)
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
                        : 'Save Changes',
                  ),
                ),
              ),
            if (_canEdit)
              const SizedBox(height: 24),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.account_tree_outlined,
                ),
                title: const Text('Budget Lines'),
                subtitle: const Text(
                  'Manage cost-code allocations for this budget.',
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BudgetLineListScreen(
                        budgetId: _budget.id,
                        repository: BudgetLineRepository(),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Status Actions',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (_allowedTransitions.isEmpty)
              const Text(
                'No further status transitions are available.',
              )
            else
              ..._allowedTransitions.map(
                (status) => Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 10,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed:
                          _isChangingStatus
                              ? null
                              : () =>
                                  _changeStatus(
                                    status,
                                  ),
                      icon: Icon(
                        _statusIcon(status),
                      ),
                      label: Text(
                        _statusActionLabel(
                          status,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (_isChangingStatus)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Center(
                  child:
                      CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _statusIcon(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.pendingApproval:
        return Icons.send_outlined;
      case BudgetStatus.approved:
        return Icons.check_circle_outline;
      case BudgetStatus.active:
        return Icons.play_circle_outline;
      case BudgetStatus.closed:
        return Icons.lock_outline;
      case BudgetStatus.draft:
        return Icons.undo_outlined;
      case BudgetStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: Text(value),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(
            Icons.calendar_today_outlined,
          ),
        ),
        child: Text(value),
      ),
    );
  }
}
