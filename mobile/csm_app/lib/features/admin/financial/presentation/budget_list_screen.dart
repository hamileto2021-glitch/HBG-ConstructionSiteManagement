import 'package:flutter/material.dart';

import '../data/models/budget.dart';
import '../data/repositories/budget_repository.dart';
import 'budget_create_screen.dart';
import 'budget_detail_screen.dart';

class BudgetListScreen extends StatefulWidget {
  BudgetListScreen({
    super.key,
    BudgetRepository? repository,
  }) : repository = repository ?? BudgetRepository();

  final BudgetRepository repository;

  @override
  State<BudgetListScreen> createState() =>
      _BudgetListScreenState();
}

class _BudgetListScreenState
    extends State<BudgetListScreen> {
  List<Budget> _budgets = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final budgets =
          await widget.repository.getAll();

      if (!mounted) return;

      setState(() {
        _budgets = budgets;
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
        title: const Text('Budgets'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                _isLoading ? null : _loadBudgets,
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
              builder: (_) => BudgetCreateScreen(
                repository: widget.repository,
              ),
            ),
          );

          if (created == true && mounted) {
            await _loadBudgets();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Budget'),
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
                onPressed: _loadBudgets,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_budgets.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadBudgets,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'No budgets found.',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBudgets,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          100,
        ),
        itemCount: _budgets.length,
        itemBuilder: (context, index) {
          final budget = _budgets[index];

          return _BudgetCard(
            budget: budget,
            onTap: () async {
              final updated =
                  await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) =>
                      BudgetDetailScreen(
                    budget: budget,
                    repository: widget.repository,
                  ),
                ),
              );

              if (updated == true && mounted) {
                await _loadBudgets();
              }
            },
          );
        },
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.budget,
    required this.onTap,
  });

  final Budget budget;
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
                      Icons
                          .account_balance_wallet_outlined,
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
                          budget.budgetNumber,
                          style: theme
                              .textTheme
                              .labelLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          budget.name,
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
                  _StatusChip(
                    status: _statusLabel(
                      budget.status,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _InfoRow(
                label: 'Amount',
                value:
                    '${budget.totalAmount} ${budget.currencyCode}',
              ),
              _InfoRow(
                label: 'Site',
                value: budget.constructionSiteId,
              ),
              _InfoRow(
                label: 'Project',
                value:
                    budget.projectId ?? '—',
              ),
              if (budget.description != null)
                _InfoRow(
                  label: 'Description',
                  value: budget.description!,
                ),
              if (budget.effectiveFrom != null)
                _InfoRow(
                  label: 'Effective From',
                  value: _formatDate(
                    budget.effectiveFrom!,
                  ),
                ),
              if (budget.effectiveTo != null)
                _InfoRow(
                  label: 'Effective To',
                  value: _formatDate(
                    budget.effectiveTo!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _statusLabel(
    BudgetStatus status,
  ) {
    switch (status) {
      case BudgetStatus.draft:
        return 'Draft';
      case BudgetStatus.pendingApproval:
        return 'Pending Approval';
      case BudgetStatus.approved:
        return 'Approved';
      case BudgetStatus.active:
        return 'Active';
      case BudgetStatus.closed:
        return 'Closed';
      case BudgetStatus.cancelled:
        return 'Cancelled';
    }
  }

  static String _formatDate(
    DateTime date,
  ) {
    final local = date.toLocal();

    String two(int value) =>
        value.toString().padLeft(2, '0');

    return '${local.year}-${two(local.month)}-'
        '${two(local.day)}';
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
      visualDensity:
          VisualDensity.compact,
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
            width: 110,
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
