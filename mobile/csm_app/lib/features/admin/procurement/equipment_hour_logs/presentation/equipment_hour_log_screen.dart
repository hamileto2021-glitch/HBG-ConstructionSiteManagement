import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models/equipment_hour_log.dart';
import 'package:csm_app/features/admin/equipment/data/repositories/equipment_hour_repository.dart';

import '../../data/models/equipment.dart';
import '../../data/repositories/equipment_repository.dart';

import 'package:csm_app/features/admin/sites/data/models/site.dart';
import 'package:csm_app/features/admin/sites/data/repositories/site_repository.dart';
import '../data/repositories/equipment_hour_log_repository.dart';

class EquipmentHourLogScreen extends StatefulWidget {
  EquipmentHourLogScreen({
    super.key,
    this.equipmentId,
    this.equipmentName,
    EquipmentHourLogRepository? repository,
    EquipmentHourRepository? syncRepository,
  })  : repository = repository ?? EquipmentHourLogRepository(),
        syncRepository = syncRepository ?? EquipmentHourRepository();

  final String? equipmentId;
  final String? equipmentName;

  // Read existing logs
  final EquipmentHourLogRepository repository;

  // Create online/offline logs
  final EquipmentHourRepository syncRepository;

  @override
  State<EquipmentHourLogScreen> createState() =>
      _EquipmentHourLogScreenState();
}

class _EquipmentHourLogScreenState
    extends State<EquipmentHourLogScreen> {
  final NumberFormat _number = NumberFormat('#,##0.0');

  List<EquipmentHourLog> _logs = [];
  bool _loading = true;
  String? _error;

  double get _hoursWorked =>
      _logs.fold(0, (s, e) => s + e.hoursWorked);

  double get _currentMeter =>
      _logs.isEmpty ? 0 : _logs.first.currentMeterReading;

  int get _operators => _logs
      .map((e) => e.operatorName)
      .whereType<String>()
      .toSet()
      .length;

  int get _projects => _logs
      .map((e) => e.projectName)
      .whereType<String>()
      .toSet()
      .length;

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

  Future<void> _createLog() async {
    String? selectedEquipmentId = widget.equipmentId;
    String? selectedSiteId;

    List<Equipment> equipmentList = [];
    List<Site> sites = [];

    final previous = TextEditingController();
    final current = TextEditingController();
    final operator = TextEditingController();
    final activity = TextEditingController();
    final remarks = TextEditingController();

    equipmentList = await EquipmentRepository().getAll();
    sites = await SiteRepository().getAll();

    if (!mounted) return;



    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (context, setDialog) {
            Future<void> save() async {
              if (selectedEquipmentId == null ||
                  selectedSiteId == null ||
                  previous.text.trim().isEmpty ||
                  current.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Equipment, Site and both meter readings are required.',
                    ),
                  ),
                );
                return;
              }

              setDialog(() => saving = true);
              debugPrint('Equipment ID = $selectedEquipmentId');

              try {
                await widget.syncRepository.create(
                  equipmentId: selectedEquipmentId!,
                  projectId: selectedSiteId!,
                  workDate: DateTime.now(),
                  startHour: double.parse(previous.text),
                  endHour: double.parse(current.text),
                  operatorName: operator.text.trim(),
                  remarks: remarks.text.trim().isEmpty
                      ? null
                      : remarks.text.trim(),
                );

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext, true);
              } catch (e) {
                setDialog(() => saving = false);

                ScaffoldMessenger.of(dialogContext)
                    .showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            }

            return AlertDialog(
              title: const Text('New Hour Entry'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.equipmentId == null)
                      DropdownButtonFormField<String>(
                        isExpanded: true,
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
                          setDialog(() => selectedEquipmentId = value);
                        },
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: previous,
                      keyboardType:
                      TextInputType.number,
                      decoration: const InputDecoration(
                        labelText:
                        'Previous Meter *',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: current,
                      keyboardType:
                      TextInputType.number,
                      decoration: const InputDecoration(
                        labelText:
                        'Current Meter *',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: operator,
                      decoration: const InputDecoration(
                        labelText: 'Operator',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedSiteId,
                      decoration: const InputDecoration(
                        labelText: 'Construction Site *',
                      ),
                      items: sites.map((site) {
                        return DropdownMenuItem(
                          value: site.id,
                          child: Text(
                            site.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialog(() => selectedSiteId = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: activity,
                      decoration: const InputDecoration(
                        labelText: 'Activity',
                      ),
                    ),
                    const SizedBox(height: 12),
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
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(
                    dialogContext,
                    false,
                  ),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving ? null : save,
                  child: Text(
                    saving ? 'Saving...' : 'Save',
                  ),
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
              ? 'Hour Meter Log'
              : '${widget.equipmentName} Hours',
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton:
      FloatingActionButton.extended(
        onPressed: _createLog,
        icon: const Icon(Icons.timer),
        label: const Text('Add Hours'),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(
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
      );
    }

    if (_logs.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const [
            SizedBox(height: 140),
            Icon(Icons.timer_outlined, size: 64),
            SizedBox(height: 16),
            Center(
              child: Text('No hour logs found'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding:
        const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _buildSummary(),
          const SizedBox(height: 16),
          ..._logs.map(
                (e) => Padding(
              padding:
              const EdgeInsets.only(bottom: 12),
              child: _HourCard(log: e),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics:
      const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.55,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _SummaryCard(
          title: 'Hours Worked',
          value: _number.format(_hoursWorked),
          icon: Icons.timer,
          color: Colors.blue,
        ),
        _SummaryCard(
          title: 'Current Meter',
          value: _number.format(_currentMeter),
          icon: Icons.speed,
          color: Colors.green,
        ),
        _SummaryCard(
          title: 'Operators',
          value: '$_operators',
          icon: Icons.person,
          color: Colors.orange,
        ),
        _SummaryCard(
          title: 'Projects',
          value: '$_projects',
          icon: Icons.business,
          color: Colors.purple,
        ),
      ],
    );
  }
}

class _HourCard extends StatelessWidget {
  const _HourCard({required this.log});

  final EquipmentHourLog log;

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
                Chip(
                  label: Text(
                    '${log.hoursWorked.toStringAsFixed(1)} hrs',
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _InfoRow(
              label: 'Date',
              value: _date(log.loggedAtUtc),
            ),
            _InfoRow(
              label: 'Previous',
              value: log.previousMeterReading
                  .toStringAsFixed(1),
            ),
            _InfoRow(
              label: 'Current',
              value: log.currentMeterReading
                  .toStringAsFixed(1),
            ),
            if (log.operatorName != null)
              _InfoRow(
                label: 'Operator',
                value: log.operatorName!,
              ),
            if (log.projectName != null)
              _InfoRow(
                label: 'Project',
                value: log.projectName!,
              ),
            if (log.activity != null)
              _InfoRow(
                label: 'Activity',
                value: log.activity!,
              ),
            if (log.remarks != null)
              Padding(
                padding:
                const EdgeInsets.only(top: 8),
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