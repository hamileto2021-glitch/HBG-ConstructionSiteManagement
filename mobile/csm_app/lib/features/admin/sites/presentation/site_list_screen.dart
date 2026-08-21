import 'package:flutter/material.dart';

import '../data/models/site.dart';
import '../data/repositories/site_repository.dart';
import 'site_create_screen.dart';
import 'site_detail_screen.dart';

class SiteListScreen extends StatefulWidget {
  const SiteListScreen({
    super.key,
    required this.repository,
  });

  final SiteRepository repository;

  @override
  State<SiteListScreen> createState() =>
      _SiteListScreenState();
}

class _SiteListScreenState
    extends State<SiteListScreen> {
  final _search = TextEditingController();

  List<Site> _sites = [];
  List<Site> _filtered = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final data = await widget.repository.getAll();

      _sites = data;
      _filtered = data;
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

  void _filter(String value) {
    final query = value.toLowerCase();

    setState(() {
      _filtered = _sites.where((site) {
        return site.name
            .toLowerCase()
            .contains(query) ||
            site.siteCode
                .toLowerCase()
                .contains(query) ||
            (site.city ?? '')
                .toLowerCase()
                .contains(query);
      }).toList();
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created =
          await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => SiteCreateScreen(
                repository: widget.repository,
              ),
            ),
          );

          if (created == true) {
            _load();
          }
        },
        icon: const Icon(Icons.add_business),
        label: const Text('New Site'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              onChanged: _filter,
              decoration: const InputDecoration(
                hintText: 'Search sites...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
              child:
              CircularProgressIndicator(),
            )
                : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final site = _filtered[index];

                  return Card(
                    margin:
                    const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SiteDetailScreen(
                              siteId: site.id,
                              repository: widget.repository,
                            ),
                          ),
                        );

                        _load();
                      },
                      leading: CircleAvatar(
                        child: Text(
                          site.siteCode.length >= 2
                              ? site.siteCode.substring(0, 2)
                              : site.siteCode,
                        ),
                      ),
                      title: Text(site.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(site.siteCode),
                          if (site.city != null) Text(site.city!),
                          const SizedBox(height: 4),
                          Chip(
                            label: Text(site.status.displayName),
                            backgroundColor: _statusColor(site.status),
                          ),
                        ],
                      ),
                      trailing: Icon(
                        site.isActive
                            ? Icons.chevron_right
                            : Icons.cancel,
                        color: site.isActive ? Colors.green : Colors.red,
                      ),
                    )
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}