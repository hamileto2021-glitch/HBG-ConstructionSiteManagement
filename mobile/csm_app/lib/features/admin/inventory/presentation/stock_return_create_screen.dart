import 'package:flutter/material.dart';

import '../data/models/stock_movement.dart';
import '../data/models/stock_return.dart';
import '../data/repositories/stock_movement_repository.dart';
import '../data/repositories/stock_return_repository.dart';

class StockReturnCreateScreen extends StatefulWidget {
  const StockReturnCreateScreen({
    super.key,
    required this.repository,
    required this.stockMovementRepository,
  });

  final StockReturnRepository repository;
  final StockMovementRepository stockMovementRepository;

  @override
  State<StockReturnCreateScreen> createState() =>
      _StockReturnCreateScreenState();
}

class _StockReturnCreateScreenState
    extends State<StockReturnCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _quantityController = TextEditingController();
  final _referenceNumberController = TextEditingController();
  final _returnedByController = TextEditingController();
  final _reasonController = TextEditingController();
  final _remarksController = TextEditingController();

  List<StockMovement> _issueMovements = [];

  String? _selectedMovementId;

  DateTime _returnDateUtc = DateTime.now().toUtc();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  StockMovement? get _selectedMovement {
    if (_selectedMovementId == null) {
      return null;
    }

    for (final movement in _issueMovements) {
      if (movement.id == _selectedMovementId) {
        return movement;
      }
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadIssueMovements();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _referenceNumberController.dispose();
    _returnedByController.dispose();
    _reasonController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadIssueMovements() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final movements =
      await widget.stockMovementRepository.getAll(
        movementType: StockMovementType.issue,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _issueMovements = movements;
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

  Future<void> _selectReturnDate() async {
    final localDate = _returnDateUtc.toLocal();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: localDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _returnDateUtc = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        localDate.hour,
        localDate.minute,
      ).toUtc();
    });
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();

    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  String _formatQuantity(
      double value,
      String unitOfMeasure,
      ) {
    return '$value $unitOfMeasure';
  }

  String? _cleanOptional(String value) {
    final trimmed = value.trim();

    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final movement = _selectedMovement;

    if (movement == null) {
      _showMessage(
        'Please select the original issue.',
      );
      return;
    }

    final quantity = double.tryParse(
      _quantityController.text.trim(),
    );

    if (quantity == null || quantity <= 0) {
      _showMessage(
        'Quantity must be greater than zero.',
      );
      return;
    }

    if (quantity > movement.quantity) {
      _showMessage(
        'Return quantity cannot exceed the original '
            'issued quantity of ${_formatQuantity(
          movement.quantity,
          movement.unitOfMeasure,
        )}.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await widget.repository.create(
        CreateStockReturnRequest(
          originalIssueMovementId: movement.id,
          quantity: quantity,
          returnDateUtc: _returnDateUtc,
          referenceNumber:
          _referenceNumberController.text.trim(),
          returnedBy: _cleanOptional(
            _returnedByController.text,
          ),
          reason: _cleanOptional(
            _reasonController.text,
          ),
          remarks: _cleanOptional(
            _remarksController.text,
          ),
        ),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Stock return created successfully.',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _error = error.toString();
      });

      _showMessage(error.toString());
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Stock Return'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
            _isLoading || _isSaving
                ? null
                : _loadIssueMovements,
            icon: const Icon(Icons.refresh),
          ),
        ],
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

    if (_error != null &&
        _issueMovements.isEmpty) {
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
                onPressed: _loadIssueMovements,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_issueMovements.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No stock issue movements were found. '
                'Create a stock issue before recording a return.',
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
            initialValue: _selectedMovementId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Original Stock Issue',
              border: OutlineInputBorder(),
            ),
            items: _issueMovements.map(
                  (movement) {
                return DropdownMenuItem<String>(
                  value: movement.id,
                  child: Text(
                    '${movement.materialCode} - '
                        '${movement.materialName} '
                        '(${movement.siteName})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ).toList(),
            onChanged: _isSaving
                ? null
                : (value) {
              setState(() {
                _selectedMovementId = value;
                _quantityController.clear();
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Original stock issue is required.';
              }

              return null;
            },
          ),
          if (_selectedMovement != null) ...[
            const SizedBox(height: 16),
            _buildIssueInformation(
              context,
              _selectedMovement!,
            ),
          ],
          const SizedBox(height: 16),
          TextFormField(
            controller: _quantityController,
            decoration: InputDecoration(
              labelText: 'Return Quantity',
              border: const OutlineInputBorder(),
              suffixText:
              _selectedMovement?.unitOfMeasure,
            ),
            keyboardType:
            const TextInputType.numberWithOptions(
              decimal: true,
            ),
            validator: (value) {
              final quantity = double.tryParse(
                value?.trim() ?? '',
              );

              if (quantity == null || quantity <= 0) {
                return 'Enter a quantity greater than zero.';
              }

              final movement = _selectedMovement;

              if (movement != null &&
                  quantity > movement.quantity) {
                return 'Cannot exceed issued quantity.';
              }

              return null;
            },
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Return Date'),
            subtitle: Text(
              _formatDate(_returnDateUtc),
            ),
            trailing: const Icon(
              Icons.calendar_today_outlined,
            ),
            onTap:
            _isSaving ? null : _selectReturnDate,
          ),
          const Divider(),
          const SizedBox(height: 16),
          TextFormField(
            controller: _referenceNumberController,
            decoration: const InputDecoration(
              labelText: 'Reference Number',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Reference number is required.';
              }

              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _returnedByController,
            decoration: const InputDecoration(
              labelText: 'Returned By',
              border: OutlineInputBorder(),
              hintText: 'Optional',
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason',
              border: OutlineInputBorder(),
              hintText: 'Optional',
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _remarksController,
            decoration: const InputDecoration(
              labelText: 'Remarks',
              border: OutlineInputBorder(),
              hintText: 'Optional',
            ),
            maxLines: 3,
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .error,
              ),
            ),
          ],
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
                  : const Icon(
                Icons.keyboard_return_outlined,
              ),
              label: Text(
                _isSaving
                    ? 'Saving...'
                    : 'Return Stock',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueInformation(
      BuildContext context,
      StockMovement movement,
      ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              'Original Issue',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Material: ${movement.materialCode} - '
                  '${movement.materialName}',
            ),
            const SizedBox(height: 4),
            Text(
              'Site: ${movement.siteName}',
            ),
            const SizedBox(height: 4),
            Text(
              'Issued: ${_formatQuantity(
                movement.quantity,
                movement.unitOfMeasure,
              )}',
            ),
            if (movement.referenceNumber != null) ...[
              const SizedBox(height: 4),
              Text(
                'Reference: '
                    '${movement.referenceNumber}',
              ),
            ],
          ],
        ),
      ),
    );
  }
}