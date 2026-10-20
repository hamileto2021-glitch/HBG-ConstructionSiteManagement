import 'package:flutter/material.dart';
import 'package:csm_app/core/network/api_client.dart';

import '../data/quality_checklist.dart';
import '../data/quality_checklist_repository.dart';
import 'edit_quality_checklist_screen.dart';


class QualityChecklistDetailsScreen extends StatefulWidget {
  const QualityChecklistDetailsScreen({
    super.key,
    required this.checklistId,
  });

  final String checklistId;

  @override
  State<QualityChecklistDetailsScreen> createState() =>
      _QualityChecklistDetailsScreenState();
}

class _QualityChecklistDetailsScreenState
    extends State<QualityChecklistDetailsScreen> {
  late final QualityChecklistRepository _repository;

  QualityChecklist? _checklist;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = QualityChecklistRepository(ApiClient());
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _repository.getById(widget.checklistId);

      if (!mounted) return;

      setState(() {
        _checklist = data;
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

  Color _categoryColor(String category) {
    switch (category) {
      case 'Concrete':
        return Colors.brown;
      case 'Rebar':
        return Colors.blue;
      case 'Masonry':
        return Colors.orange;
      case 'Finishing':
        return Colors.purple;
      default:
        return Colors.teal;
    }
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
        appBar: AppBar(title: const Text('Checklist')),
        body: Center(child: Text(_error!)),
      );
    }

    final c = _checklist!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quality Checklist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => EditQualityChecklistScreen(
                    checklist: c,
                  ),
                ),
              );

              if (updated == true && mounted) {
                await _load();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            c.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),

          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: Colors.grey,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  c.constructionSiteName,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Chip(
            label: Text(c.category),
            backgroundColor:
            _categoryColor(c.category).withValues(alpha: 0.15),
          ),

          if (c.description != null) ...[
            const SizedBox(height: 16),
            Text(c.description!),
          ],

          const SizedBox(height: 24),

          Row(
            children: [
              const Icon(Icons.checklist),
              const SizedBox(width: 8),
              Text(
                '${c.items.length} Inspection Items',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),

          const SizedBox(height: 12),

          ...c.items.map(
                (item) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(item.sequence.toString()),
                ),
                title: Text(item.requirement),
                subtitle: Text(
                  item.isMandatory ? 'Mandatory' : 'Optional',
                ),
                trailing: Icon(
                  item.isMandatory
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: item.isMandatory
                      ? Colors.green
                      : Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}