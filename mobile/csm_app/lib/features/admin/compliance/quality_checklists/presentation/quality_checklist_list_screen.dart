import 'package:flutter/material.dart';
import 'package:csm_app/core/network/api_client.dart';

import '../data/quality_checklist.dart';
import '../data/quality_checklist_repository.dart';
import 'create_quality_checklist_screen.dart';
import 'quality_checklist_details_screen.dart';

class QualityChecklistListScreen extends StatefulWidget {
  const QualityChecklistListScreen({super.key});

  @override
  State<QualityChecklistListScreen> createState() =>
      _QualityChecklistListScreenState();
}

class _QualityChecklistListScreenState
    extends State<QualityChecklistListScreen> {
  late final QualityChecklistRepository _repository;

  List<QualityChecklist> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = QualityChecklistRepository(ApiClient());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _repository.getAll();

      if (!mounted) return;

      setState(() => _items = data);
    } catch (e) {
      if (!mounted) return;

      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quality Checklists'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateQualityChecklistScreen(),
            ),
          );

          if (created == true && mounted) {
            await _load();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(_error!),
      ))
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: _items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = _items[index];

            return Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          QualityChecklistDetailsScreen(
                            checklistId: item.id,
                          ),
                    ),
                  );

                  if (mounted) await _load();
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding:
                            const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _categoryColor(
                                item.category,
                              ).withValues(alpha: 0.15),
                              borderRadius:
                              BorderRadius.circular(12),
                            ),
                            child: Text(
                              item.category,
                              style: TextStyle(
                                color: _categoryColor(
                                  item.category,
                                ),
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.constructionSiteName,
                              style: TextStyle(
                                color:
                                Colors.grey.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      if (item.description != null)
                        Text(
                          item.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Icon(
                            Icons.checklist,
                            size: 18,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.items.length} Items',
                            style: TextStyle(
                              color:
                              Colors.grey.shade700,
                            ),
                          ),
                          const Spacer(),
                          Chip(
                            label: Text(
                              item.isActive
                                  ? 'Active'
                                  : 'Inactive',
                            ),
                            backgroundColor: item.isActive
                                ? Colors.green.withValues(
                                alpha: 0.15)
                                : Colors.grey.withValues(
                                alpha: 0.15),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}