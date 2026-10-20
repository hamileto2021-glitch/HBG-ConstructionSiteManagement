import 'package:flutter/material.dart';

import '../data/safety_incident.dart';
import '../data/safety_incident_repository.dart';
import 'create_safety_incident_screen.dart';
import 'safety_incident_details_screen.dart';

class SafetyIncidentListScreen extends StatefulWidget {
  const SafetyIncidentListScreen({
    super.key,
    required this.repository,
  });

  final SafetyIncidentRepository repository;

  @override
  State<SafetyIncidentListScreen> createState() =>
      _SafetyIncidentListScreenState();
}

class _SafetyIncidentListScreenState
    extends State<SafetyIncidentListScreen> {
  bool _isLoading = true;
  String? _error;
  List<SafetyIncident> _incidents = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await widget.repository.getAll();

      if (!mounted) return;

      setState(() {
        _incidents = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'fatal':
        return Colors.red.shade900;

      case 'critical':
        return Colors.red;

      case 'serious':
        return Colors.deepOrange;

      case 'moderate':
        return Colors.orange;

      case 'minor':
        return Colors.green;

      case 'nearmiss':
      case 'near miss':
        return Colors.blue;

      default:
        return Colors.grey;
    }
  }

  IconData _severityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'fatal':
      case 'critical':
        return Icons.warning_amber_rounded;

      case 'serious':
        return Icons.error_outline;

      case 'moderate':
        return Icons.warning;

      case 'minor':
        return Icons.info_outline;

      case 'nearmiss':
      case 'near miss':
        return Icons.visibility;

      default:
        return Icons.warning;
    }
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'underinvestigation':
        return 'Under Investigation';

      case 'correctiveactionrequired':
        return 'Corrective Action Required';

      default:
        return status;
    }
  }

  Future<void> _openDetails(
      SafetyIncident incident,
      ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SafetyIncidentDetailsScreen(
          incidentId: incident.id,
          repository: widget.repository,
        ),
      ),
    );

    if (!mounted) return;

    await _load();
  }

  Future<void> _createIncident() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateSafetyIncidentScreen(
          repository: widget.repository,
        ),
      ),
    );

    if (!mounted) return;

    if (created == true) {
      await _load();
    }
  }

  Widget _buildIncidentCard(
      SafetyIncident incident,
      ) {
    final severityColor =
    _severityColor(incident.severity);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 5,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDetails(incident),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            14,
            12,
            10,
            12,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: severityColor,
                child: Icon(
                  _severityIcon(incident.severity),
                  color: Colors.white,
                  size: 25,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      incident.constructionSiteName.trim().isEmpty
                          ? 'Unknown Site'
                          : incident.constructionSiteName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      incident.incidentNumber,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),

                    const SizedBox(height: 3),



                    Text(
                      _formatDate(
                        incident.occurredAtUtc,
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Wrap(
                      spacing: 7,
                      runSpacing: 5,
                      children: [
                        Container(
                          padding:
                          const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: severityColor
                                .withValues(
                              alpha: 0.12,
                            ),
                            borderRadius:
                            BorderRadius.circular(9),
                            border: Border.all(
                              color: severityColor
                                  .withValues(
                                alpha: 0.28,
                              ),
                            ),
                          ),
                          child: Text(
                            incident.severity,
                            style: TextStyle(
                              color: severityColor,
                              fontSize: 12,
                              fontWeight:
                              FontWeight.w600,
                            ),
                          ),
                        ),

                        Container(
                          padding:
                          const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey
                                .withValues(
                              alpha: 0.10,
                            ),
                            borderRadius:
                            BorderRadius.circular(9),
                          ),
                          child: Text(
                            _statusLabel(
                              incident.status,
                            ),
                            style: TextStyle(
                              color:
                              Colors.grey.shade800,
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

              const SizedBox(width: 4),

              Icon(
                Icons.chevron_right,
                size: 28,
                color: Colors.grey.shade700,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics:
      const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 140),
        Center(
          child: Text(
            'No safety incidents found.',
            style: TextStyle(fontSize: 17),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Incidents'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: Builder(
          builder: (_) {
            if (_isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (_error != null) {
              return ListView(
                physics:
                const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!),
                  ),
                ],
              );
            }

            if (_incidents.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.only(
                top: 8,
                bottom: 100,
              ),
              itemCount: _incidents.length,
              itemBuilder: (context, index) {
                return _buildIncidentCard(
                  _incidents[index],
                );
              },
            );
          },
        ),
      ),
      floatingActionButton:
      FloatingActionButton(
        onPressed: _createIncident,
        child: const Icon(Icons.add),
      ),
    );
  }
}