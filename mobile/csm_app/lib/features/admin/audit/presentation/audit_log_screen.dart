import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models/audit_log.dart';
import '../data/repositories/audit_repository.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({
    super.key,
    required this.repository,
  });

  final AuditRepository repository;

  @override
  State<AuditLogScreen> createState() =>
      _AuditLogScreenState();
}

class _AuditLogScreenState
    extends State<AuditLogScreen> {
  final List<String> modules = [
    'All',
    'HRM',
    'Payroll',
    'Inventory',
    'Projects',
    'Company',
    'Backup',
  ];

  String selected = 'All';

  List<AuditLog> logs = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);

    logs = await widget.repository.getLogs(
      module: selected == 'All' ? null : selected,
    );

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Log'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              initialValue: selected,
              items: modules
                  .map(
                    (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e),
                ),
              )
                  .toList(),
              onChanged: (value) {
                selected = value!;
                load();
              },
            ),
          ),
          Expanded(
            child: loading
                ? const Center(
              child:
              CircularProgressIndicator(),
            )
                : ListView.builder(
              itemCount: logs.length,
              itemBuilder: (_, i) {
                final log = logs[i];

                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      log.module[0],
                    ),
                  ),
                  title: Text(log.description),
                  subtitle: Text(
                    '${log.userName} • '
                        '${DateFormat('dd MMM yyyy HH:mm').format(log.createdAtUtc.toLocal())}',
                  ),
                  trailing: Chip(
                    label: Text(log.action),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}