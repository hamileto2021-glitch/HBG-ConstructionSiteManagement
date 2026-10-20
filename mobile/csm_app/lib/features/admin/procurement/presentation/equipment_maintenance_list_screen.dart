import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models/equipment_maintenance.dart';
import '../data/repositories/equipment_maintenance_repository.dart';
import 'equipment_maintenance_create_screen.dart';
import 'equipment_maintenance_detail_screen.dart';

class EquipmentMaintenanceListScreen extends StatefulWidget {
  EquipmentMaintenanceListScreen({
    super.key,
    EquipmentMaintenanceRepository? repository,
  }) : repository =
      repository ?? EquipmentMaintenanceRepository();

  final EquipmentMaintenanceRepository repository;

  @override
  State<EquipmentMaintenanceListScreen> createState() =>
      _EquipmentMaintenanceListScreenState();
}

class _EquipmentMaintenanceListScreenState
    extends State<EquipmentMaintenanceListScreen> {
  List<EquipmentMaintenance> _maintenance = [];
  bool _isLoading = true;
  bool? _completedOnly;
  String? _errorMessage;

  final NumberFormat _currency = NumberFormat('#,##0.00');

  int get _total => _maintenance.length;

  int get _pending =>
      _maintenance.where((e) => e.completedAtUtc == null).length;

  int get _completed =>
      _maintenance.where((e) => e.completedAtUtc != null).length;

  double get _totalCost =>
      _maintenance.fold(0, (s, e) => s + (e.cost ?? 0));

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await widget.repository.getAll(
        completedOnly: _completedOnly,
      );

      if (!mounted) return;

      setState(() {
        _maintenance = result;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment Maintenance'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool?>(
                segments: const [
                  ButtonSegment<bool?>(
                    value: null,
                    label: Text('All'),
                    icon: Icon(Icons.list_alt),
                  ),
                  ButtonSegment<bool?>(
                    value: false,
                    label: Text('Pending'),
                    icon: Icon(Icons.pending_actions_outlined),
                  ),
                  ButtonSegment<bool?>(
                    value: true,
                    label: Text('Completed'),
                    icon: Icon(Icons.task_alt_outlined),
                  ),
                ],
                selected: {_completedOnly},
                onSelectionChanged: (selection) {
                  setState(() {
                    _completedOnly = selection.first;
                  });
                  _load();
                },
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => EquipmentMaintenanceCreateScreen(
                maintenanceRepository: widget.repository,
              ),
            ),
          );

          if (created == true && mounted) {
            await _load();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Maintenance'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text(
                'Unable to load maintenance records',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_maintenance.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 140),
            Icon(Icons.build_circle_outlined, size: 64),
            SizedBox(height: 16),
            Center(
              child: Text('No maintenance records found.'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 16),
          ..._maintenance.map(
                (record) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _MaintenanceCard(
                maintenance: record,
                onTap: () async {
                  final updated =
                  await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) =>
                          EquipmentMaintenanceDetailScreen(
                            maintenance: record,
                            repository: widget.repository,
                          ),
                    ),
                  );

                  if (updated == true && mounted) {
                    await _load();
                  }
                },
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
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.55,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _SummaryCard(
          title: 'Total',
          value: '$_total',
          icon: Icons.build,
          color: Colors.blue,
        ),
        _SummaryCard(
          title: 'Pending',
          value: '$_pending',
          icon: Icons.pending_actions,
          color: Colors.orange,
        ),
        _SummaryCard(
          title: 'Completed',
          value: '$_completed',
          icon: Icons.task_alt,
          color: Colors.green,
        ),
        _SummaryCard(
          title: 'Cost',
          value: 'ETB ${_currency.format(_totalCost)}',
          icon: Icons.account_balance_wallet,
          color: Colors.purple,
        ),
      ],
    );
  }
}

class _MaintenanceCard extends StatelessWidget {
  const _MaintenanceCard({
    required this.maintenance,
    required this.onTap,
  });

  final EquipmentMaintenance maintenance;
  final VoidCallback onTap;

  static final NumberFormat _currency =
  NumberFormat('#,##0.00');

  String _date(DateTime value) {
    final d = value.toLocal();
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final completed = maintenance.completedAtUtc != null;
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.build,
                      color:
                      theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          maintenance.equipmentCode,
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          maintenance.equipmentName,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    backgroundColor: completed
                        ? Colors.green.withValues(alpha: .12)
                        : Colors.orange.withValues(alpha: .12),
                    label: Text(
                      completed ? 'Completed' : 'Pending',
                      style: TextStyle(
                        color: completed
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              _InfoRow(
                label: 'Type',
                value: maintenance.maintenanceType,
              ),
              _InfoRow(
                label: 'Scheduled',
                value: _date(maintenance.scheduledAtUtc),
              ),
              _InfoRow(
                label: 'Meter',
                value: maintenance.meterReading == null
                    ? '—'
                    : maintenance.meterReading!
                    .toStringAsFixed(1),
              ),
              _InfoRow(
                label: 'Cost',
                value: maintenance.cost == null
                    ? '—'
                    : '${maintenance.currencyCode} ${_currency.format(maintenance.cost)}',
              ),
              if (maintenance.serviceProvider != null &&
                  maintenance.serviceProvider!
                      .trim()
                      .isNotEmpty)
                _InfoRow(
                  label: 'Provider',
                  value: maintenance.serviceProvider!,
                ),
              if (maintenance.completedAtUtc != null)
                _InfoRow(
                  label: 'Completed',
                  value: _date(maintenance.completedAtUtc!),
                ),
              if (maintenance.nextMaintenanceAtUtc != null)
                _InfoRow(
                  label: 'Next Service',
                  value: _date(
                    maintenance.nextMaintenanceAtUtc!,
                  ),
                ),
            ],
          ),
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}