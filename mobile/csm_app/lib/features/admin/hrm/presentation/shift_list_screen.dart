import 'package:flutter/material.dart';

import '../data/models/shift.dart';
import '../data/repositories/shift_repository.dart';

class ShiftListScreen extends StatefulWidget {
  const ShiftListScreen({
    super.key,
    required this.repository,
  });

  final ShiftRepository repository;

  @override
  State<ShiftListScreen> createState() =>
      _ShiftListScreenState();
}

class _ShiftListScreenState
    extends State<ShiftListScreen> {
  bool _loading = true;
  String? _error;
  List<Shift> _shifts = [];

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
      final result = await widget.repository.getAll();

      if (!mounted) return;

      setState(() {
        _shifts = result;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Create'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 16),
          Center(child: Text(_error!)),
        ],
      );
    }

    if (_shifts.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 180),
          Icon(Icons.schedule, size: 64),
          SizedBox(height: 16),
          Center(child: Text('No shifts available.')),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _shifts.length,
      separatorBuilder: (context, index) =>
      const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final shift = _shifts[index];

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
                            shift.code,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            shift.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium,
                          ),
                        ],
                      ),
                    ),
                    Chip(
                      backgroundColor:
                      shift.isActive
                          ? Colors.green.withValues(alpha: .12)
                          : Colors.grey.withValues(alpha: .12),
                      label: Text(
                        shift.isActive
                            ? 'Active'
                            : 'Inactive',
                        style: TextStyle(
                          color: shift.isActive
                              ? Colors.green
                              : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    const Icon(Icons.access_time, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${shift.startTime} → ${shift.endTime}',
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _InfoTile(
                        label: 'Hours',
                        value:
                        shift.standardHours
                            .toStringAsFixed(1),
                      ),
                    ),
                    Expanded(
                      child: _InfoTile(
                        label: 'Grace',
                        value:
                        '${shift.gracePeriodMinutes} min',
                      ),
                    ),
                  ],
                ),

                if (shift.isNightShift) ...[
                  const SizedBox(height: 12),
                  const Chip(
                    avatar: Icon(Icons.dark_mode, size: 18),
                    label: Text('Night Shift'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}