import 'package:flutter/material.dart';

import '../../procurement/data/repositories/material_repository.dart';
import '../../sites/data/repositories/site_repository.dart';
import '../data/models/stock_issue.dart';
import '../data/repositories/stock_issue_repository.dart';
import 'stock_issue_create_screen.dart';
import 'stock_issue_detail_screen.dart';



class StockIssueListScreen extends StatefulWidget {
  const StockIssueListScreen({
    super.key,
    required this.repository,
  });

  final StockIssueRepository repository;

  @override
  State<StockIssueListScreen> createState() =>
      _StockIssueListScreenState();
}

class _StockIssueListScreenState
    extends State<StockIssueListScreen> {
  bool _loading = true;
  List<StockIssue> _issues = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      _issues = await widget.repository.getAll();
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _create() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => StockIssueCreateScreen(
          repository: StockIssueRepository(),
          materialRepository: MaterialRepository(),
          siteRepository: SiteRepository(),
        ),
      ),
    );

    if (created == true) {
      _load();
    }
  }

  String _date(DateTime value) {
    final d = value.toLocal();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Issues'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _create,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _issues.isEmpty
          ? const Center(
        child: Text('No stock issues found'),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _issues.length,
        itemBuilder: (_, index) {
          final issue = _issues[index];

          return Card(
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StockIssueDetailScreen(
                      issue: issue,
                    ),
                  ),
                );
              },
              leading: const CircleAvatar(
                child: Icon(Icons.outbox),
              ),
              title: Text(issue.referenceNumber),
              subtitle: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    '${issue.materialCode} • ${issue.materialName}',
                  ),
                  Text(issue.siteName),
                  Text(_date(issue.issueDateUtc)),
                ],
              ),
              trailing: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                crossAxisAlignment:
                CrossAxisAlignment.end,
                children: [
                  Text(
                    '${issue.quantityIssued}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(issue.unitOfMeasure),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}