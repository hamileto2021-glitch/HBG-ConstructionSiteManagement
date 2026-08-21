import 'package:flutter/material.dart';

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
      final maintenance =
          await widget.repository.getAll(
        completedOnly: _completedOnly,
      );

      if (!mounted) return;

      setState(() {
        _maintenance = maintenance;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
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
            padding: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              8,
            ),
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
                    icon: Icon(
                      Icons.pending_actions_outlined,
                    ),
                  ),
                  ButtonSegment<bool?>(
                    value: true,
                    label: Text('Completed'),
                    icon: Icon(
                      Icons.task_alt_outlined,
                    ),
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
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created =
          await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) =>
                  EquipmentMaintenanceCreateScreen(
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
              const Icon(
                Icons.error_outline,
                size: 48,
              ),
              const SizedBox(height: 16),
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
          physics:
              const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Icon(
              Icons.build_circle_outlined,
              size: 64,
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'No equipment maintenance records found.',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          24,
        ),
        itemCount: _maintenance.length,
        itemBuilder: (context, index) {
          return _MaintenanceCard(
            maintenance: _maintenance[index],
            onTap: () async {
              final updated =
              await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) =>
                      EquipmentMaintenanceDetailScreen(
                        maintenance: _maintenance[index],
                        repository: widget.repository,
                      ),
                ),
              );

              if (updated == true && mounted) {
                await _load();
              }
            },
          );
        },
      ),
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

  String _formatDate(DateTime value) {
    final local = value.toLocal();

    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  String _formatNumber(double? value) {
    if (value == null) {
      return '—';
    }

    return value.toStringAsFixed(
      value.truncateToDouble() == value ? 0 : 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isCompleted =
        maintenance.completedAtUtc != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(12),
                      color: theme
                          .colorScheme
                          .primaryContainer,
                    ),
                    child: Icon(
                      Icons.build_outlined,
                      color: theme
                          .colorScheme
                          .onPrimaryContainer,
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
                          style: theme
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          maintenance.equipmentName,
                          style:
                              theme.textTheme.labelLarge,
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      isCompleted
                          ? 'Completed'
                          : 'Pending',
                    ),
                    visualDensity:
                        VisualDensity.compact,
                  ),
                ],
              ),
              const Divider(height: 24),
              _InfoRow(
                label: 'Maintenance Type',
                value: maintenance.maintenanceType,
              ),
              _InfoRow(
                label: 'Scheduled',
                value: _formatDate(
                  maintenance.scheduledAtUtc,
                ),
              ),
              _InfoRow(
                label: 'Started',
                value:
                    maintenance.startedAtUtc == null
                        ? '—'
                        : _formatDate(
                            maintenance.startedAtUtc!,
                          ),
              ),
              _InfoRow(
                label: 'Completed',
                value:
                    maintenance.completedAtUtc == null
                        ? '—'
                        : _formatDate(
                            maintenance.completedAtUtc!,
                          ),
              ),
              _InfoRow(
                label: 'Meter Reading',
                value: _formatNumber(
                  maintenance.meterReading,
                ),
              ),
              _InfoRow(
                label: 'Cost',
                value: maintenance.cost == null
                    ? '—'
                    : '${_formatNumber(maintenance.cost)} '
                        '${maintenance.currencyCode}',
              ),
              if (maintenance.serviceProvider != null &&
                  maintenance.serviceProvider!
                      .trim()
                      .isNotEmpty)
                _InfoRow(
                  label: 'Service Provider',
                  value:
                      maintenance.serviceProvider!,
                ),
              _InfoRow(
                label: 'Next Maintenance',
                value: maintenance
                            .nextMaintenanceAtUtc ==
                        null
                    ? '—'
                    : _formatDate(
                        maintenance
                            .nextMaintenanceAtUtc!,
                      ),
              ),
            ],
          ),
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
            width: 145,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium,
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
