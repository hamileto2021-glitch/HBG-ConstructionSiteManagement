import 'package:flutter/material.dart';

import '../data/models/violation.dart';
import '../data/repositories/violation_repository.dart';

class ViolationListScreen extends StatefulWidget {
  const ViolationListScreen({super.key});

  @override
  State<ViolationListScreen> createState() =>
      _ViolationListScreenState();
}

class _ViolationListScreenState
    extends State<ViolationListScreen> {
  final _repo = ViolationRepository();

  List<Violation> _all = [];
  bool _loading = true;
  bool _openOnly = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _repo.getAll();

    if (!mounted) return;

    setState(() {
      _all = data;
      _loading = false;
    });
  }

  List<Violation> get _items =>
      _openOnly
          ? _all.where((e) => !e.isResolved).toList()
          : _all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Violations Register'),
        actions: [
          Switch(
            value: _openOnly,
            onChanged: (v) =>
                setState(() => _openOnly = v),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          itemCount: _items.length,
          itemBuilder: (_, index) {
            final v = _items[index];

            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: v.isResolved
                      ? Colors.green
                      : Colors.red,
                  child: Icon(
                    v.isResolved
                        ? Icons.check
                        : Icons.warning,
                    color: Colors.white,
                  ),
                ),
                title: Text(v.requirement),
                subtitle: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(v.inspectionNumber),
                    Text(v.siteName),
                    if (v.correctiveAction != null)
                      Text(
                        'Action: ${v.correctiveAction}',
                      ),
                  ],
                ),
                trailing: Text(v.status),
              ),
            );
          },
        ),
      ),
    );
  }
}