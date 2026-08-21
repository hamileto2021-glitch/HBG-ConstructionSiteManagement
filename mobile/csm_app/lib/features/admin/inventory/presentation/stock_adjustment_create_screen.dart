import 'package:flutter/material.dart';

import '../../procurement/data/models/material.dart' as procurement;
import '../../procurement/data/repositories/material_repository.dart';
import '../../sites/data/models/site.dart';
import '../../sites/data/repositories/site_repository.dart';
import '../data/models/stock_adjustment.dart';
import '../data/repositories/stock_adjustment_repository.dart';

class StockAdjustmentCreateScreen extends StatefulWidget {
  const StockAdjustmentCreateScreen({
    super.key,
    required this.repository,
    required this.materialRepository,
    required this.siteRepository,
  });

  final StockAdjustmentRepository repository;
  final MaterialRepository materialRepository;
  final SiteRepository siteRepository;

  @override
  State<StockAdjustmentCreateScreen> createState() =>
      _StockAdjustmentCreateScreenState();
}

class _StockAdjustmentCreateScreenState
    extends State<StockAdjustmentCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _quantityController = TextEditingController();
  final _unitCostController = TextEditingController();
  final _adjustmentNumberController = TextEditingController();
  final _reasonController = TextEditingController();
  final _approvedByController = TextEditingController();
  final _remarksController = TextEditingController();

  List<procurement.Material> _materials = [];
  List<Site> _sites = [];

  String? _selectedSiteId;
  String? _selectedMaterialId;

  bool _increase = true;
  DateTime _adjustmentDateUtc = DateTime.now().toUtc();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitCostController.dispose();
    _adjustmentNumberController.dispose();
    _reasonController.dispose();
    _approvedByController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        widget.materialRepository.getAll(isActive: true),
        widget.siteRepository.getAll(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _materials =
        results[0] as List<procurement.Material>;
        _sites = results[1] as List<Site>;
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

  Future<void> _selectAdjustmentDate() async {
    final localDate = _adjustmentDateUtc.toLocal();

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
      _adjustmentDateUtc = DateTime(
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

  String? _cleanOptional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSiteId == null) {
      _showMessage('Please select a construction site.');
      return;
    }

    if (_selectedMaterialId == null) {
      _showMessage('Please select a material.');
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

    final unitCostText =
    _unitCostController.text.trim();

    final unitCost = unitCostText.isEmpty
        ? null
        : double.tryParse(unitCostText);

    if (unitCostText.isNotEmpty &&
        (unitCost == null || unitCost < 0)) {
      _showMessage(
        'Unit cost must be zero or greater.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final adjustment = await widget.repository.create(
        CreateStockAdjustmentRequest(
          constructionSiteId: _selectedSiteId!,
          materialId: _selectedMaterialId!,
          increase: _increase,
          quantity: quantity,
          unitCost: unitCost,
          adjustmentDateUtc: _adjustmentDateUtc,
          adjustmentNumber:
          _adjustmentNumberController.text.trim(),
          reason: _reasonController.text.trim(),
          approvedBy: _cleanOptional(
            _approvedByController.text,
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
        SnackBar(
          content: Text(
            'Stock adjustment successful.\n'
                'Balance: '
                '${adjustment.quantityBefore} '
                '${adjustment.unitOfMeasure} → '
                '${adjustment.quantityAfter} '
                '${adjustment.unitOfMeasure}',
          ),
        ),
      );

      Navigator.of(context).pop(adjustment);
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
        title: const Text('Create Stock Adjustment'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading || _isSaving
                ? null
                : _loadLookups,
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
        _materials.isEmpty &&
        _sites.isEmpty) {
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
                onPressed: _loadLookups,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
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
            initialValue: _selectedSiteId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Construction Site',
              border: OutlineInputBorder(),
            ),
            items: _sites
                .map(
                  (site) => DropdownMenuItem<String>(
                value: site.id,
                child: Text(
                  '${site.siteCode} - ${site.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
                .toList(),
            onChanged: _isSaving
                ? null
                : (value) {
              setState(() {
                _selectedSiteId = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Construction site is required.';
              }

              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedMaterialId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Material',
              border: OutlineInputBorder(),
            ),
            items: _materials
                .map(
                  (material) => DropdownMenuItem<String>(
                value: material.id,
                    child: Text(
                      '${material.materialCode} - '
                          '${material.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
              ),
            )
                .toList(),
            onChanged: _isSaving
                ? null
                : (value) {
              setState(() {
                _selectedMaterialId = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Material is required.';
              }

              return null;
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Adjustment Type',
            style: Theme.of(context)
                .textTheme
                .titleMedium,
          ),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(
                value: true,
                icon: Icon(
                  Icons.add_circle_outline,
                ),
                label: Text('Increase'),
              ),
              ButtonSegment<bool>(
                value: false,
                icon: Icon(
                  Icons.remove_circle_outline,
                ),
                label: Text('Decrease'),
              ),
            ],
            selected: {_increase},
            onSelectionChanged: _isSaving
                ? null
                : (selection) {
              setState(() {
                _increase = selection.first;
              });
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _quantityController,
            decoration: const InputDecoration(
              labelText: 'Quantity',
              border: OutlineInputBorder(),
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

              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _unitCostController,
            decoration: const InputDecoration(
              labelText: 'Unit Cost',
              border: OutlineInputBorder(),
              hintText: 'Optional',
            ),
            keyboardType:
            const TextInputType.numberWithOptions(
              decimal: true,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Adjustment Date'),
            subtitle: Text(
              _formatDate(_adjustmentDateUtc),
            ),
            trailing: const Icon(
              Icons.calendar_today_outlined,
            ),
            onTap: _isSaving
                ? null
                : _selectAdjustmentDate,
          ),
          const Divider(),
          const SizedBox(height: 16),
          TextFormField(
            controller: _adjustmentNumberController,
            decoration: const InputDecoration(
              labelText: 'Adjustment Number',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Adjustment number is required.';
              }

              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Reason is required.';
              }

              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _approvedByController,
            decoration: const InputDecoration(
              labelText: 'Approved By',
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
                Icons.tune_outlined,
              ),
              label: Text(
                _isSaving
                    ? 'Saving...'
                    : 'Adjust Stock',
              ),
            ),
          ),
        ],
      ),
    );
  }
}