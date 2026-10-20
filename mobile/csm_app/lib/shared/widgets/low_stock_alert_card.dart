import 'package:flutter/material.dart';

class LowStockAlertCard extends StatelessWidget {
  const LowStockAlertCard({
    super.key,
    required this.lowStockCount,
    required this.criticalItems,
  });

  final int lowStockCount;
  final List<String> criticalItems;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'Low Stock Alerts',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              '$lowStockCount',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Text('Items below reorder level'),

            const Divider(height: 28),

            ...criticalItems.map(
                  (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 8, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            ),

            if (criticalItems.isEmpty)
              const Text('No critical inventory items'),
          ],
        ),
      ),
    );
  }
}