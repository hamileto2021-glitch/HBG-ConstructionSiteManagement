import 'package:flutter/material.dart';

import '../data/models/site_assignment/site_assignment.dart';
import '../data/repositories/employee_repository.dart';
import '../data/repositories/site_assignment_repository.dart';
import '../../sites/data/repositories/site_repository.dart';
import 'site_assignment_create_screen.dart';
import 'site_assignment_edit_screen.dart';

class SiteAssignmentListScreen extends StatefulWidget {
  const SiteAssignmentListScreen({
    super.key,
    required this.repository,
  });

  final SiteAssignmentRepository repository;

  @override
  State<SiteAssignmentListScreen> createState() =>
      _SiteAssignmentListScreenState();
}

class _SiteAssignmentListScreenState
    extends State<SiteAssignmentListScreen> {
  bool _isLoading = true;
  String? _error;
  List<SiteAssignment> _assignments = [];

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final assignments = await widget.repository.getAll();

      if (!mounted) {
        return;
      }

      setState(() {
        _assignments = assignments;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openCreateScreen() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SiteAssignmentCreateScreen(
          assignmentRepository: widget.repository,
          employeeRepository: EmployeeRepository(),
          siteRepository: SiteRepository(),
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadAssignments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Site Assignments'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadAssignments,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateScreen,
        icon: const Icon(Icons.add),
        label: const Text('Create'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAssignments,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading && _assignments.isEmpty) {
      return ListView(
        children: [
          SizedBox(
            height: 300,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      );
    }

    if (_error != null && _assignments.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Unable to load site assignments.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadAssignments,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      );
    }

    if (_assignments.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 180),
          Center(
            child: Text(
              'No site assignments found.',
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _assignments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildAssignmentCard(
          context,
          _assignments[index],
        );
      },
    );
  }

  Widget _buildAssignmentCard(
    BuildContext context,
    SiteAssignment assignment,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment_ind_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    assignment.employeeName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Chip(
                      label: Text(
                        assignment.isActive ? 'Active' : 'Inactive',
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: () async {
                        final updated =
                            await Navigator.of(context).push<SiteAssignment>(
                          MaterialPageRoute(
                            builder: (_) => SiteAssignmentEditScreen(
                              assignment: assignment,
                              repository: widget.repository,
                            ),
                          ),
                        );

                        if (updated != null && mounted) {
                          await _loadAssignments();
                        }
                      },
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Employee',
              value: assignment.employeeNumber,
            ),
            _InfoRow(
              label: 'Site',
              value: assignment.siteName,
            ),
            _InfoRow(
              label: 'Start date',
              value: _formatDate(assignment.startDate),
            ),
            if (assignment.endDate != null)
              _InfoRow(
                label: 'End date',
                value: _formatDate(assignment.endDate!),
              ),
            if (assignment.roleAtSite != null)
              _InfoRow(
                label: 'Role',
                value: assignment.roleAtSite!,
              ),
            _InfoRow(
              label: 'Primary',
              value: assignment.isPrimaryAssignment ? 'Yes' : 'No',
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();

    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
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

