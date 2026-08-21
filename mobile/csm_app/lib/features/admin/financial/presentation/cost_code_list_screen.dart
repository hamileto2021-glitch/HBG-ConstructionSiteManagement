import 'package:flutter/material.dart';

import '../data/models/cost_code.dart';
import '../data/repositories/cost_code_repository.dart';
import 'cost_code_create_screen.dart';
import 'cost_code_detail_screen.dart';

class CostCodeListScreen extends StatefulWidget {
  CostCodeListScreen({
    super.key,
    CostCodeRepository? repository,
  }) : repository = repository ?? CostCodeRepository();

  final CostCodeRepository repository;

  @override
  State<CostCodeListScreen> createState() =>
      _CostCodeListScreenState();
}

class _CostCodeListScreenState
    extends State<CostCodeListScreen> {
  List<CostCode> _costCodes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCostCodes();
  }

  Future<void> _loadCostCodes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final costCodes =
          await widget.repository.getAll();

      if (!mounted) return;

      setState(() {
        _costCodes = costCodes;
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
        title: const Text('Cost Codes'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                _isLoading ? null : _loadCostCodes,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () async {
          final created =
              await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => CostCodeCreateScreen(
                repository: widget.repository,
              ),
            ),
          );

          if (created == true && mounted) {
            await _loadCostCodes();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Cost Code'),
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
                onPressed: _loadCostCodes,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_costCodes.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadCostCodes,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Icon(
              Icons.account_tree_outlined,
              size: 64,
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'No cost codes found.',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCostCodes,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          100,
        ),
        itemCount: _costCodes.length,
        itemBuilder: (context, index) {
          return _CostCodeCard(
            costCode: _costCodes[index],
            onTap: () async {
              final updated =
                  await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) =>
                      CostCodeDetailScreen(
                    costCode: _costCodes[index],
                    repository: widget.repository,
                  ),
                ),
              );

              if (updated == true && mounted) {
                await _loadCostCodes();
              }
            },
          );
        },
      ),
    );
  }
}

class _CostCodeCard extends StatelessWidget {
  const _CostCodeCard({
    required this.costCode,
    required this.onTap,
  });

  final CostCode costCode;
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
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(12),
                      color: theme
                          .colorScheme
                          .primaryContainer,
                    ),
                    child: Icon(
                      Icons.account_tree_outlined,
                      color: theme
                          .colorScheme
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
                          costCode.code,
                          style: theme
                              .textTheme
                              .labelLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          costCode.name,
                          style: theme
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      costCode.isActive
                          ? 'Active'
                          : 'Inactive',
                    ),
                    visualDensity:
                        VisualDensity.compact,
                  ),
                ],
              ),
              const Divider(height: 24),
              _InfoRow(
                label: 'Description',
                value:
                    costCode.description ?? '—',
              ),
              _InfoRow(
                label: 'Parent',
                value:
                    costCode.parentCostCodeId ??
                        '—',
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    costCode.isActive
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    costCode.isActive
                        ? 'Active'
                        : 'Inactive',
                    style:
                        theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
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
            width: 100,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium,
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
