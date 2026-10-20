import 'package:flutter/material.dart';



class EquipmentReportTab extends StatelessWidget {
  const EquipmentReportTab({super.key});

  @override
  Widget build(BuildContext context) {
    const utilization = 0.92;
    const maintenanceDue = 6;
    const downtimeHours = 48;
    const fuelConsumption = 18450.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Equipment Analytics',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: const [
            Expanded(
              child: _EquipmentCard(
                title: 'Utilization',
                value: '92%',
                color: Colors.blue,
                icon: Icons.construction,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _EquipmentCard(
                title: 'Maintenance',
                value: '6',
                color: Colors.orange,
                icon: Icons.build,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: const [
            Expanded(
              child: _EquipmentCard(
                title: 'Downtime',
                value: '48 h',
                color: Colors.red,
                icon: Icons.warning,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _EquipmentCard(
                title: 'Fuel',
                value: '18,450 L',
                color: Colors.green,
                icon: Icons.local_gas_station,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        const Text(
          'Fleet Utilization',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Overall Utilization'),
                    Text(
                      '${(utilization * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: utilization,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 18),
                _SummaryRow(
                  'Maintenance Due',
                  '$maintenanceDue Equipment',
                ),
                const Divider(),
                _SummaryRow(
                  'Downtime',
                  '$downtimeHours Hours',
                ),
                const Divider(),
                _SummaryRow(
                  'Fuel Consumption',
                  '${fuelConsumption.toStringAsFixed(0)} L',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'Equipment Status',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: const [
                _StatusBar(
                  label: 'Operational',
                  percent: 0.68,
                  color: Colors.green,
                ),
                SizedBox(height: 12),
                _StatusBar(
                  label: 'Under Maintenance',
                  percent: 0.18,
                  color: Colors.orange,
                ),
                SizedBox(height: 12),
                _StatusBar(
                  label: 'Breakdown',
                  percent: 0.14,
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'Top Utilized Equipment',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        Card(
          child: Column(
            children: const [
              ListTile(
                leading: Icon(
                  Icons.construction,
                  color: Colors.blue,
                ),
                title: Text('Excavator EX-001'),
                subtitle: Text('Operating Hours: 1,280'),
                trailing: Text(
                  '98%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.construction,
                  color: Colors.blue,
                ),
                title: Text('Crane CR-004'),
                subtitle: Text('Operating Hours: 1,040'),
                trailing: Text(
                  '91%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.construction,
                  color: Colors.blue,
                ),
                title: Text('Dump Truck DT-012'),
                subtitle: Text('Operating Hours: 870'),
                trailing: Text(
                  '86%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  const _EquipmentCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
      MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.label,
    required this.percent,
    required this.color,
  });

  final String label;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              '${(percent * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percent,
          color: color,
          minHeight: 8,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }
}