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
      final records = await widget.repository.getAll(
        openOnly: _openOnly,
      );

      if (!mounted) return;

      setState(() {
        _records = records;
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
    final equipmentIdController = TextEditingController();
    final downtimeNumberController = TextEditingController();
    final reasonController = TextEditingController();
    final resolutionController = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        bool saving = false;
        DateTime startedAt = DateTime.now();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> save() async {
              final equipmentId =
              equipmentIdController.text.trim();
              final downtimeNumber =
              downtimeNumberController.text.trim();
              final reason =
              reasonController.text.trim();

              if (equipmentId.isEmpty ||
                  downtimeNumber.isEmpty ||
                  reason.isEmpty) {
                if (!dialogContext.mounted) return;

                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Equipment ID, downtime number and reason are required.',
                    ),
                  ),
                );
                return;
              }

              setDialogState(() {
                saving = true;
              });

              try {
                await widget.repository.create(
                  equipmentId: equipmentId,
                  startedAtUtc: startedAt.toUtc(),
                  downtimeNumber: downtimeNumber,
                  reason: reason,
                  resolution:
                  resolutionController.text.trim().isEmpty
                      ? null
                      : resolutionController.text.trim(),
                );

                if (!dialogContext.mounted) return;

                Navigator.of(dialogContext).pop(true);
              } catch (error) {
                if (!dialogContext.mounted) return;

                setDialogState(() {
                  saving = false;
                });

                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(error.toString()),
                  ),
                );
              }
            }

            return AlertDialog(
              title: const Text('Record Equipment Downtime'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: equipmentIdController,
                      enabled: !saving,
                      decoration: const InputDecoration(
                        labelText: 'Equipment ID',
                        hintText: 'Enter equipment ID',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: downtimeNumberController,
                      enabled: !saving,
                      decoration: const InputDecoration(
                        labelText: 'Downtime Number',
                        hintText: 'e.g. DT-002',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: reasonController,
                      enabled: !saving,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Reason',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: resolutionController,
                      enabled: !saving,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Resolution',
                        hintText: 'Optional',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () =>
                      Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: saving ? null : save,
                  icon: saving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    saving ? 'Saving...' : 'Record Downtime',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    equipmentIdController.dispose();
    downtimeNumberController.dispose();
    reasonController.dispose();
    resolutionController.dispose();

    if (created == true && mounted) {
      await _load();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Equipment downtime recorded.'),
        ),
      );
    }
  }

  Future<void> _closeDowntime(
      EquipmentDowntime record,
      ) async {
    final resolutionController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> close() async {
              setDialogState(() {
                saving = true;
              });

              try {
                await widget.repository.close(
                  id: record.id,
                  endedAtUtc: DateTime.now().toUtc(),
                  resolution:
                  resolutionController.text.trim().isEmpty
                      ? null
                      : resolutionController.text.trim(),
                );

                if (!dialogContext.mounted) return;

                Navigator.of(dialogContext).pop(true);
              } catch (error) {
                if (!dialogContext.mounted) return;

                setDialogState(() {
                  saving = false;
                });

                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(error.toString()),
                  ),
                );
              }
            }

            return AlertDialog(
              title: Text(
                'Close ${record.downtimeNumber}',
              ),
              content: TextField(
                controller: resolutionController,
                enabled: !saving,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Resolution',
                  hintText: 'Describe how the issue was resolved',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () =>
                      Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: saving ? null : close,
                  icon: saving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(
                    Icons.check_circle_outline,
                  ),
                  label: Text(
                    saving ? 'Closing...' : 'Close Downtime',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    resolutionController.dispose();

    if (confirmed == true && mounted) {
      await _load();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Equipment downtime closed.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment Downtime'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Record Downtime'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              8,
            ),
            child: SegmentedButton<bool?>(
              segments: const [
                ButtonSegment<bool?>(
                  value: null,
                  label: Text('All'),
                  icon: Icon(Icons.list_alt),
                ),
                ButtonSegment<bool?>(
                  value: true,
                  label: Text('Open'),
                  icon: Icon(
                    Icons.warning_amber_outlined,
                  ),
                ),
                ButtonSegment<bool?>(
                  value: false,
                  label: Text('Closed'),
                  icon: Icon(
                    Icons.check_circle_outline,
                  ),
                ),
              ],
              selected: {_openOnly},
              onSelectionChanged: (selection) {
                setState(() {
                  _openOnly = selection.first;
                });
                _load();
              },
            ),
          ),
          Expanded(
            child: _buildBody(),
          ),
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

    if (_records.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Icon(
              Icons.build_circle_outlined,
              size: 64,
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'No equipment downtime records found.',
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
          100,
        ),
        itemCount: _records.length,
        itemBuilder: (context, index) {
          final record = _records[index];

          return _DowntimeCard(
            record: record,
            onClose: record.isOpen
                ? () => _closeDowntime(record)
                : null,
          );
        },
      ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOpen = record.isOpen;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    record.downtimeNumber,
                    style:
                    theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  avatar: Icon(
                    isOpen
                        ? Icons.warning_amber_outlined
                        : Icons.check_circle_outline,
                    size: 18,
                  ),
                  label: Text(
                    isOpen ? 'OPEN' : 'CLOSED',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${record.equipmentCode} — '
                  '${record.equipmentName}',
              style: theme.textTheme.titleSmall,
            ),
            if (record.constructionSiteName != null) ...[
              const SizedBox(height: 4),
              Text(
                'Site: ${record.constructionSiteName}',
              ),
            ],
            const Divider(height: 24),
            _InfoRow(
              label: 'Started',
              value: _formatDateTime(
                record.startedAtUtc,
              ),
            ),
            _InfoRow(
              label: 'Ended',
              value: record.endedAtUtc == null
                  ? 'Still open'
                  : _formatDateTime(
                record.endedAtUtc!,
              ),
            ),
            _InfoRow(
              label: 'Duration',
              value: record.durationHours == null
                  ? 'In progress'
                  : '${record.durationHours!.toStringAsFixed(2)} hours',
            ),
            const SizedBox(height: 10),
            Text(
              'Reason',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(record.reason),
            if (record.resolution != null) ...[
              const SizedBox(height: 10),
              Text(
                'Resolution',
                style: theme.textTheme.labelLarge,
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
                  icon: const Icon(
                    Icons.check_circle_outline,
                  ),
                  label: const Text(
                    'Close Downtime',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatDateTime(DateTime value) {
    final local = value.toLocal();

    String two(int value) =>
        value.toString().padLeft(2, '0');

    return '${local.year}-${two(local.month)}-'
        '${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
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
            width: 80,
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