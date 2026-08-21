import 'package:flutter/material.dart';

import '../data/models/material_request.dart';
import '../data/repositories/material_request_repository.dart';
import 'material_request_create_screen.dart';
import 'material_request_detail_screen.dart';

class MaterialRequestListScreen extends StatefulWidget {
  const MaterialRequestListScreen({
    super.key,
    required this.repository,
  });

  final MaterialRequestRepository repository;

  @override
  State<MaterialRequestListScreen> createState() =>
      _MaterialRequestListScreenState();
}

class _MaterialRequestListScreenState
    extends State<MaterialRequestListScreen> {
  final List<MaterialRequest> _requests = [];

  bool _isLoading = true;
  MaterialRequestStatus? _statusFilter;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final requests = await widget.repository.getAll(
        status: _statusFilter,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _requests
          ..clear()
          ..addAll(requests);
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

  Future<void> _openCreateScreen() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MaterialRequestCreateScreen(
          repository: widget.repository,
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadRequests();
    }
  }

  Future<void> _openDetailScreen(
    MaterialRequest request,
  ) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MaterialRequestDetailScreen(
          materialRequestId: request.id,
          repository: widget.repository,
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadRequests();
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Material Requests'),
        actions: [
          PopupMenuButton<MaterialRequestStatus?>(
            tooltip: 'Filter by status',
            initialValue: _statusFilter,
            onSelected: (value) {
              setState(() {
                _statusFilter = value;
              });
              _loadRequests();
            },
            itemBuilder: (_) => [
              const PopupMenuItem<MaterialRequestStatus?>(
                value: null,
                child: Text('All'),
              ),
              ...MaterialRequestStatus.values.map(
                (status) =>
                    PopupMenuItem<MaterialRequestStatus?>(
                  value: status,
                  child: Text(_statusLabel(status)),
                ),
              ),
            ],
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            tooltip: 'Create Material Request',
            onPressed:
                _isLoading ? null : _openCreateScreen,
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                _isLoading ? null : _loadRequests,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRequests,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading && _requests.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 300),
          Center(
            child: CircularProgressIndicator(),
          ),
        ],
      );
    }

    if (_error != null && _requests.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 220),
          Center(
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
                    onPressed: _loadRequests,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_requests.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 220),
          Center(
            child: Text('No material requests found.'),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final request = _requests[index];

        return _MaterialRequestCard(
          request: request,
          statusLabel: _statusLabel(request.status),
          priorityLabel: _priorityLabel(request.priority),
          onTap: () => _openDetailScreen(request),
        );
      },
    );
  }
}

class _MaterialRequestCard extends StatelessWidget {
  const _MaterialRequestCard({
    required this.request,
    required this.statusLabel,
    required this.priorityLabel,
    required this.onTap,
  });

  final MaterialRequest request;
  final String statusLabel;
  final String priorityLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.request_quote_outlined,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      request.requestNumber,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge,
                    ),
                  ),
                  Chip(
                    label: Text(statusLabel),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
                label: 'Date',
                value: request.requestDate
                    .toLocal()
                    .toString()
                    .split(' ')
                    .first,
              ),
              _InfoRow(
                label: 'Priority',
                value: priorityLabel,
              ),
              _InfoRow(
                label: 'Lines',
                value: request.lines.length.toString(),
              ),
            ],
          ),
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
            width: 90,
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
