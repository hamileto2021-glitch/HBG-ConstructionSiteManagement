import 'package:flutter/material.dart';
import '../data/models/stock_issue.dart';

class StockIssueDetailScreen extends StatelessWidget {
  const StockIssueDetailScreen({
    super.key,
    required this.issue,
  });

  final StockIssue issue;

  String _date(DateTime value) {
    final d = value.toLocal();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Issue Detail'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    issue.referenceNumber,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _date(issue.issueDateUtc),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Site & Material',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _row('Site', issue.siteName),
                  _row(
                    'Material',
                    '${issue.materialCode} • ${issue.materialName}',
                  ),
                  _row('Unit', issue.unitOfMeasure),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quantity & Cost',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _row(
                    'Issued',
                    '${issue.quantityIssued} ${issue.unitOfMeasure}',
                  ),
                  _row(
                    'Unit Cost',
                    issue.unitCost.toStringAsFixed(2),
                  ),
                  _row(
                    'Total Cost',
                    issue.totalCost.toStringAsFixed(2),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Issue Information',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _row(
                    'Issued To',
                    issue.issuedTo ?? '-',
                  ),
                  _row(
                    'Purpose',
                    issue.purpose ?? '-',
                  ),
                  _row(
                    'Remarks',
                    issue.remarks ?? '-',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Inventory Impact',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          const Text('Before'),
                          Text(
                            issue.quantityOnHandBefore.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_forward),
                      Column(
                        children: [
                          const Text('After'),
                          Text(
                            issue.quantityOnHandAfter.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}