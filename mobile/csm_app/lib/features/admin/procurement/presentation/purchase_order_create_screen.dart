import 'package:flutter/material.dart';

import '../../sites/data/models/site.dart';
import '../../sites/data/repositories/site_repository.dart';
import '../data/models/material.dart' as material_model;
import '../data/models/purchase_order.dart';
import '../data/models/vendor.dart';
import '../data/repositories/material_repository.dart';
import '../data/repositories/purchase_order_repository.dart';
import '../data/repositories/vendor_repository.dart';

class PurchaseOrderCreateScreen extends StatefulWidget {
  const PurchaseOrderCreateScreen({
    super.key,
    required this.repository,
    this.siteRepository,
    this.vendorRepository,
    this.materialRepository,
  });

  final PurchaseOrderRepository repository;
  final SiteRepository? siteRepository;
  final VendorRepository? vendorRepository;
  final MaterialRepository? materialRepository;

  @override
  State<PurchaseOrderCreateScreen> createState() =>
      _PurchaseOrderCreateScreenState();
}

class _PurchaseOrderCreateScreenState
    extends State<PurchaseOrderCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _purchaseOrderNumberController =
      TextEditingController();
  final _projectIdController = TextEditingController();
  final _materialRequestIdController =
      TextEditingController();
  final _currencyCodeController =
      TextEditingController(text: 'ETB');
  final _exchangeRateController =
      TextEditingController(text: '1');
  final _discountController =
      TextEditingController(text: '0');
  final _deliveryAddressController =
      TextEditingController();
  final _paymentTermsController =
      TextEditingController();
  final _notesController = TextEditingController();

  final List<_PurchaseOrderLineDraft> _lines = [];

  List<Site> _sites = [];
  List<Vendor> _vendors = [];
  List<material_model.Material> _materials = [];

  String? _selectedSiteId;
  String? _selectedVendorId;

  DateTime _orderDate = DateTime.now();
  DateTime? _expectedDeliveryDate;

  bool _isLoadingReferences = true;
  bool _isSaving = false;
  String? _referenceError;

  @override
  void initState() {
    super.initState();
    _addLine();
    _loadReferences();
  }

  @override
  void dispose() {
    _purchaseOrderNumberController.dispose();
    _projectIdController.dispose();
    _materialRequestIdController.dispose();
    _currencyCodeController.dispose();
    _exchangeRateController.dispose();
    _discountController.dispose();
    _deliveryAddressController.dispose();
    _paymentTermsController.dispose();
    _notesController.dispose();

    for (final line in _lines) {
      line.dispose();
    }

    super.dispose();
  }

  Future<void> _loadReferences() async {
    setState(() {
      _isLoadingReferences = true;
      _referenceError = null;
    });

    try {
      final siteRepository =
          widget.siteRepository ?? SiteRepository();
      final vendorRepository =
          widget.vendorRepository ?? VendorRepository();
      final materialRepository =
          widget.materialRepository ?? MaterialRepository();

      final results = await Future.wait([
        siteRepository.getAll(),
        vendorRepository.getAll(isActive: true),
        materialRepository.getAll(isActive: true),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _sites = (results[0] as List<Site>)
            .where((site) => site.isActive)
            .toList();

        _vendors = (results[1] as List<Vendor>)
            .where((vendor) => vendor.isActive)
            .toList();

        _materials =
            results[2] as List<material_model.Material>;

        _isLoadingReferences = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _referenceError = error.toString();
        _isLoadingReferences = false;
      });
    }
  }

  void _addLine() {
    setState(() {
      _lines.add(_PurchaseOrderLineDraft());
    });
  }

  void _removeLine(int index) {
    if (_lines.length == 1) {
      return;
    }

    final line = _lines.removeAt(index);
    line.dispose();

    setState(() {});
  }

  Future<void> _selectOrderDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _orderDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selected != null && mounted) {
      setState(() {
        _orderDate = selected;
      });
    }
  }

  Future<void> _selectExpectedDeliveryDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate:
          _expectedDeliveryDate ?? _orderDate,
      firstDate: _orderDate,
      lastDate: DateTime(2100),
    );

    if (selected != null && mounted) {
      setState(() {
        _expectedDeliveryDate = selected;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSiteId == null) {
      _showMessage(
        'Please select a construction site.',
      );
      return;
    }

    if (_selectedVendorId == null) {
      _showMessage(
        'Please select a vendor.',
      );
      return;
    }

    if (_lines.isEmpty) {
      _showMessage(
        'At least one purchase order line is required.',
      );
      return;
    }

    final exchangeRate = double.tryParse(
      _exchangeRateController.text.trim(),
    );

    final discountAmount = double.tryParse(
      _discountController.text.trim(),
    );

    if (exchangeRate == null || exchangeRate <= 0) {
      _showMessage(
        'Exchange rate must be greater than zero.',
      );
      return;
    }

    if (discountAmount == null || discountAmount < 0) {
      _showMessage(
        'Discount amount cannot be negative.',
      );
      return;
    }

    final lines = <PurchaseOrderLineInput>[];

    for (final line in _lines) {
      final materialId = line.materialIdController.text.trim();
      final quantity = double.tryParse(
        line.quantityController.text.trim(),
      );
      final unitPrice = double.tryParse(
        line.unitPriceController.text.trim(),
      );
      final taxAmount = double.tryParse(
        line.taxAmountController.text.trim(),
      );

      if (
          materialId.isEmpty ||
          quantity == null ||
          quantity <= 0 ||
          unitPrice == null ||
          unitPrice < 0 ||
          taxAmount == null ||
          taxAmount < 0) {
        _showMessage(
          'Every line needs a material, quantity greater than zero, '
          'and valid price/tax amounts.',
        );
        return;
      }

      lines.add(
        PurchaseOrderLineInput(
          materialId: materialId,
          costCodeId:
              _optionalValue(line.costCodeController),
          orderedQuantity: quantity,
          unitPrice: unitPrice,
          taxAmount: taxAmount,
        ),
      );
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.repository.create(
        constructionSiteId: _selectedSiteId!,
        projectId:
            _optionalValue(_projectIdController),
        vendorId: _selectedVendorId!,
        materialRequestId:
            _optionalValue(
          _materialRequestIdController,
        ),
        purchaseOrderNumber:
            _purchaseOrderNumberController.text.trim(),
        orderDate: _orderDate,
        expectedDeliveryDate:
            _expectedDeliveryDate,
        currencyCode:
            _currencyCodeController.text.trim(),
        exchangeRate: exchangeRate,
        discountAmount: discountAmount,
        deliveryAddress:
            _optionalValue(_deliveryAddressController),
        paymentTerms:
            _optionalValue(_paymentTermsController),
        notes: _optionalValue(_notesController),
        lines: lines,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      _showMessage(
        'Failed to create purchase order: $error',
      );
    }
  }

  String? _optionalValue(
    TextEditingController controller,
  ) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();

    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Purchase Order'),
      ),
      body: _isLoadingReferences
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _referenceError != null
              ? _buildReferenceError()
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _buildSiteSelector(),
                      const SizedBox(height: 16),
                      _buildVendorSelector(),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller:
                            _purchaseOrderNumberController,
                        enabled: !_isSaving,
                        decoration:
                            const InputDecoration(
                          labelText: 'Purchase Order Number',
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Purchase order number is required.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title:
                            const Text('Order Date'),
                        subtitle: Text(
                          _formatDate(_orderDate),
                        ),
                        trailing: const Icon(
                          Icons.calendar_today_outlined,
                        ),
                        onTap: _isSaving
                            ? null
                            : _selectOrderDate,
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Expected Delivery Date',
                        ),
                        subtitle: Text(
                          _expectedDeliveryDate == null
                              ? 'Not specified'
                              : _formatDate(
                                  _expectedDeliveryDate!,
                                ),
                        ),
                        trailing: const Icon(
                          Icons.event_available_outlined,
                        ),
                        onTap: _isSaving
                            ? null
                            : _selectExpectedDeliveryDate,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller:
                            _projectIdController,
                        enabled: !_isSaving,
                        decoration:
                            const InputDecoration(
                          labelText: 'Project ID (optional)',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller:
                            _materialRequestIdController,
                        enabled: !_isSaving,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Material Request ID (optional)',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller:
                                  _currencyCodeController,
                              enabled: !_isSaving,
                              decoration:
                                  const InputDecoration(
                                labelText: 'Currency',
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return 'Currency is required.';
                                }

                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller:
                                  _exchangeRateController,
                              enabled: !_isSaving,
                              decoration:
                                  const InputDecoration(
                                labelText: 'Exchange Rate',
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller:
                            _discountController,
                        enabled: !_isSaving,
                        decoration:
                            const InputDecoration(
                          labelText: 'Discount Amount',
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller:
                            _deliveryAddressController,
                        enabled: !_isSaving,
                        decoration:
                            const InputDecoration(
                          labelText: 'Delivery Address',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller:
                            _paymentTermsController,
                        enabled: !_isSaving,
                        decoration:
                            const InputDecoration(
                          labelText: 'Payment Terms',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        enabled: !_isSaving,
                        decoration:
                            const InputDecoration(
                          labelText: 'Notes',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Purchase Order Lines',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge,
                            ),
                          ),
                          FilledButton.icon(
                            onPressed:
                                _isSaving ? null : _addLine,
                            icon:
                                const Icon(Icons.add),
                            label:
                                const Text('Add Line'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._lines.asMap().entries.map(
                        (entry) {
                          return _LineCard(
                            index: entry.key,
                            line: entry.value,
                            materials: _materials,
                            canRemove:
                                _lines.length > 1,
                            enabled: !_isSaving,
                            onRemove: () =>
                                _removeLine(
                              entry.key,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed:
                              _isSaving ? null : _save,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
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
                                : 'Create Purchase Order',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildReferenceError() {
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
              _referenceError!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadReferences,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSiteSelector() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedSiteId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Construction Site',
      ),
      items: _sites
          .map(
            (site) => DropdownMenuItem<String>(
              value: site.id,
              child: Text(
                '${site.siteCode} - ${site.name}',
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
    );
  }

  Widget _buildVendorSelector() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedVendorId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Vendor',
      ),
      items: _vendors
          .map(
            (vendor) => DropdownMenuItem<String>(
              value: vendor.id,
              child: Text(
                '${vendor.vendorCode} - ${vendor.name}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: _isSaving
          ? null
          : (value) {
              setState(() {
                _selectedVendorId = value;
              });
            },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Vendor is required.';
        }

        return null;
      },
    );
  }
}

class _PurchaseOrderLineDraft {
  final materialIdController =
      TextEditingController();
  final costCodeController =
      TextEditingController();
  final quantityController =
      TextEditingController();
  final unitPriceController =
      TextEditingController();
  final taxAmountController =
      TextEditingController(text: '0');

  void dispose() {
    materialIdController.dispose();
    costCodeController.dispose();
    quantityController.dispose();
    unitPriceController.dispose();
    taxAmountController.dispose();
  }
}

class _LineCard extends StatelessWidget {
  const _LineCard({
    required this.index,
    required this.line,
    required this.materials,
    required this.canRemove,
    required this.enabled,
    required this.onRemove,
  });

  final int index;
  final _PurchaseOrderLineDraft line;
  final List<material_model.Material> materials;
  final bool canRemove;
  final bool enabled;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Line ${index + 1}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),
                ),
                if (canRemove)
                  IconButton(
                    tooltip: 'Remove line',
                    onPressed:
                        enabled ? onRemove : null,
                    icon: const Icon(
                      Icons.delete_outline,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue:
                  line.materialIdController.text.isEmpty
                      ? null
                      : line.materialIdController.text,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Material',
              ),
              items: materials
                  .map(
                    (material) =>
                        DropdownMenuItem<String>(
                      value: material.id,
                      child: Text(
                        '${material.materialCode} - ${material.name}',
                        overflow:
                            TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: enabled
                  ? (value) {
                      line.materialIdController.text =
                          value ?? '';
                    }
                  : null,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Material is required.';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: line.costCodeController,
              enabled: enabled,
              decoration: const InputDecoration(
                labelText: 'Cost Code ID (optional)',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller:
                        line.quantityController,
                    enabled: enabled,
                    decoration:
                        const InputDecoration(
                      labelText: 'Quantity',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      final quantity =
                          double.tryParse(
                        value?.trim() ?? '',
                      );

                      if (quantity == null ||
                          quantity <= 0) {
                        return 'Enter quantity.';
                      }

                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller:
                        line.unitPriceController,
                    enabled: enabled,
                    decoration:
                        const InputDecoration(
                      labelText: 'Unit Price',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      final price =
                          double.tryParse(
                        value?.trim() ?? '',
                      );

                      if (price == null ||
                          price < 0) {
                        return 'Enter price.';
                      }

                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: line.taxAmountController,
              enabled: enabled,
              decoration: const InputDecoration(
                labelText: 'Tax Amount',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                final tax = double.tryParse(
                  value?.trim() ?? '',
                );

                if (tax == null || tax < 0) {
                  return 'Enter tax amount.';
                }

                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}



