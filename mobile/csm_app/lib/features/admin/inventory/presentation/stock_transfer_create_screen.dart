import 'package:flutter/material.dart';

import '../../procurement/data/models/material.dart' as procurement;
import '../../procurement/data/repositories/material_repository.dart';
import '../../sites/data/models/site.dart';
import '../../sites/data/repositories/site_repository.dart';
import '../data/models/stock_transfer.dart';
import '../data/repositories/stock_transfer_repository.dart';

class StockTransferCreateScreen extends StatefulWidget {
  const StockTransferCreateScreen({
    super.key,
    required this.repository,
    required this.materialRepository,
    required this.siteRepository,
  });

  final StockTransferRepository repository;
  final MaterialRepository materialRepository;
  final SiteRepository siteRepository;

  @override
  State<StockTransferCreateScreen> createState() =>
      _StockTransferCreateScreenState();
}

class _StockTransferCreateScreenState
    extends State<StockTransferCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _quantityController = TextEditingController();
  final _transferNumberController = TextEditingController();
  final _requestedByController = TextEditingController();
  final _approvedByController = TextEditingController();
  final _remarksController = TextEditingController();

  List<procurement.Material> _materials = [];
  List<Site> _sites = [];

  String? _sourceSiteId;
  String? _destinationSiteId;
  String? _materialId;

  DateTime _transferDateUtc = DateTime.now().toUtc();

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
    _transferNumberController.dispose();
    _requestedByController.dispose();
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

  Future<void> _selectTransferDate() async {
    final localDate = _transferDateUtc.toLocal();

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
      _transferDateUtc = DateTime(
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

    if (_sourceSiteId == null) {
      _showMessage('Please select the source site.');
      return;
    }

    if (_destinationSiteId == null) {
      _showMessage(
        'Please select the destination site.',
      );
      return;
    }

    if (_sourceSiteId == _destinationSiteId) {
      _showMessage(
        'Source and destination sites must be different.',
      );
      return;
    }

    if (_materialId == null) {
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

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final transfer = await widget.repository.create(
        CreateStockTransferRequest(
          sourceConstructionSiteId: _sourceSiteId!,
          destinationConstructionSiteId:
          _destinationSiteId!,
          materialId: _materialId!,
          quantity: quantity,
          transferDateUtc: _transferDateUtc,
          transferNumber:
          _transferNumberController.text.trim(),
          requestedBy: _cleanOptional(
            _requestedByController.text,
          ),
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
            'Transfer successful.\n'
                'Source: ${transfer.sourceQuantityBefore} '
                '→ ${transfer.sourceQuantityAfter} '
                '${transfer.unitOfMeasure}\n'
                'Destination: ${transfer.destinationQuantityBefore} '
                '→ ${transfer.destinationQuantityAfter} '
                '${transfer.unitOfMeasure}',
          ),
        ),
      );

      Navigator.of(context).pop(transfer);
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
        title: const Text('Create Stock Transfer'),
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
            initialValue: _sourceSiteId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Source Site',
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
                _sourceSiteId = value;

                if (_destinationSiteId == value) {
                  _destinationSiteId = null;
                }
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Source site is required.';
              }

              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _destinationSiteId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Destination Site',
              border: OutlineInputBorder(),
            ),
            items: _sites
                .where(
                  (site) => site.id != _sourceSiteId,
            )
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
                _destinationSiteId = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Destination site is required.';
              }

              if (value == _sourceSiteId) {
                return 'Destination must differ from source.';
              }

              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _materialId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Material',
              border: OutlineInputBorder(),
            ),
            items: _materials.map(
                  (material) => DropdownMenuItem<String>(
                value: material.id,
                    child: Text(
                      '${material.materialCode} - '
                          '${material.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
              ),
            ).toList(),
            onChanged: _isSaving
                ? null
                : (value) {
              setState(() {
                _materialId = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Material is required.';
              }

              return null;
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
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Transfer Date'),
            subtitle: Text(
              _formatDate(_transferDateUtc),
            ),
            trailing: const Icon(
              Icons.calendar_today_outlined,
            ),
            onTap: _isSaving
                ? null
                : _selectTransferDate,
          ),
          const Divider(),
          const SizedBox(height: 16),
          TextFormField(
            controller: _transferNumberController,
            decoration: const InputDecoration(
              labelText: 'Transfer Number',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Transfer number is required.';
              }

              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _requestedByController,
            decoration: const InputDecoration(
              labelText: 'Requested By',
              border: OutlineInputBorder(),
              hintText: 'Optional',
            ),
            textInputAction: TextInputAction.next,
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
                Icons.swap_horiz_outlined,
              ),
              label: Text(
                _isSaving
                    ? 'Saving...'
                    : 'Transfer Stock',
              ),
            ),
          ),
        ],
      ),
    );
  }
}