import 'package:flutter/material.dart';

class EquipmentUtilizationCard extends StatelessWidget {
  const EquipmentUtilizationCard({
    super.key,
    required this.utilization,
    required this.available,
    required this.inUse,
  });

  final double utilization;
  final int available;
  final int inUse;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Equipment Utilization',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),

            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: utilization / 100,
                      strokeWidth: 10,
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        '${utilization.toStringAsFixed(0)}%',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium,
                      ),
                      const Text('Utilized'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: _metric(
                    'Available',
                    available.toString(),
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _metric(
                    'In Use',
                    inUse.toString(),
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(
      String label,
      String value,
      Color color,
      ) {
    return Column(
      children: [
        Icon(Icons.circle, size: 12, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label),
      ],
    );
  }
}