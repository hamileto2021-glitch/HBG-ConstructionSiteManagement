import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models/equipment_fuel_log.dart';
import '../data/repositories/equipment_fuel_log_repository.dart';
import '../../data/models/equipment.dart';
import '../../data/repositories/equipment_repository.dart';
import 'package:csm_app/features/admin/sites/data/models/site.dart';
import 'package:csm_app/features/admin/sites/data/repositories/site_repository.dart';

class EquipmentFuelLogScreen extends StatefulWidget {
  EquipmentFuelLogScreen({
    super.key,
    this.equipmentId,
    this.equipmentName,
    EquipmentFuelLogRepository? repository,
  }) : repository = repository ?? EquipmentFuelLogRepository();

  final String? equipmentId;
  final String? equipmentName;
  final EquipmentFuelLogRepository repository;

  @override
  State<EquipmentFuelLogScreen> createState() =>
      _EquipmentFuelLogScreenState();
}

class _EquipmentFuelLogScreenState
    extends State<EquipmentFuelLogScreen> {
  final NumberFormat _currency = NumberFormat('#,##0.00');

  List<EquipmentFuelLog> _logs = [];
  bool _loading = true;
  String? _error;

  double get _totalLiters =>
      _logs.fold(0, (s, e) => s + e.liters);

  double get _totalCost =>
      _logs.fold(0, (s, e) => s + e.totalCost);

  double get _averagePrice =>
      _logs.isEmpty ? 0 : _totalCost / _totalLiters;

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
      final result = await widget.repository.getAll(
        equipmentId: widget.equipmentId,
      );

      if (!mounted) return;

      setState(() {
        _logs = result;
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

  Future<void> _createFuelLog() async {
    String? selectedEquipmentId = widget.equipmentId;
    String? selectedSiteId;

    List<Equipment> equipmentList = [];
    List<Site> sites = [];

    final liters = TextEditingController();
    final unitPrice = TextEditingController();
    final meter = TextEditingController();
    final supplier = TextEditingController();
    final invoice = TextEditingController();
    final remarks = TextEditingController();

    String fuelType = 'Diesel';

    equipmentList = await EquipmentRepository().getAll();
    final siteRepository = SiteRepository();
    sites = await siteRepository.getAll();

    if (!mounted) return;

    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialog) {
            return AlertDialog(
              title: const Text('New Fuel Entry'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: selectedEquipmentId,
                        decoration: const InputDecoration(
                          labelText: 'Equipment *',
                        ),
                        items: equipmentList.map((e) {
                          return DropdownMenuItem(
                            value: e.id,
                            child: Text(
                              '${e.equipmentCode} - ${e.name}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialog(() {
                            selectedEquipmentId = value;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: selectedSiteId,
                        decoration: const InputDecoration(
                          labelText: 'Construction Site *',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        items: sites.map<DropdownMenuItem<String>>((site) {
                          return DropdownMenuItem<String>(
                            value: site.id,
                            child: SizedBox(
                              width: double.infinity,
                              child: Text(
                                site.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialog(() {
                            selectedSiteId = value;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        initialValue: fuelType,
                        decoration: const InputDecoration(
                          labelText: 'Fuel Type',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Diesel',
                            child: Text('Diesel'),
                          ),
                          DropdownMenuItem(
                            value: 'Petrol',
                            child: Text('Petrol'),
                          ),
                          DropdownMenuItem(
                            value: 'Engine Oil',
                            child: Text('Engine Oil'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setDialog(() {
                            fuelType = value;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: liters,
                        keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Liters *',
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: unitPrice,
                        keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Unit Price *',
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: meter,
                        keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Meter Reading *',
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: supplier,
                        decoration: const InputDecoration(
                          labelText: 'Supplier',
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: invoice,
                        decoration: const InputDecoration(
                          labelText: 'Invoice Number',
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: remarks,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Remarks',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (selectedEquipmentId == null ||
                        selectedSiteId == null ||
                        liters.text.trim().isEmpty ||
                        unitPrice.text.trim().isEmpty ||
                        meter.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Equipment, Site, Liters, Unit Price and Meter are required.',
                          ),
                        ),
                      );
                      return;
                    }

                    await widget.repository.create(
                      equipmentId: selectedEquipmentId!,
                      siteId: selectedSiteId!,
                      refueledAtUtc: DateTime.now(),
                      fuelType: fuelType,
                      liters: double.parse(liters.text),
                      unitPrice: double.parse(unitPrice.text),
                      meterReading: double.parse(meter.text),
                      supplierName: supplier.text.trim().isEmpty
                          ? null
                          : supplier.text.trim(),
                      invoiceNumber: invoice.text.trim().isEmpty
                          ? null
                          : invoice.text.trim(),
                      remarks: remarks.text.trim().isEmpty
                          ? null
                          : remarks.text.trim(),
                    );

                    if (context.mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (created == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.equipmentName == null
              ? 'Fuel Log'
              : '${widget.equipmentName} Fuel',
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createFuelLog,
        icon: const Icon(Icons.local_gas_station),
        label: const Text('Add Fuel'),
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
                  'Unable to load fuel log',
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

    if (_logs.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const [
            SizedBox(height: 140),
            Icon(Icons.local_gas_station_outlined, size: 64),
            SizedBox(height: 16),
            Center(child: Text('No fuel records found')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _buildSummary(),
          const SizedBox(height: 16),
          ..._logs.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _FuelCard(
              log: e,
              currency: _currency,
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.55,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _SummaryCard(
          title: 'Entries',
          value: '${_logs.length}',
          icon: Icons.receipt_long,
          color: Colors.blue,
        ),
        _SummaryCard(
          title: 'Liters',
          value: _totalLiters.toStringAsFixed(1),
          icon: Icons.local_gas_station,
          color: Colors.green,
        ),
        _SummaryCard(
          title: 'Total Cost',
          value: 'ETB ${_currency.format(_totalCost)}',
          icon: Icons.account_balance_wallet,
          color: Colors.purple,
        ),
        _SummaryCard(
          title: 'Avg Price',
          value: 'ETB ${_currency.format(_averagePrice)}',
          icon: Icons.analytics,
          color: Colors.orange,
        ),
      ],
    );
  }
}

class _FuelCard extends StatelessWidget {
  const _FuelCard({
    required this.log,
    required this.currency,
  });

  final EquipmentFuelLog log;
  final NumberFormat currency;

  String _date(DateTime value) {
    final d = value.toLocal();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.equipmentCode,
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge,
                      ),
                      Text(
                        log.equipmentName,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium,
                      ),
                    ],
                  ),
                ),
                Chip(label: Text(log.fuelType)),
              ],
            ),
            const Divider(height: 24),
            _InfoRow(
              label: 'Date',
              value: _date(log.refueledAtUtc),
            ),
            _InfoRow(
              label: 'Liters',
              value: '${log.liters.toStringAsFixed(1)} L',
            ),
            _InfoRow(
              label: 'Unit Price',
              value:
              'ETB ${currency.format(log.unitPrice)}',
            ),
            _InfoRow(
              label: 'Total',
              value:
              'ETB ${currency.format(log.totalCost)}',
            ),
            _InfoRow(
              label: 'Meter',
              value:
              log.meterReading.toStringAsFixed(1),
            ),
            if (log.siteName != null)
              _InfoRow(
                label: 'Site',
                value: log.siteName!,
              ),
            if (log.supplierName != null)
              _InfoRow(
                label: 'Supplier',
                value: log.supplierName!,
              ),
            if (log.invoiceNumber != null)
              _InfoRow(
                label: 'Invoice',
                value: log.invoiceNumber!,
              ),
            if (log.remarks != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(log.remarks!),
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
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const Spacer(),

            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 2),

            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
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