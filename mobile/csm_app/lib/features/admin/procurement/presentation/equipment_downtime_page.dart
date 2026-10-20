
import 'package:flutter/material.dart';

import '../equipment_downtime/data/models/equipment_downtime.dart';
import '../equipment_downtime/data/repositories/equipment_downtime_repository.dart';

class EquipmentDowntimeScreen extends StatefulWidget {
  EquipmentDowntimeScreen({
    super.key,
    EquipmentDowntimeRepository? repository,
  }) : repository = repository ?? EquipmentDowntimeRepository();

  final EquipmentDowntimeRepository repository;

  @override
  State<EquipmentDowntimeScreen> createState() =>
      _EquipmentDowntimeScreenState();
}

class _EquipmentDowntimeScreenState
    extends State<EquipmentDowntimeScreen> {
  List<EquipmentDowntime> _records = [];
  bool _isLoading = true;
  bool? _openOnly;
  String? _errorMessage;

  int get _total => _records.length;

  int get _open =>
      _records.where((e) => e.isOpen).length;

  int get _closed =>
      _records.where((e) => !e.isOpen).length;

  double get _downtimeHours => _records.fold(
    0,
        (s, e) => s + (e.durationHours ?? 0),
  );

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
        openOnly: _openOnly,
      );

      if (!mounted) return;

      setState(() {
        _records = result;
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

  Future<void> _showCreateDialog() async {
    final equipmentId = TextEditingController();
    final number = TextEditingController();
    final reason = TextEditingController();
    final resolution = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> save() async {
              if (equipmentId.text.trim().isEmpty ||
                  number.text.trim().isEmpty ||
                  reason.text.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Equipment ID, Number and Reason are required.',
                    ),
                  ),
                );
                return;
              }

              setDialogState(() => saving = true);

              try {
                await widget.repository.create(
                  equipmentId: equipmentId.text.trim(),
                  startedAtUtc: DateTime.now().toUtc(),
                  downtimeNumber: number.text.trim(),
                  reason: reason.text.trim(),
                  resolution: resolution.text.trim().isEmpty
                      ? null
                      : resolution.text.trim(),
                );

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext, true);
              } catch (e) {
                if (!dialogContext.mounted) return;

                setDialogState(() => saving = false);

                ScaffoldMessenger.of(dialogContext)
                    .showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            }

            return AlertDialog(
              title:
              const Text('Record Equipment Downtime'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: equipmentId,
                      decoration: const InputDecoration(
                        labelText: 'Equipment ID',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: number,
                      decoration: const InputDecoration(
                        labelText: 'Downtime Number',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: reason,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Reason',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: resolution,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Resolution (Optional)',
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
                FilledButton.icon(
                  onPressed: saving ? null : save,
                  icon: const Icon(Icons.save),
                  label: Text(
                    saving ? 'Saving...' : 'Record',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    equipmentId.dispose();
    number.dispose();
    reason.dispose();
    resolution.dispose();

    if (created == true && mounted) {
      await _load();
    }
  }

  Future<void> _closeDowntime(
      EquipmentDowntime record,
      ) async {
    final resolution = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Close ${record.downtimeNumber}',
          ),
          content: TextField(
            controller: resolution,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Resolution',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await widget.repository.close(
      id: record.id,
      endedAtUtc: DateTime.now().toUtc(),
      resolution: resolution.text.trim().isEmpty
          ? null
          : resolution.text.trim(),
    );

    resolution.dispose();

    if (mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment Downtime'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton:
      FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Record'),
      ),
      body: Column(
        children: [
          Padding(
            padding:
            const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SegmentedButton<bool?>(
              segments: const [
                ButtonSegment<bool?>(
                  value: null,
                  label: Text('All'),
                ),
                ButtonSegment<bool?>(
                  value: true,
                  label: Text('Open'),
                ),
                ButtonSegment<bool?>(
                  value: false,
                  label: Text('Closed'),
                ),
              ],
              selected: {_openOnly},
              onSelectionChanged: (value) {
                setState(() {
                  _openOnly = value.first;
                });
                _load();
              },
            ),
          ),
          Expanded(child: _buildBody()),
        ],
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
              const Icon(Icons.error, size: 48),
              const SizedBox(height: 16),
              Text(_errorMessage!),
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

    if (_records.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const [
            SizedBox(height: 150),
            Icon(Icons.build_circle_outlined, size: 64),
            SizedBox(height: 16),
            Center(
              child: Text(
                'No downtime records found.',
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
        const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 16),
          ..._records.map(
                (record) => Padding(
              padding:
              const EdgeInsets.only(bottom: 12),
              child: _DowntimeCard(
                record: record,
                onClose: record.isOpen
                    ? () => _closeDowntime(record)
                    : null,
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
      physics:
      const NeverScrollableScrollPhysics(),
      children: [
        _SummaryCard(
          title: 'Total',
          value: '$_total',
          icon: Icons.assignment,
          color: Colors.blue,
        ),
        _SummaryCard(
          title: 'Open',
          value: '$_open',
          icon: Icons.warning_amber,
          color: Colors.red,
        ),
        _SummaryCard(
          title: 'Closed',
          value: '$_closed',
          icon: Icons.check_circle,
          color: Colors.green,
        ),
        _SummaryCard(
          title: 'Hours Lost',
          value: _downtimeHours.toStringAsFixed(1),
          icon: Icons.timer,
          color: Colors.orange,
        ),
      ],
    );
  }
}

class _DowntimeCard extends StatelessWidget {
  const _DowntimeCard({
    required this.record,
    this.onClose,
  });

  final EquipmentDowntime record;
  final VoidCallback? onClose;

  String _date(DateTime value) {
    final d = value.toLocal();

    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final open = record.isOpen;

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
                        record.downtimeNumber,
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        record.equipmentName,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium,
                      ),
                      Text(record.equipmentCode),
                    ],
                  ),
                ),
                Chip(
                  backgroundColor: open
                      ? Colors.red.withValues(alpha: .12)
                      : Colors.green.withValues(alpha: .12),
                  label: Text(
                    open ? 'OPEN' : 'CLOSED',
                    style: TextStyle(
                      color: open
                          ? Colors.red
                          : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _InfoRow(
              label: 'Site',
              value:
              record.constructionSiteName ?? '—',
            ),
            _InfoRow(
              label: 'Started',
              value: _date(record.startedAtUtc),
            ),
            _InfoRow(
              label: 'Ended',
              value: record.endedAtUtc == null
                  ? 'In Progress'
                  : _date(record.endedAtUtc!),
            ),
            _InfoRow(
              label: 'Duration',
              value: record.durationHours == null
                  ? 'Running'
                  : '${record.durationHours!.toStringAsFixed(1)} hrs',
            ),
            const SizedBox(height: 10),
            Text(
              'Reason',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium,
            ),
            const SizedBox(height: 4),
            Text(record.reason),
            if (record.resolution != null &&
                record.resolution!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Resolution',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium,
              ),
              const SizedBox(height: 4),
              Text(record.resolution!),
            ],
            if (onClose != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onClose,
                  icon: const Icon(Icons.check_circle),
                  label:
                  const Text('Close Downtime'),
                ),
              ),
            ],
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
      const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
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