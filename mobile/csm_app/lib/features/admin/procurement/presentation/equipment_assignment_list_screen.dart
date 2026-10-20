import 'package:flutter/material.dart';

import '../data/models/equipment_assignment.dart';
import '../data/repositories/equipment_assignment_repository.dart';
import 'equipment_assignment_create_screen.dart';
import 'equipment_assignment_detail_screen.dart';

class EquipmentAssignmentListScreen extends StatefulWidget {
  EquipmentAssignmentListScreen({
    super.key,
    EquipmentAssignmentRepository? repository,
  }) : repository =
      repository ?? EquipmentAssignmentRepository();

  final EquipmentAssignmentRepository repository;

  @override
  State<EquipmentAssignmentListScreen> createState() =>
      _EquipmentAssignmentListScreenState();
}

class _EquipmentAssignmentListScreenState
    extends State<EquipmentAssignmentListScreen> {
  List<EquipmentAssignment> _assignments = [];
  bool _isLoading = true;
  bool? _activeOnly;
  String? _errorMessage;

  int get _total => _assignments.length;

  int get _active =>
      _assignments.where((e) => e.isActive).length;

  int get _released =>
      _assignments.where((e) => !e.isActive).length;

  int get _projects =>
      _assignments
          .where((e) => e.projectId != null)
          .map((e) => e.projectId)
          .toSet()
          .length;

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
      final assignments = await widget.repository.getAll(
        activeOnly: _activeOnly,
      );

      if (!mounted) return;

      setState(() {
        _assignments = assignments;
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
        title: const Text('Equipment Assignments'),
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
                    value: true,
                    label: Text('Active'),
                    icon: Icon(Icons.assignment_outlined),
                  ),
                  ButtonSegment<bool?>(
                    value: false,
                    label: Text('Released'),
                    icon: Icon(
                      Icons.assignment_turned_in_outlined,
                    ),
                  ),
                ],
                selected: {_activeOnly},
                onSelectionChanged: (selection) {
                  setState(() {
                    _activeOnly = selection.first;
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
                  EquipmentAssignmentCreateScreen(
                    assignmentRepository: widget.repository,
                  ),
            ),
          );

          if (created == true && mounted) {
            await _load();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Assign Equipment'),
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
                'Unable to load assignments',
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
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_assignments.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Icon(
              Icons.assignment_outlined,
              size: 64,
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'No equipment assignments found.',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          24,
        ),
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 16),

          ..._assignments.map(
                (assignment) => Padding(
              padding:
              const EdgeInsets.only(bottom: 12),
              child: _AssignmentCard(
                assignment: assignment,
                onTap: () async {
                  final updated =
                  await Navigator.of(context)
                      .push<bool>(
                    MaterialPageRoute(
                      builder: (_) =>
                          EquipmentAssignmentDetailScreen(
                            assignment: assignment,
                            repository:
                            widget.repository,
                          ),
                    ),
                  );

                  if (updated == true &&
                      mounted) {
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
          title: 'Active',
          value: '$_active',
          icon: Icons.check_circle,
          color: Colors.green,
        ),
        _SummaryCard(
          title: 'Released',
          value: '$_released',
          icon:
          Icons.assignment_turned_in,
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

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.assignment,
    required this.onTap,
  });

  final EquipmentAssignment assignment;
  final VoidCallback onTap;

  String _formatDate(DateTime value) {
    final local = value.toLocal();

    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  String _formatMeter(double? value) {
    if (value == null) return '—';

    return value.toStringAsFixed(
      value.truncateToDouble() == value
          ? 0
          : 2,
    );
  }

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
                      Icons.assignment,
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
                          assignment.assignmentNumber,
                          style: theme
                              .textTheme.labelLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          assignment.equipmentCode,
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
                  Chip(
                    backgroundColor:
                    assignment.isActive
                        ? Colors.green
                        .withValues(
                      alpha: .12,
                    )
                        : Colors.orange
                        .withValues(
                      alpha: .12,
                    ),
                    label: Text(
                      assignment.isActive
                          ? 'Active'
                          : 'Released',
                      style: TextStyle(
                        color: assignment.isActive
                            ? Colors.green
                            : Colors.orange,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              _InfoRow(
                label: 'Equipment',
                value: assignment.equipmentName,
              ),
              _InfoRow(
                label: 'Site',
                value: assignment
                    .constructionSiteName,
              ),
              _InfoRow(
                label: 'Project',
                value:
                assignment.projectName ??
                    '—',
              ),
              _InfoRow(
                label: 'Assigned',
                value: _formatDate(
                  assignment.assignedAtUtc,
                ),
              ),
              _InfoRow(
                label: 'Released',
                value: assignment
                    .releasedAtUtc ==
                    null
                    ? '—'
                    : _formatDate(
                  assignment
                      .releasedAtUtc!,
                ),
              ),
              _InfoRow(
                label: 'Meter Start',
                value: _formatMeter(
                  assignment
                      .meterReadingAtAssignment,
                ),
              ),
              _InfoRow(
                label: 'Meter End',
                value: _formatMeter(
                  assignment
                      .meterReadingAtRelease,
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
                  .textTheme.headlineSmall,
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
      const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 145,
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