import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models/equipment_utilization.dart';
import '../data/repositories/equipment_utilization_repository.dart';

class EquipmentUtilizationScreen extends StatefulWidget {
  EquipmentUtilizationScreen({
    super.key,
    EquipmentUtilizationRepository? repository,
  }) : repository =
      repository ?? EquipmentUtilizationRepository();

  final EquipmentUtilizationRepository repository;

  @override
  State<EquipmentUtilizationScreen> createState() =>
      _EquipmentUtilizationScreenState();
}

class _EquipmentUtilizationScreenState
    extends State<EquipmentUtilizationScreen> {
  final NumberFormat _currency = NumberFormat('#,##0.00');
  final NumberFormat _number = NumberFormat('#,##0.0');

  List<EquipmentUtilization> _items = [];
  bool _loading = true;
  String? _error;

  double get _totalHours =>
      _items.fold(0, (s, e) => s + e.hoursWorked);

  double get _totalFuel =>
      _items.fold(0, (s, e) => s + e.fuelConsumed);

  double get _totalDowntime =>
      _items.fold(0, (s, e) => s + e.downtimeHours);

  double get _maintenanceCost =>
      _items.fold(0, (s, e) => s + e.maintenanceCost);



  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await widget.repository.getAll();

      if (!mounted) return;

      setState(() {
        _items = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment Utilization'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Unable to load utilization data',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                SelectableText(
                  _error!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _load,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const [
            SizedBox(height: 140),
            Icon(Icons.analytics_outlined, size: 64),
            SizedBox(height: 16),
            Center(
              child: Text(
                'No utilization data available.',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding:
        const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 20),
          Text(
            'Equipment Performance',
            style: Theme.of(context)
                .textTheme
                .titleLarge,
          ),
          const SizedBox(height: 12),
          ..._items.map(
                (e) => Padding(
              padding:
              const EdgeInsets.only(bottom: 12),
              child: _UtilizationCard(
                item: e,
                currency: _currency,
                number: _number,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics:
      const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.45,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _SummaryCard(
          title: 'Hours Worked',
          value: _number.format(_totalHours),
          icon: Icons.timer,
          color: Colors.blue,
        ),
        _SummaryCard(
          title: 'Fuel Used',
          value: '${_number.format(_totalFuel)} L',
          icon: Icons.local_gas_station,
          color: Colors.green,
        ),
        _SummaryCard(
          title: 'Downtime',
          value: '${_number.format(_totalDowntime)} h',
          icon: Icons.warning_amber,
          color: Colors.orange,
        ),
        _SummaryCard(
          title: 'Maintenance',
          value:
          'ETB ${_currency.format(_maintenanceCost)}',
          icon: Icons.build,
          color: Colors.purple,
        ),
      ],
    );
  }
}

class _UtilizationCard extends StatelessWidget {
  const _UtilizationCard({
    required this.item,
    required this.currency,
    required this.number,
  });

  final EquipmentUtilization item;
  final NumberFormat currency;
  final NumberFormat number;

  Color _statusColor() {
    if (item.utilization >= 90) {
      return Colors.green;
    }
    if (item.utilization >= 70) {
      return Colors.orange;
    }
    return Colors.red;
  }

  String _status() {
    if (item.utilization >= 90) {
      return 'Excellent';
    }
    if (item.utilization >= 70) {
      return 'Good';
    }
    return 'Low';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.equipmentCode,
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.equipmentName,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium,
                      ),
                    ],
                  ),
                ),
                Chip(
                  backgroundColor:
                  statusColor.withValues(alpha: .12),
                  label: Text(
                    _status(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _InfoRow(
              label: 'Hours Worked',
              value:
              '${number.format(item.hoursWorked)} h',
            ),
            _InfoRow(
              label: 'Fuel Used',
              value:
              '${number.format(item.fuelConsumed)} L',
            ),
            _InfoRow(
              label: 'Downtime',
              value:
              '${number.format(item.downtimeHours)} h',
            ),
            _InfoRow(
              label: 'Fuel / Hour',
              value:
              '${number.format(item.fuelPerHour)} L/h',
            ),
            _InfoRow(
              label: 'Maintenance',
              value:
              'ETB ${currency.format(item.maintenanceCost)}',
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Utilization',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${item.utilization.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: item.utilization / 100,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              color: statusColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

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
            const Spacer(),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall,
            ),
            Text(title),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value),
        ],
      ),
    );
  }
}