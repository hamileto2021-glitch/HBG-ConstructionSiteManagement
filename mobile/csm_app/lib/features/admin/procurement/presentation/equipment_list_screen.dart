import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models/equipment.dart';
import '../data/repositories/equipment_repository.dart';
import 'equipment_create_screen.dart';
import 'equipment_detail_screen.dart';
import '../../../../responsive/breakpoints.dart';
import '../../../../shared/widgets/adaptive_data_table.dart';



class EquipmentListScreen extends StatefulWidget {
  EquipmentListScreen({
    super.key,
    EquipmentRepository? repository,
  }) : repository = repository ?? EquipmentRepository();

  final EquipmentRepository repository;

  @override
  State<EquipmentListScreen> createState() =>
      _EquipmentListScreenState();
}

class _EquipmentListScreenState
    extends State<EquipmentListScreen> {
  List<Equipment> _equipment = [];
  bool _isLoading = true;
  String? _errorMessage;

  final NumberFormat _currency = NumberFormat('#,##0.00');

  String money(double? value) =>
      value == null ? '—' : 'ETB ${_currency.format(value)}';

  int get _total => _equipment.length;

  int get _available =>
      _equipment.where((e) => e.status == 'Available').length;

  int get _inUse =>
      _equipment.where((e) => e.status == 'InUse').length;

  int get _maintenance =>
      _equipment.where((e) => e.status == 'Maintenance').length;

  @override
  void initState() {
    super.initState();
    _loadEquipment();
  }

  Future<void> _loadEquipment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final equipment = await widget.repository.getAll();

      if (!mounted) return;

      setState(() {
        _equipment = equipment;
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
        title: const Text('Equipment Management'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadEquipment,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created =
          await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => EquipmentCreateScreen(
                repository: widget.repository,
              ),
            ),
          );

          if (created == true && mounted) {
            await _loadEquipment();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Equipment'),
      ),
      body: _buildBody(),
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
                'Unable to load equipment',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadEquipment,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_equipment.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadEquipment,
        child: ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Icon(
              Icons.construction_outlined,
              size: 64,
            ),
            SizedBox(height: 16),
            Center(
              child: Text('No equipment found.'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEquipment,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          100,
        ),
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 16),
          if (AppBreakpoints.isDesktop(context))
            AdaptiveDataTable(
              columns: [
                AdaptiveColumn(
                  label: 'Equipment',
                  value: (r) => r['name'] as String,
                ),
                AdaptiveColumn(
                  label: 'Asset No.',
                  value: (r) => r['asset'] as String,
                ),
                AdaptiveColumn(
                  label: 'Category',
                  value: (r) => r['category'] as String,
                ),
                AdaptiveColumn(
                  label: 'Status',
                  value: (r) => r['status'] as String,
                ),
                AdaptiveColumn(
                  label: 'Ownership',
                  value: (r) => r['ownership'] as String,
                ),
              ],
              rows: _equipment.map((e) {
                return {
                  'equipment': e,
                  'name': e.name,
                  'asset': e.equipmentCode,
                  'category': e.category.isEmpty ? '-' : e.category,
                  'status': e.status,
                  'ownership': e.ownershipType,
                };
              }).toList(),
              onRowTap: (row) async {
                final equipment = row['equipment'] as Equipment;

                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EquipmentDetailScreen(
                      equipment: equipment,
                      repository: widget.repository,
                    ),
                  ),
                );

                if (updated == true && mounted) {
                  await _loadEquipment();
                }
              },
            )
          else
            ..._equipment.map(
                  (equipment) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _EquipmentCard(
                  equipment: equipment,
                  onTap: () async {
                    final updated = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EquipmentDetailScreen(
                          equipment: equipment,
                          repository: widget.repository,
                        ),
                      ),
                    );

                    if (updated == true && mounted) {
                      await _loadEquipment();
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
    final isDesktop = AppBreakpoints.isDesktop(context);

    return GridView.count(
      crossAxisCount: isDesktop ? 4 : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: isDesktop ? 1.8 : 1.55,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _SummaryCard(
          title: 'Total',
          value: '$_total',
          icon: Icons.construction,
          color: Colors.blue,
        ),
        _SummaryCard(
          title: 'Available',
          value: '$_available',
          icon: Icons.check_circle,
          color: Colors.green,
        ),
        _SummaryCard(
          title: 'In Use',
          value: '$_inUse',
          icon: Icons.engineering,
          color: Colors.orange,
        ),
        _SummaryCard(
          title: 'Maintenance',
          value: '$_maintenance',
          icon: Icons.build,
          color: Colors.red,
        ),
      ],
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  const _EquipmentCard({
    required this.equipment,
    required this.onTap,
  });

  final Equipment equipment;
  final VoidCallback onTap;

  static final NumberFormat _currency =
  NumberFormat('#,##0.00');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius:
                      BorderRadius.circular(12),
                      color: theme.colorScheme
                          .primaryContainer,
                    ),
                    child: Icon(
                      Icons.construction,
                      color: theme.colorScheme
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
                          equipment.equipmentCode,
                          style: theme
                              .textTheme.labelLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          equipment.name,
                          style: theme
                              .textTheme.titleMedium
                              ?.copyWith(
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(
                    status: equipment.status,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _OwnershipBadge(
                    ownership:
                    equipment.ownershipType,
                  ),
                  const Spacer(),
                  Icon(
                    equipment.isActive
                        ? Icons.check_circle
                        : Icons.cancel,
                    size: 18,
                    color: equipment.isActive
                        ? Colors.green
                        : Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    equipment.isActive
                        ? 'Active'
                        : 'Inactive',
                  ),
                ],
              ),
              const Divider(height: 24),
              _InfoRow(
                label: 'Category',
                value: equipment.category.isEmpty ? '—' : equipment.category,
              ),
              _InfoRow(
                label: 'Make / Model',
                value: _makeModel(),
              ),
              _InfoRow(
                label: 'Meter',
                value:
                '${equipment.currentMeterReading.toStringAsFixed(1)} ${equipment.meterUnit}',
              ),
              _InfoRow(
                label: 'Value',
                value: _valueText(),
              ),
              if (equipment.serialNumber != null)
                _InfoRow(
                  label: 'Serial',
                  value: equipment.serialNumber!,
                ),
              if (equipment.registrationNumber != null)
                _InfoRow(
                  label: 'Registration',
                  value:
                  equipment.registrationNumber!,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _makeModel() {
    final parts = <String>[];

    if (equipment.make.trim().isNotEmpty) {
      parts.add(equipment.make.trim());
    }

    if (equipment.model.trim().isNotEmpty) {
      parts.add(equipment.model.trim());
    }

    return parts.isEmpty ? '—' : parts.join(' / ');
  }

  String _valueText() {
    if (equipment.purchaseCost != null) {
      return 'ETB ${_currency.format(equipment.purchaseCost)}';
    }

    if (equipment.rentalRate != null) {
      return 'ETB ${_currency.format(equipment.rentalRate)}'
          '/${equipment.rentalRateUnit ?? ''}';
    }

    return '—';
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
                  .textTheme.headlineSmall,
            ),
            Text(title),
          ],
        ),
      ),
    );
  }
}

class _OwnershipBadge extends StatelessWidget {
  const _OwnershipBadge({
    required this.ownership,
  });

  final String ownership;

  @override
  Widget build(BuildContext context) {
    final owned = ownership == 'Owned';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: owned
            ? Colors.indigo.withValues(alpha: .12)
            : Colors.teal.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        ownership,
        style: TextStyle(
          color: owned
              ? Colors.indigo
              : Colors.teal,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;

    switch (status) {
      case 'Available':
        color = Colors.green;
        break;
      case 'InUse':
        color = Colors.orange;
        break;
      case 'Maintenance':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      backgroundColor:
      color.withValues(alpha: .12),
      label: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
      visualDensity: VisualDensity.compact,
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
            width: 90,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme.labelMedium,
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