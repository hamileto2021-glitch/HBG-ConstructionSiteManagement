import 'package:flutter/material.dart';

import '../data/models/equipment_assignment.dart';
import '../data/repositories/equipment_assignment_repository.dart';

class EquipmentAssignmentDetailScreen extends StatefulWidget {
  EquipmentAssignmentDetailScreen({
    super.key,
    required this.assignment,
    EquipmentAssignmentRepository? repository,
  }) : repository =
            repository ?? EquipmentAssignmentRepository();

  final EquipmentAssignment assignment;
  final EquipmentAssignmentRepository repository;

  @override
  State<EquipmentAssignmentDetailScreen> createState() =>
      _EquipmentAssignmentDetailScreenState();
}

class _EquipmentAssignmentDetailScreenState
    extends State<EquipmentAssignmentDetailScreen> {
  final _meterController = TextEditingController();

  bool _isReleasing = false;

  @override
  void dispose() {
    _meterController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();

    String two(int value) =>
        value.toString().padLeft(2, '0');

    return '${local.year}-${two(local.month)}-'
        '${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  String _formatMeter(double? value) {
    if (value == null) return '—';

    return value.toStringAsFixed(
      value.truncateToDouble() == value ? 0 : 2,
    );
  }

  Future<void> _release() async {
    final meterText = _meterController.text.trim();

    final meterReading = meterText.isEmpty
        ? null
        : double.tryParse(meterText);

    if (meterText.isNotEmpty &&
        (meterReading == null || meterReading < 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a valid non-negative meter reading.',
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Release Equipment'),
          content: Text(
            'Release ${widget.assignment.equipmentCode} '
            'from ${widget.assignment.constructionSiteName}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Release'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isReleasing = true;
    });

    try {
      await widget.repository.release(
        id: widget.assignment.id,
        releasedAtUtc: DateTime.now().toUtc(),
        meterReadingAtRelease: meterReading,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Equipment released successfully.',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isReleasing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignment = widget.assignment;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(assignment.assignmentNumber),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        assignment.isActive
                            ? Icons.assignment_outlined
                            : Icons
                                .assignment_turned_in_outlined,
                        size: 36,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          assignment.assignmentNumber,
                          style:
                              theme.textTheme.headlineSmall,
                        ),
                      ),
                      Chip(
                        label: Text(
                          assignment.isActive
                              ? 'Active'
                              : 'Released',
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  _InfoRow(
                    label: 'Equipment Code',
                    value: assignment.equipmentCode,
                  ),
                  _InfoRow(
                    label: 'Equipment',
                    value: assignment.equipmentName,
                  ),
                  _InfoRow(
                    label: 'Site',
                    value:
                        assignment.constructionSiteName,
                  ),
                  _InfoRow(
                    label: 'Project',
                    value:
                        assignment.projectName ?? '—',
                  ),
                  _InfoRow(
                    label: 'Assigned',
                    value:
                        _formatDateTime(
                      assignment.assignedAtUtc,
                    ),
                  ),
                  _InfoRow(
                    label: 'Meter at Assignment',
                    value: _formatMeter(
                      assignment
                          .meterReadingAtAssignment,
                    ),
                  ),
                  _InfoRow(
                    label: 'Released',
                    value:
                        assignment.releasedAtUtc == null
                            ? '—'
                            : _formatDateTime(
                                assignment
                                    .releasedAtUtc!,
                              ),
                  ),
                  _InfoRow(
                    label: 'Meter at Release',
                    value: _formatMeter(
                      assignment.meterReadingAtRelease,
                    ),
                  ),
                  if (assignment.remarks != null &&
                      assignment.remarks!
                          .trim()
                          .isNotEmpty)
                    _InfoRow(
                      label: 'Remarks',
                      value: assignment.remarks!,
                    ),
                ],
              ),
            ),
          ),
          if (assignment.isActive) ...[
            const SizedBox(height: 20),
            Text(
              'Release Equipment',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _meterController,
              enabled: !_isReleasing,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Meter Reading at Release',
                border: OutlineInputBorder(),
                hintText: 'Optional',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed:
                    _isReleasing ? null : _release,
                icon: _isReleasing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons
                            .assignment_turned_in_outlined,
                      ),
                label: Text(
                  _isReleasing
                      ? 'Releasing...'
                      : 'Release Equipment',
                ),
              ),
            ),
          ],
        ],
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
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
