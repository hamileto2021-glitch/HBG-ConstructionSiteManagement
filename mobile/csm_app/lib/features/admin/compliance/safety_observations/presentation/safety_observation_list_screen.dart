import 'package:flutter/material.dart';

import '../../../../../core/network/api_client.dart';
import '../data/safety_observation.dart';
import '../data/safety_observation_repository.dart';
import 'create_safety_observation_screen.dart';
import 'safety_observation_details_screen.dart';

class SafetyObservationListScreen extends StatefulWidget {
  const SafetyObservationListScreen({super.key});

  @override
  State<SafetyObservationListScreen> createState() =>
      _SafetyObservationListScreenState();
}

class _SafetyObservationListScreenState
    extends State<SafetyObservationListScreen> {
  late final SafetyObservationRepository _repository;

  List<SafetyObservation> _items = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    _repository = SafetyObservationRepository(ApiClient());

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

      setState(() {
        _items = data;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Color _riskColor(String risk) {
    switch (risk) {
      case 'Critical':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return Colors.amber;
      default:
        return Colors.green;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Closed':
        return Colors.green;
      case 'InProgress':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime value) {
    final d = value.toLocal();

    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Observations'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateSafetyObservationScreen(),
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
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _error != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!),
        ),
      )
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: _items.length,
          separatorBuilder: (_, _) =>
          const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = _items[index];

            return Card(
              elevation: 1,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SafetyObservationDetailsScreen(
                            observationId: item.id,
                          ),
                    ),
                  );

                  if (mounted) {
                    await _load();
                  }
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
                              item.constructionSiteName,
                              maxLines: 1,
                              overflow:
                              TextOverflow.ellipsis,
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
                              color: _riskColor(
                                item.riskLevel,
                              ).withValues(alpha: 0.15),
                              borderRadius:
                              BorderRadius.circular(12),
                            ),
                            child: Text(
                              item.riskLevel,
                              style: TextStyle(
                                color: _riskColor(
                                  item.riskLevel,
                                ),
                                fontSize: 12,
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.observationNumber,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 15,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(
                              item.observationDate,
                            ),
                            style: TextStyle(
                              color:
                              Colors.grey.shade700,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding:
                            const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(
                                item.status,
                              ).withValues(alpha: 0.15),
                              borderRadius:
                              BorderRadius.circular(12),
                            ),
                            child: Text(
                              item.status,
                              style: TextStyle(
                                color: _statusColor(
                                  item.status,
                                ),
                                fontSize: 12,
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),
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