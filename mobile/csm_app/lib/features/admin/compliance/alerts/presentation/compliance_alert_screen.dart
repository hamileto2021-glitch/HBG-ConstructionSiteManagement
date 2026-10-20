import 'package:flutter/material.dart';

import '../data/models/compliance_alert.dart';
import '../data/repositories/compliance_alert_repository.dart';

class ComplianceAlertScreen extends StatefulWidget {
  const ComplianceAlertScreen({super.key});

  @override
  State<ComplianceAlertScreen> createState() =>
      _ComplianceAlertScreenState();
}

class _ComplianceAlertScreenState
    extends State<ComplianceAlertScreen> {
  final _repo = ComplianceAlertRepository();

  List<ComplianceAlert> _alerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _repo.getAll();

    if (!mounted) return;

    setState(() {
      _alerts = data;
      _loading = false;
    });
  }

  Color _color(ComplianceAlert a) {
    if (a.isExpired) return Colors.red;
    if (a.daysRemaining <= 7) return Colors.orange;
    return Colors.amber;
  }

  String _label(ComplianceAlert a) {
    if (a.isExpired) return 'Expired';
    if (a.daysRemaining <= 7) return 'Critical';
    return 'Upcoming';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expiry Alerts')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          itemCount: _alerts.length,
          itemBuilder: (_, i) {
            final a = _alerts[i];

            return Card(
              margin: const EdgeInsets.all(10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _color(a),
                  child: const Icon(Icons.warning,
                      color: Colors.white),
                ),
                title: Text(a.permitNumber),
                subtitle: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(a.siteName),
                    Text(a.permitHolder),
                    Text(
                      'Expiry: '
                          '${a.expiryDate.day}/${a.expiryDate.month}/${a.expiryDate.year}',
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    Text(
                      _label(a),
                      style: TextStyle(
                        color: _color(a),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('${a.daysRemaining} d'),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}