import 'package:flutter/material.dart';

import '../../sites/data/models/site.dart';
import '../../sites/data/repositories/site_repository.dart';
import '../data/models/material.dart' as material_model;
import '../data/models/material_request.dart';
import '../data/repositories/material_repository.dart';
import '../data/repositories/material_request_repository.dart';

class MaterialRequestCreateScreen extends StatefulWidget {
  const MaterialRequestCreateScreen({
    super.key,
    required this.repository,
    this.siteRepository,
    this.materialRepository,
  });

  final MaterialRequestRepository repository;
  final SiteRepository? siteRepository;
  final MaterialRepository? materialRepository;

  @override
  State<MaterialRequestCreateScreen> createState() =>
      _MaterialRequestCreateScreenState();
}

class _MaterialRequestCreateScreenState
    extends State<MaterialRequestCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _requestNumberController = TextEditingController();
  final _purposeController = TextEditingController();

  final List<_RequestLineDraft> _lines = [];

  List<Site> _sites = [];
  List<material_model.Material> _materials = [];

  String? _selectedSiteId;

  DateTime _requestDate = DateTime.now();
  DateTime? _requiredByDate;
  Priority _priority = Priority.normal;

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
    _requestNumberController.dispose();
    _purposeController.dispose();

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

      final materialRepository =
          widget.materialRepository ??
              MaterialRepository();

      final results = await Future.wait([
        siteRepository.getAll(),
        materialRepository.getAll(isActive: true),
      ]);

      if (!mounted) {
        return;
      }

      final sites = results[0] as List<Site>;
      final materials =
          results[1] as List<material_model.Material>;

      setState(() {
        _sites = sites
            .where((site) => site.isActive)
            .toList();
        _materials = materials;
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
      _lines.add(_RequestLineDraft());
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

  Future<void> _selectRequestDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _requestDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selected != null && mounted) {
      setState(() {
        _requestDate = selected;
      });
    }
  }

  Future<void> _selectRequiredByDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate:
          _requiredByDate ?? _requestDate,
      firstDate: _requestDate,
      lastDate: DateTime(2100),
    );

    if (selected != null && mounted) {
      setState(() {
        _requiredByDate = selected;
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

    if (_lines.isEmpty) {
      _showMessage(
        'At least one material line is required.',
      );
      return;
    }

    final lines = <MaterialRequestLineInput>[];

    for (final line in _lines) {
      final materialId = line.materialId;
      final quantity = double.tryParse(
        line.quantityController.text.trim(),
      );

      if (materialId == null ||
          materialId.isEmpty ||
          quantity == null ||
          quantity <= 0) {
        _showMessage(
          'Every material line needs a material and a quantity greater than zero.',
        );
        return;
      }

      lines.add(
        MaterialRequestLineInput(
          materialId: materialId,
          requestedQuantity: quantity,
          remarks: _optionalValue(
            line.remarksController,
          ),
        ),
      );
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.repository.create(
        constructionSiteId: _selectedSiteId!,
        requestNumber:
            _requestNumberController.text.trim(),
        requestDate: _requestDate,
        requiredByDate: _requiredByDate,
        purpose: _optionalValue(
          _purposeController,
        ),
        priority: _priority,
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
        'Failed to create material request: $error',
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

  String _priorityLabel(Priority priority) {
    switch (priority) {
      case Priority.low:
        return 'Low';
      case Priority.normal:
        return 'Normal';
      case Priority.high:
        return 'High';
      case Priority.critical:
        return 'Critical';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Material Request',
        ),
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
                      TextFormField(
                        controller:
                            _requestNumberController,
                        enabled: !_isSaving,
                        decoration:
                            const InputDecoration(
                          labelText: 'Request Number',
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Request number is required.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding:
                            EdgeInsets.zero,
                        title:
                            const Text('Request Date'),
                        subtitle: Text(
                          _formatDate(_requestDate),
                        ),
                        trailing: const Icon(
                          Icons.calendar_today_outlined,
                        ),
                        onTap: _isSaving
                            ? null
                            : _selectRequestDate,
                      ),
                      ListTile(
                        contentPadding:
                            EdgeInsets.zero,
                        title: const Text(
                          'Required By Date',
                        ),
                        subtitle: Text(
                          _requiredByDate == null
                              ? 'Not specified'
                              : _formatDate(
                                  _requiredByDate!,
                                ),
                        ),
                        trailing: const Icon(
                          Icons.event_available_outlined,
                        ),
                        onTap: _isSaving
                            ? null
                            : _selectRequiredByDate,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<Priority>(
                        initialValue: _priority,
                        decoration:
                            const InputDecoration(
                          labelText: 'Priority',
                        ),
                        items: Priority.values
                            .map(
                              (priority) =>
                                  DropdownMenuItem<
                                      Priority>(
                                value: priority,
                                child: Text(
                                  _priorityLabel(
                                    priority,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _isSaving
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() {
                                    _priority = value;
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller:
                            _purposeController,
                        enabled: !_isSaving,
                        decoration:
                            const InputDecoration(
                          labelText: 'Purpose',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Material Lines',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge,
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: _isSaving
                                ? null
                                : _addLine,
                            icon: const Icon(
                              Icons.add,
                            ),
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
                                : 'Create Request',
                          ),
                        ),
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
                '${site.siteCode} — ${site.name}',
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
              'Unable to load construction sites '
              'and materials.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),
            const SizedBox(height: 8),
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
}

class _RequestLineDraft {
  String? materialId;
  String unitOfMeasure = '';

  final quantityController = TextEditingController();
  final remarksController = TextEditingController();

  void dispose() {
    quantityController.dispose();
    remarksController.dispose();
  }
}

class _LineCard extends StatefulWidget {
  const _LineCard({
    required this.index,
    required this.line,
    required this.materials,
    required this.canRemove,
    required this.enabled,
    required this.onRemove,
  });

  final int index;
  final _RequestLineDraft line;
  final List<material_model.Material> materials;
  final bool canRemove;
  final bool enabled;
  final VoidCallback onRemove;

  @override
  State<_LineCard> createState() => _LineCardState();
}

class _LineCardState extends State<_LineCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Line ${widget.index + 1}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Remove line',
                  onPressed: widget.canRemove && widget.enabled
                      ? widget.onRemove
                      : null,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Material
            DropdownButtonFormField<String>(
              initialValue: widget.line.materialId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Material',
                border: OutlineInputBorder(),
              ),
              items: widget.materials
                  .map(
                    (m) => DropdownMenuItem<String>(
                  value: m.id,
                  child: Text(
                    '${m.materialCode} — ${m.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
                  .toList(),
              onChanged: widget.enabled
                  ? (value) {
                if (value == null) return;

                final material = widget.materials.firstWhere(
                      (m) => m.id == value,
                );

                setState(() {
                  widget.line.materialId = material.id;
                  widget.line.unitOfMeasure =
                      material.unitOfMeasure;
                });
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

            // Unit of Measure Dropdown (Read Only)
            DropdownButtonFormField<String>(
              initialValue: widget.line.unitOfMeasure.isEmpty
                  ? null
                  : widget.line.unitOfMeasure,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Unit of Measure',
                border: OutlineInputBorder(),
              ),
              items: widget.materials
                  .map((m) => m.unitOfMeasure)
                  .toSet()
                  .map(
                    (uom) => DropdownMenuItem<String>(
                  value: uom,
                  child: Text(uom),
                ),
              )
                  .toList(),
              onChanged: widget.enabled
                  ? (value) {
                if (value == null) return;

                setState(() {
                  widget.line.unitOfMeasure = value;
                });
              }
                  : null,
            ),

            const SizedBox(height: 12),

            // Quantity
            TextFormField(
              controller: widget.line.quantityController,
              enabled: widget.enabled,
              decoration: InputDecoration(
                labelText: widget.line.unitOfMeasure.isEmpty
                    ? 'Requested Quantity'
                    : 'Requested Quantity (${widget.line.unitOfMeasure})',
                border: const OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                final qty = double.tryParse(value?.trim() ?? '');

                if (qty == null || qty <= 0) {
                  return 'Enter a quantity greater than zero.';
                }
                return null;
              },
            ),

            const SizedBox(height: 12),

            // Remarks
            TextFormField(
              controller: widget.line.remarksController,
              enabled: widget.enabled,
              decoration: const InputDecoration(
                labelText: 'Remarks',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
