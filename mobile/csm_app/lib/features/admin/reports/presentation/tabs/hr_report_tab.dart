import 'package:flutter/material.dart';
import '../../../../../core/utils/currency_formatter.dart';



class HrReportTab extends StatelessWidget {
  const HrReportTab({super.key});

  @override
  Widget build(BuildContext context) {
    const attendanceRate = 0.94;
    const totalEmployees = 186;
    const contractors = 58;
    const leaveRequests = 12;
    const payroll = 8450000.0;

    String money(double value) =>
        CurrencyFormatter.etb(value);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'HR Analytics',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: const [
            Expanded(
              child: _HrCard(
                title: 'Employees',
                value: '186',
                color: Colors.blue,
                icon: Icons.people,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _HrCard(
                title: 'Contractors',
                value: '58',
                color: Colors.orange,
                icon: Icons.engineering,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            const Expanded(
              child: _HrCard(
                title: 'Leave',
                value: '12',
                color: Colors.purple,
                icon: Icons.event_busy,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _HrCard(
                title: 'Payroll',
                value: money(payroll),
                color: Colors.green,
                icon: Icons.payments,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        const Text(
          'Attendance Rate',
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
                    const Text('Today'),
                    Text(
                      '${(attendanceRate * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: attendanceRate,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 18),
                _SummaryRow(
                  'Present',
                  '${(totalEmployees * attendanceRate).round()}',
                ),
                const Divider(),
                _SummaryRow(
                  'Absent',
                  '${totalEmployees - (totalEmployees * attendanceRate).round()}',
                ),
                const Divider(),
                _SummaryRow(
                  'Leave Requests',
                  '$leaveRequests',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'Workforce Distribution',
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
                _DistributionBar(
                  label: 'Permanent',
                  percent: (totalEmployees - contractors) / totalEmployees,
                  color: Colors.blue,
                ),
                const SizedBox(height: 12),
                _DistributionBar(
                  label: 'Contract',
                  percent: contractors / totalEmployees,
                  color: Colors.orange,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'Site Workforce',
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
                  Icons.location_city,
                  color: Colors.blue,
                ),
                title: Text('Office Complex'),
                subtitle: Text('92 Workers'),
                trailing: Text(
                  '49%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.location_city,
                  color: Colors.green,
                ),
                title: Text('Warehouse'),
                subtitle: Text('54 Workers'),
                trailing: Text(
                  '29%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.location_city,
                  color: Colors.orange,
                ),
                title: Text('Road Project'),
                subtitle: Text('40 Workers'),
                trailing: Text(
                  '22%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
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

class _HrCard extends StatelessWidget {
  const _HrCard({
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
          crossAxisAlignment: CrossAxisAlignment.start,
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

class _DistributionBar extends StatelessWidget {
  const _DistributionBar({
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