import 'package:flutter/material.dart';

import '../data/models/equipment.dart';
import '../data/repositories/equipment_repository.dart';
import 'equipment_create_screen.dart';
import 'equipment_detail_screen.dart';

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

class _EquipmentListScreenState extends State<EquipmentListScreen> {
  List<Equipment> _equipment = [];
  bool _isLoading = true;
  String? _errorMessage;

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
        title: const Text('Equipment'),
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
          final created = await Navigator.of(context).push<bool>(
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
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Icon(
              Icons.construction_outlined,
              size: 64,
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'No equipment found.',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEquipment,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          100,
        ),
        itemCount: _equipment.length,
        itemBuilder: (context, index) {
          return _EquipmentCard(
            equipment: _equipment[index],
            onTap: () async {
              final updated = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => EquipmentDetailScreen(
                    equipment: _equipment[index],
                    repository: widget.repository,
                  ),
                ),
              );

              if (updated == true && mounted) {
                await _loadEquipment();
              }
            },
          );
        },
      ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: theme.colorScheme.primaryContainer,
                    ),
                    child: Icon(
                      Icons.construction_outlined,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          equipment.equipmentCode,
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          equipment.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
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
              const Divider(height: 24),
              _InfoRow(
                label: 'Category',
                value: equipment.category ?? '—',
              ),
              _InfoRow(
                label: 'Ownership',
                value: equipment.ownershipType,
              ),
              _InfoRow(
                label: 'Make / Model',
                value: _makeModel(),
              ),
              _InfoRow(
                label: 'Meter',
                value:
                '${equipment.currentMeterReading} ${equipment.meterUnit}',
              ),
              if (equipment.serialNumber != null)
                _InfoRow(
                  label: 'Serial',
                  value: equipment.serialNumber!,
                ),
              if (equipment.registrationNumber != null)
                _InfoRow(
                  label: 'Registration',
                  value: equipment.registrationNumber!,
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    equipment.isActive
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    equipment.isActive ? 'Active' : 'Inactive',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _makeModel() {
    final parts = <String>[];

    if (equipment.make != null &&
        equipment.make!.trim().isNotEmpty) {
      parts.add(equipment.make!.trim());
    }

    if (equipment.model != null &&
        equipment.model!.trim().isNotEmpty) {
      parts.add(equipment.model!.trim());
    }

    return parts.isEmpty ? '—' : parts.join(' / ');
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(status),
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
              style:
                  Theme.of(context).textTheme.labelMedium,
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
