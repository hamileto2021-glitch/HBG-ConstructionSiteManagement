import 'package:flutter/material.dart';

import '../data/models/site.dart';
import '../data/repositories/site_repository.dart';
import 'site_edit_screen.dart';

class SiteDetailScreen extends StatefulWidget {
  const SiteDetailScreen({
    super.key,
    required this.siteId,
    required this.repository,
  });

  final String siteId;
  final SiteRepository repository;

  @override
  State<SiteDetailScreen> createState() =>
      _SiteDetailScreenState();
}

class _SiteDetailScreenState
    extends State<SiteDetailScreen> {
  Site? _site;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      _site = await widget.repository.getById(widget.siteId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Color _statusColor(SiteStatus status) {
    switch (status) {
      case SiteStatus.planning:
        return Colors.orange;
      case SiteStatus.active:
        return Colors.green;
      case SiteStatus.onHold:
        return Colors.deepOrange;
      case SiteStatus.completed:
        return Colors.blue;
      case SiteStatus.closed:
        return Colors.grey;
    }
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final site = _site;

    if (site == null) {
      return const Scaffold(
        body: Center(child: Text('Site not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(site.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    child: Text(site.siteCode),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    site.name,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(site.status.displayName),
                    backgroundColor:
                    _statusColor(site.status),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _row('Code', site.siteCode),
                  _row(
                    'Address',
                    site.address ?? '-',
                  ),
                  _row('City', site.city ?? '-'),
                  _row(
                    'Region',
                    site.region ?? '-',
                  ),
                  _row(
                    'Country',
                    site.country ?? '-',
                  ),
                  _row(
                    'Latitude',
                    site.latitude?.toString() ?? '-',
                  ),
                  _row(
                    'Longitude',
                    site.longitude?.toString() ?? '-',
                  ),
                  _row(
                    'Geofence',
                    site.geofenceRadiusMeters != null
                        ? '${site.geofenceRadiusMeters} m'
                        : '-',
                  ),
                  _row(
                    'Description',
                    site.description ?? '-',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () async {
              final updated =
              await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => SiteEditScreen(
                    site: site,
                    repository: widget.repository,
                  ),
                ),
              );

              if (updated == true) {
                _load();
              }
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Site'),
          ),
        ],
      ),
    );
  }
}