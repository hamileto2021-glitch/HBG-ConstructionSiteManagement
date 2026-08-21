import 'package:flutter/material.dart';

import '../data/models/budget_line.dart';
import '../data/repositories/budget_line_repository.dart';
import 'budget_line_create_screen.dart';

class BudgetLineListScreen extends StatefulWidget {
  const BudgetLineListScreen({
    super.key,
    required this.budgetId,
    required this.repository,
  });

  final String budgetId;
  final BudgetLineRepository repository;

  @override
  State<BudgetLineListScreen> createState() =>
      _BudgetLineListScreenState();
}

class _BudgetLineListScreenState
    extends State<BudgetLineListScreen> {
  List<BudgetLine> _lines = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLines();
  }

  Future<void> _loadLines() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final lines = await widget.repository.getByBudget(
        widget.budgetId,
      );

      if (!mounted) return;

      setState(() {
        _lines = lines;
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
        title: const Text('Budget Lines'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadLines,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created =
              await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => BudgetLineCreateScreen(
                budgetId: widget.budgetId,
                repository: widget.repository,
              ),
            ),
          );

          if (created == true && mounted) {
            await _loadLines();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Line'),
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
                onPressed: _loadLines,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_lines.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadLines,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Icon(
              Icons.account_tree_outlined,
              size: 64,
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'No budget lines found.',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLines,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          100,
        ),
        itemCount: _lines.length,
        itemBuilder: (context, index) {
          final line = _lines[index];

          return _BudgetLineCard(
            line: line,
            onTap: () async {
              final updated =
                  await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => BudgetLineCreateScreen(
                    budgetId: widget.budgetId,
                    repository: widget.repository,
                    line: line,
                  ),
                ),
              );

              if (updated == true && mounted) {
                await _loadLines();
              }
            },
          );
        },
      ),
    );
  }
}

class _BudgetLineCard extends StatelessWidget {
  const _BudgetLineCard({
    required this.line,
    required this.onTap,
  });

  final BudgetLine line;
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: theme.colorScheme.primaryContainer,
                    ),
                    child: Icon(
                      Icons.account_tree_outlined,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      line.costCode,
                      style:
                          theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                  ),
                ],
              ),
              const Divider(height: 24),
              _InfoRow(
                label: 'Description',
                value:
                    line.description?.trim().isNotEmpty == true
                        ? line.description!
                        : '—',
              ),
              _InfoRow(
                label: 'Budgeted',
                value: _formatAmount(
                  line.budgetedAmount,
                ),
              ),
              _InfoRow(
                label: 'Revised',
                value: _formatAmount(
                  line.revisedAmount,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAmount(double value) {
    return value.toStringAsFixed(2);
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium,
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
