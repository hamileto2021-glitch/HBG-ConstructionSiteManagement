import 'package:flutter/material.dart';

import '../data/models/material_request.dart';
import '../data/repositories/material_request_repository.dart';

class MaterialRequestDetailScreen extends StatefulWidget {
  const MaterialRequestDetailScreen({
    super.key,
    required this.materialRequestId,
    required this.repository,
  });

  final String materialRequestId;
  final MaterialRequestRepository repository;

  @override
  State<MaterialRequestDetailScreen> createState() =>
      _MaterialRequestDetailScreenState();
}

class _MaterialRequestDetailScreenState
    extends State<MaterialRequestDetailScreen> {
  MaterialRequest? _request;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  final _requestNumberController = TextEditingController();
  final _siteIdController = TextEditingController();
  final _projectIdController = TextEditingController();
  final _purposeController = TextEditingController();

  DateTime _requestDate = DateTime.now();
  DateTime? _requiredByDate;
  Priority _priority = Priority.normal;

  final List<_LineDraft> _lines = [];

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  @override
  void dispose() {
    _requestNumberController.dispose();
    _siteIdController.dispose();
    _projectIdController.dispose();
    _purposeController.dispose();

    for (final line in _lines) {
      line.dispose();
    }

    super.dispose();
  }

  Future<void> _loadRequest() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final request = await widget.repository.getById(
        widget.materialRequestId,
      );

      if (!mounted) {
        return;
      }

      _request = request;
      _requestNumberController.text = request.requestNumber;
      _siteIdController.text = request.constructionSiteId;
      _projectIdController.text = request.projectId ?? '';
      _purposeController.text = request.purpose ?? '';
      _requestDate = request.requestDate;
      _requiredByDate = request.requiredByDate;
      _priority = request.priority;

      for (final line in _lines) {
        line.dispose();
      }

      _lines.clear();

      for (final line in request.lines) {
        _lines.add(
          _LineDraft(
            id: line.id,
            materialId: line.materialId,
            quantity: line.requestedQuantity,
            remarks: line.remarks,
            approvedQuantity: line.approvedQuantity,
          ),
        );
      }

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

  bool get _canEdit {
    return _request?.status ==
        MaterialRequestStatus.draft;
  }

  bool get _canSubmit {
    return _request?.status ==
        MaterialRequestStatus.draft;
  }

  bool get _canApprove {
    final status = _request?.status;

    return status == MaterialRequestStatus.submitted;
  }

  bool get _canReject {
    final status = _request?.status;

    return status == MaterialRequestStatus.submitted;
  }

  bool get _canCancel {
    final status = _request?.status;

    return status == MaterialRequestStatus.draft ||
        status == MaterialRequestStatus.submitted;
  }

  Future<void> _save() async {
    if (_request == null || !_canEdit) {
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
      final materialId =
          line.materialIdController.text.trim();
      final quantity = double.tryParse(
        line.quantityController.text.trim(),
      );

      if (materialId.isEmpty ||
          quantity == null ||
          quantity <= 0) {
        _showMessage(
          'Every material line needs a valid material ID and quantity.',
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
      await widget.repository.update(
        materialRequestId: widget.materialRequestId,
        constructionSiteId:
            _siteIdController.text.trim(),
        projectId:
            _optionalValue(_projectIdController),
        requestNumber:
            _requestNumberController.text.trim(),
        requestDate: _requestDate,
        requiredByDate: _requiredByDate,
        purpose: _optionalValue(_purposeController),
        priority: _priority,
        lines: lines,
      );

      await _loadRequest();

      if (mounted) {
        _showMessage('Material request updated.');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      _showMessage(
        'Failed to update material request: $error',
      );
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit) {
      return;
    }

    final confirmed = await _confirm(
      title: 'Submit Request',
      message:
          'Submit this material request for approval?',
      confirmLabel: 'Submit',
    );

    if (!confirmed) {
      return;
    }

    await _runAction(
      action: () => widget.repository.submit(
        widget.materialRequestId,
      ),
      successMessage: 'Material request submitted.',
    );
  }

  Future<void> _approve() async {
    if (!_canApprove || _request == null) {
      return;
    }

    final lines = <MaterialRequestApprovalLine>[];

    for (final line in _lines) {
      final approvedQuantity = double.tryParse(
        line.approvedQuantityController.text.trim(),
      );

      if (approvedQuantity == null ||
          approvedQuantity < 0) {
        _showMessage(
          'Enter a valid approved quantity for every line.',
        );
        return;
      }

      lines.add(
        MaterialRequestApprovalLine(
          materialRequestLineId: line.id!,
          approvedQuantity: approvedQuantity,
        ),
      );
    }

    final remarks = await _requestRemarks(
      title: 'Approve Material Request',
      actionLabel: 'Approve',
    );

    if (remarks == null) {
      return;
    }

    await _runAction(
      action: () => widget.repository.approve(
        materialRequestId: widget.materialRequestId,
        remarks: remarks,
        lines: lines,
      ),
      successMessage: 'Material request approved.',
    );
  }

  Future<void> _reject() async {
    if (!_canReject) {
      return;
    }

    final remarks = await _requestRemarks(
      title: 'Reject Material Request',
      actionLabel: 'Reject',
      requireRemarks: true,
    );

    if (remarks == null) {
      return;
    }

    await _runAction(
      action: () => widget.repository.reject(
        materialRequestId: widget.materialRequestId,
        remarks: remarks,
      ),
      successMessage: 'Material request rejected.',
    );
  }

  Future<void> _cancel() async {
    if (!_canCancel) {
      return;
    }

    final remarks = await _requestRemarks(
      title: 'Cancel Material Request',
      actionLabel: 'Cancel',
    );

    if (remarks == null) {
      return;
    }

    await _runAction(
      action: () => widget.repository.cancel(
        materialRequestId: widget.materialRequestId,
        remarks: remarks,
      ),
      successMessage: 'Material request cancelled.',
    );
  }

  Future<void> _runAction({
    required Future<MaterialRequest> Function() action,
    required String successMessage,
  }) async {
    setState(() {
      _isSaving = true;
    });

    try {
      await action();

      if (!mounted) {
        return;
      }

      await _loadRequest();

      if (mounted) {
        _showMessage(successMessage);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      _showMessage(error.toString());
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  Future<String?> _requestRemarks({
    required String title,
    required String actionLabel,
    bool requireRemarks = false,
  }) async {
    return showDialog<String?>(
      context: context,
      builder: (context) {
        return _RemarksDialog(
          title: title,
          actionLabel: actionLabel,
          requireRemarks: requireRemarks,
        );
      },
    );
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

  void _addLine() {
    if (!_canEdit) {
      return;
    }

    setState(() {
      _lines.add(_LineDraft());
    });
  }

  void _removeLine(int index) {
    if (!_canEdit || _lines.length == 1) {
      return;
    }

    final line = _lines.removeAt(index);
    line.dispose();

    setState(() {});
  }

  String _statusLabel(MaterialRequestStatus status) {
    switch (status) {
      case MaterialRequestStatus.draft:
        return 'Draft';
      case MaterialRequestStatus.submitted:
        return 'Submitted';
      case MaterialRequestStatus.approved:
        return 'Approved';
      case MaterialRequestStatus.partiallyApproved:
        return 'Partially Approved';
      case MaterialRequestStatus.rejected:
        return 'Rejected';
      case MaterialRequestStatus.ordered:
        return 'Ordered';
      case MaterialRequestStatus.partiallyDelivered:
        return 'Partially Delivered';
      case MaterialRequestStatus.delivered:
        return 'Delivered';
      case MaterialRequestStatus.cancelled:
        return 'Cancelled';
    }
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
        title: Text(
          _request?.requestNumber ??
              'Material Request',
        ),
        actions: [
          if (_canEdit)
            IconButton(
              tooltip: 'Save Changes',
              onPressed: _isSaving ? null : _save,
              icon: const Icon(Icons.save_outlined),
            ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isSaving ? null : _loadRequest,
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
                onPressed: _loadRequest,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final request = _request!;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _InfoRow(
                  label: 'Status',
                  value: _statusLabel(request.status),
                ),
                _InfoRow(
                  label: 'Site',
                  value: request.siteName,
                ),
                if (request.projectName != null)
                  _InfoRow(
                    label: 'Project',
                    value: request.projectName!,
                  ),
                _InfoRow(
                  label: 'Priority',
                  value: _priorityLabel(request.priority),
                ),
                _InfoRow(
                  label: 'Request Date',
                  value: _formatDate(
                    request.requestDate,
                  ),
                ),
                if (request.requiredByDate != null)
                  _InfoRow(
                    label: 'Required By',
                    value: _formatDate(
                      request.requiredByDate!,
                    ),
                  ),
                if (request.approvalRemarks != null)
                  _InfoRow(
                    label: 'Approval Remarks',
                    value: request.approvalRemarks!,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_canEdit) ...[
          TextFormField(
            controller: _requestNumberController,
            decoration: const InputDecoration(
              labelText: 'Request Number',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _siteIdController,
            decoration: const InputDecoration(
              labelText: 'Construction Site ID',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _projectIdController,
            decoration: const InputDecoration(
              labelText: 'Project ID',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Priority>(
            initialValue: _priority,
            decoration: const InputDecoration(
              labelText: 'Priority',
            ),
            items: Priority.values
                .map(
                  (priority) =>
                      DropdownMenuItem<Priority>(
                    value: priority,
                    child: Text(
                      _priorityLabel(priority),
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
            controller: _purposeController,
            decoration: const InputDecoration(
              labelText: 'Purpose',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
        ],
        Text(
          'Material Lines',
          style: Theme.of(context)
              .textTheme
              .titleLarge,
        ),
        const SizedBox(height: 12),
        ..._lines.asMap().entries.map(
          (entry) {
            return _LineCard(
              index: entry.key,
              line: entry.value,
              editable: _canEdit,
              approvalMode: _canApprove,
              canRemove: _lines.length > 1,
              onRemove: () =>
                  _removeLine(entry.key),
            );
          },
        ),
        if (_canEdit) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _isSaving ? null : _addLine,
            icon: const Icon(Icons.add),
            label: const Text('Add Material Line'),
          ),
        ],
        const SizedBox(height: 24),
        _buildActions(context),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (_canEdit)
          FilledButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save Changes'),
          ),
        if (_canSubmit)
          FilledButton.icon(
            onPressed: _isSaving ? null : _submit,
            icon: const Icon(Icons.send_outlined),
            label: const Text('Submit'),
          ),
        if (_canApprove)
          FilledButton.icon(
            onPressed: _isSaving ? null : _approve,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Approve'),
          ),
        if (_canReject)
          OutlinedButton.icon(
            onPressed: _isSaving ? null : _reject,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Reject'),
          ),
        if (_canCancel)
          OutlinedButton.icon(
            onPressed: _isSaving ? null : _cancel,
            icon: const Icon(Icons.block_outlined),
            label: const Text('Cancel Request'),
          ),
      ],
    );
  }
}

class _RemarksDialog extends StatefulWidget {
  const _RemarksDialog({
    required this.title,
    required this.actionLabel,
    required this.requireRemarks,
  });

  final String title;
  final String actionLabel;
  final bool requireRemarks;

  @override
  State<_RemarksDialog> createState() => _RemarksDialogState();
}

class _RemarksDialogState extends State<_RemarksDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();

    if (widget.requireRemarks && value.isEmpty) {
      return;
    }

    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 4,
        decoration: InputDecoration(
          labelText:
              widget.requireRemarks ? 'Remarks *' : 'Remarks',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}
class _LineDraft {
  _LineDraft({
    this.id,
    String? materialId,
    double? quantity,
    String? remarks,
    double? approvedQuantity,
  }) {
    if (materialId != null) {
      materialIdController.text = materialId;
    }

    if (quantity != null) {
      quantityController.text = quantity.toString();
    }

    if (remarks != null) {
      remarksController.text = remarks;
    }

    if (approvedQuantity != null) {
      approvedQuantityController.text =
          approvedQuantity.toString();
    }
  }
  final String? id;

  final materialIdController = TextEditingController();
  final quantityController = TextEditingController();
  final remarksController = TextEditingController();
  final approvedQuantityController =
      TextEditingController();
void dispose() {
    materialIdController.dispose();
    quantityController.dispose();
    remarksController.dispose();
    approvedQuantityController.dispose();
  }
}

class _LineCard extends StatelessWidget {
  const _LineCard({
    required this.index,
    required this.line,
    required this.editable,
    required this.approvalMode,
    required this.canRemove,
    required this.onRemove,
  });

  final int index;
  final _LineDraft line;
  final bool editable;
  final bool approvalMode;
  final bool canRemove;
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
                if (editable)
                  IconButton(
                    tooltip: 'Remove line',
                    onPressed:
                        canRemove ? onRemove : null,
                    icon: const Icon(
                      Icons.delete_outline,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: line.materialIdController,
              enabled: editable,
              decoration: const InputDecoration(
                labelText: 'Material ID',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: line.quantityController,
              enabled: editable,
              decoration: const InputDecoration(
                labelText: 'Requested Quantity',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            if (approvalMode) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller:
                    line.approvedQuantityController,
                decoration: const InputDecoration(
                  labelText: 'Approved Quantity',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: line.remarksController,
              enabled: editable,
              decoration: const InputDecoration(
                labelText: 'Remarks',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge,
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}





