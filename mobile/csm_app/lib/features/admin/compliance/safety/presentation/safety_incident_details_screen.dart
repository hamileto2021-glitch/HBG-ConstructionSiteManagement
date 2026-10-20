import 'package:flutter/material.dart';

import '../data/safety_incident.dart';
import '../data/safety_incident_repository.dart';
import 'edit_safety_incident_screen.dart';

class SafetyIncidentDetailsScreen extends StatefulWidget {
  const SafetyIncidentDetailsScreen({
    super.key,
    required this.incidentId,
    required this.repository,
  });

  final String incidentId;
  final SafetyIncidentRepository repository;

  @override
  State<SafetyIncidentDetailsScreen> createState() =>
      _SafetyIncidentDetailsScreenState();
}

class _SafetyIncidentDetailsScreenState
    extends State<SafetyIncidentDetailsScreen> {
  SafetyIncident? _incident;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data =
      await widget.repository.getById(
        widget.incidentId,
      );

      if (!mounted) return;

      setState(() {
        _incident = data;
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

  String _formatDateTime(DateTime? date) {
    if (date == null) {
      return '-';
    }

    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildBadge(
      String text,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.12,
        ),
        borderRadius:
        BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(
            alpha: 0.28,
          ),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildBooleanRow(
      String label,
      bool value,
      ) {
    return _InfoRow(
      label,
      value ? 'Yes' : 'No',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Safety Incident',
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_error!),
          ),
        ),
      );
    }

    final incident = _incident;

    if (incident == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Safety incident not found.',
          ),
        ),
      );
    }

    final severityColor =
    _severityColor(incident.severity);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Safety Incident',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => EditSafetyIncidentScreen(
                    incident: incident,
                    repository: widget.repository,
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
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(16),
              ),
              child: Padding(
                padding:
                const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      incident.locationDescription
                          .trim()
                          .isEmpty
                          ? 'Safety Incident'
                          : incident.locationDescription,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge,
                    ),

                    const SizedBox(height: 7),

                    Text(
                      incident.incidentNumber,
                      style: TextStyle(
                        color:
                        Colors.grey.shade700,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildBadge(
                          incident.severity,
                          severityColor,
                        ),
                        _buildBadge(
                          _statusLabel(
                            incident.status,
                          ),
                          Colors.blueGrey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            _InfoCard(
              title: 'Incident Information',
              children: [
                _InfoRow(
                  'Construction Site',
                  incident
                      .constructionSiteName,
                ),
                _InfoRow(
                  'Occurred',
                  _formatDateTime(
                    incident.occurredAtUtc,
                  ),
                ),
                _InfoRow(
                  'Reported',
                  _formatDateTime(
                    incident.reportedAtUtc,
                  ),
                ),
                _InfoRow(
                  'Status',
                  _statusLabel(
                    incident.status,
                  ),
                ),
                _InfoRow(
                  'Severity',
                  incident.severity,
                ),
                _InfoRow(
                  'Location',
                  incident
                      .locationDescription,
                ),
              ],
            ),

            const SizedBox(height: 16),

            _InfoCard(
              title: 'Incident Description',
              children: [
                Text(
                  incident.description,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _InfoCard(
              title: 'Injury Information',
              children: [
                _buildBooleanRow(
                  'Injury Occurred',
                  incident.injuryOccurred,
                ),
                _buildBooleanRow(
                  'Medical Treatment',
                  incident
                      .medicalTreatmentRequired,
                ),
                _buildBooleanRow(
                  'Lost Time Incident',
                  incident.lostTimeIncident,
                ),
              ],
            ),

            if (incident.immediateActionTaken !=
                null) ...[
              const SizedBox(height: 16),
              _InfoCard(
                title: 'Immediate Action',
                children: [
                  Text(
                    incident
                        .immediateActionTaken!,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ],

            if (incident.rootCause != null) ...[
              const SizedBox(height: 16),
              _InfoCard(
                title: 'Root Cause',
                children: [
                  Text(
                    incident.rootCause!,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ],

            if (incident.correctiveAction !=
                null) ...[
              const SizedBox(height: 16),
              _InfoCard(
                title: 'Corrective Action',
                children: [
                  Text(
                    incident.correctiveAction!,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ],

            if (incident
                .investigationCompletedAtUtc !=
                null) ...[
              const SizedBox(height: 16),
              _InfoCard(
                title: 'Investigation',
                children: [
                  _InfoRow(
                    'Investigator',
                    incident.investigatedBy ??
                        '-',
                  ),
                  _InfoRow(
                    'Completed',
                    _formatDateTime(
                      incident
                          .investigationCompletedAtUtc,
                    ),
                  ),
                ],
              ),
            ],

            if (incident.closedAtUtc !=
                null) ...[
              const SizedBox(height: 16),
              _InfoCard(
                title: 'Closure',
                children: [
                  _InfoRow(
                    'Closed At',
                    _formatDateTime(
                      incident.closedAtUtc,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
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
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                fontWeight:
                FontWeight.w600,
              ),
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
  const _InfoRow(
      this.label,
      this.value,
      );

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 135,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight:
                FontWeight.w600,
              ),
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