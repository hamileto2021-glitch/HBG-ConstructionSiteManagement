import 'package:flutter/material.dart';

import '../data/work_permit.dart';
import '../data/work_permit_repository.dart';

import 'edit_work_permit_screen.dart';

class WorkPermitDetailsScreen extends StatefulWidget {
  const WorkPermitDetailsScreen({
    super.key,
    required this.permitId,
    required this.repository,
  });

  final String permitId;
  final WorkPermitRepository repository;

  @override
  State<WorkPermitDetailsScreen> createState() =>
      _WorkPermitDetailsScreenState();
}

class _WorkPermitDetailsScreenState
    extends State<WorkPermitDetailsScreen> {
  WorkPermit? _permit;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final permit = await widget.repository.getById(widget.permitId);

      if (!mounted) return;

      setState(() {
        _permit = permit;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'issued':
        return Colors.blue;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';

    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Work Permit')),
        body: Center(child: Text(_error!)),
      );
    }

    final permit = _permit!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Permit Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditWorkPermitScreen(
                    repository: widget.repository,
                    permit: permit,
                  ),
                ),
              );

              _load();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    permit.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(permit.permitNumber),
                  const SizedBox(height: 12),
                  Chip(
                    label: Text(permit.status),
                    backgroundColor:
                    _statusColor(permit.status).withValues(alpha: 0.15),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Permit Information',
            children: [
              _InfoRow('Construction Site', permit.constructionSiteName),
              _InfoRow('Permit Type', permit.permitType),
              _InfoRow('Status', permit.status),
              _InfoRow('Issued By', permit.issuedBy),
            ],
          ),
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Validity',
            children: [
              _InfoRow(
                'Application Date',
                _formatDate(permit.applicationDate),
              ),
              _InfoRow(
                'Issue Date',
                _formatDate(permit.issueDate),
              ),
              _InfoRow(
                'Expiry Date',
                _formatDate(permit.expiryDate),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}