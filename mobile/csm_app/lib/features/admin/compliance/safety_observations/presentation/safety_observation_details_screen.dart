import 'package:flutter/material.dart';

import '../../../../../core/network/api_client.dart';
import '../data/safety_observation.dart';
import '../data/safety_observation_repository.dart';
import 'edit_safety_observation_screen.dart';

class SafetyObservationDetailsScreen extends StatefulWidget {
  const SafetyObservationDetailsScreen({
    super.key,
    required this.observationId,
  });

  final String observationId;

  @override
  State<SafetyObservationDetailsScreen> createState() =>
      _SafetyObservationDetailsScreenState();
}

class _SafetyObservationDetailsScreenState
    extends State<SafetyObservationDetailsScreen> {
  late final SafetyObservationRepository _repository;

  SafetyObservation? _observation;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = SafetyObservationRepository(ApiClient());
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _repository.getById(widget.observationId);

      if (!mounted) return;

      setState(() {
        _observation = data;
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

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year}';

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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Safety Observation')),
        body: Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!),
        )),
      );
    }

    final o = _observation!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Observation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => EditSafetyObservationScreen(
                    observation: o,
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
            o.constructionSiteName,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            o.observationNumber,
            style: Theme.of(context).textTheme.titleMedium,
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Chip(label: Text(o.status)),
              const SizedBox(width: 8),
              Chip(
                backgroundColor: _riskColor(o.riskLevel).withValues(alpha: 0.15),
                label: Text(
                  o.riskLevel,
                  style: TextStyle(color: _riskColor(o.riskLevel)),
                ),
              ),
            ],
          ),

          const Divider(height: 32),

          _tile('Date', _date(o.observationDate)),
          _tile('Category', o.category),
          _tile('Location', o.location),
          _tile('Observer', o.observerName),
          if (o.employeeName != null)
            _tile('Employee', o.employeeName!),

          const SizedBox(height: 20),

          Text(
            'Description',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(o.description),

          if (o.immediateAction != null) ...[
            const SizedBox(height: 20),
            Text(
              'Immediate Action',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(o.immediateAction!),
          ],

          if (o.recommendedAction != null) ...[
            const SizedBox(height: 20),
            Text(
              'Recommended Action',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(o.recommendedAction!),
          ],

          const SizedBox(height: 24),

          Row(
            children: [
              const Icon(Icons.thumb_up_alt_outlined),
              const SizedBox(width: 8),
              Text(
                o.positiveObservation
                    ? 'Positive Observation'
                    : 'Improvement Required',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              )),
          const SizedBox(height: 2),
          Text(value),
        ],
      ),
    );
  }
}