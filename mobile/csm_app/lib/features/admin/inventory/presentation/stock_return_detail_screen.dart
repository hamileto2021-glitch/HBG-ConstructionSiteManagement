import 'package:flutter/material.dart';

import '../data/models/stock_return.dart';

class StockReturnDetailScreen extends StatelessWidget {
  const StockReturnDetailScreen({
    super.key,
    required this.stockReturn,
  });

  final StockReturn stockReturn;

  String _date(DateTime value) {
    final d = value.toLocal();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Widget _infoRow(String label, String value) {
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
        title: const Text('Stock Return Detail'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    stockReturn.referenceNumber,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(_date(stockReturn.returnDateUtc)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Site & Material',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  _infoRow('Site', stockReturn.siteName),
                  _infoRow(
                    'Material',
                    '${stockReturn.materialCode} • ${stockReturn.materialName}',
                  ),
                  _infoRow(
                    'Unit',
                    stockReturn.unitOfMeasure,
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
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Return Information',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  _infoRow(
                    'Returned Qty',
                    '${stockReturn.returnedQuantity} ${stockReturn.unitOfMeasure}',
                  ),
                  _infoRow(
                    'Original Issue',
                    stockReturn.originalIssuedQuantity.toString(),
                  ),
                  _infoRow(
                    'Previously Returned',
                    stockReturn.previouslyReturnedQuantity.toString(),
                  ),
                  _infoRow(
                    'Remaining Returnable',
                    stockReturn.remainingReturnableQuantity.toString(),
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
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cost & Audit',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  _infoRow(
                    'Unit Cost',
                    stockReturn.unitCost.toStringAsFixed(2),
                  ),
                  _infoRow(
                    'Stock Before',
                    stockReturn.quantityOnHandBefore.toString(),
                  ),
                  _infoRow(
                    'Stock After',
                    stockReturn.quantityOnHandAfter.toString(),
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
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Remarks',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  _infoRow(
                    'Returned By',
                    stockReturn.returnedBy ?? '-',
                  ),
                  _infoRow(
                    'Reason',
                    stockReturn.reason ?? '-',
                  ),
                  _infoRow(
                    'Remarks',
                    stockReturn.remarks ?? '-',
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