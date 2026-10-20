import 'package:flutter/material.dart';

import '../data/models/expense.dart';
import '../data/models/cost_code.dart';
import '../data/repositories/expense_repository.dart';
import '../data/repositories/cost_code_repository.dart';
import '../../procurement/data/models/vendor.dart';
import '../../procurement/data/repositories/vendor_repository.dart';
import '../../projects/data/models/project.dart';
import '../../projects/data/repositories/project_repository.dart';
import '../../sites/data/models/site.dart';
import '../../sites/data/repositories/site_repository.dart';
import 'expense_create_screen.dart';

class ExpenseDetailScreen extends StatefulWidget {
  const ExpenseDetailScreen({
    super.key,
    required this.expense,
    required this.repository,
    this.siteRepository,
    this.projectRepository,
    this.costCodeRepository,
    this.vendorRepository,
  });

  final Expense expense;
  final ExpenseRepository repository;

  final SiteRepository? siteRepository;
  final ProjectRepository? projectRepository;
  final CostCodeRepository? costCodeRepository;
  final VendorRepository? vendorRepository;

  @override
  State<ExpenseDetailScreen> createState() =>
      _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState
    extends State<ExpenseDetailScreen> {
  late Expense _expense;

  late final SiteRepository _siteRepository;
  late final ProjectRepository _projectRepository;
  late final CostCodeRepository _costCodeRepository;
  late final VendorRepository _vendorRepository;

  Site? _site;
  Project? _project;
  CostCode? _costCode;
  Vendor? _vendor;

  bool _isLoading = true;
  bool _isChangingStatus = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _expense = widget.expense;

    _siteRepository =
        widget.siteRepository ?? SiteRepository();
    _projectRepository =
        widget.projectRepository ?? ProjectRepository();
    _costCodeRepository =
        widget.costCodeRepository ?? CostCodeRepository();
    _vendorRepository =
        widget.vendorRepository ?? VendorRepository();

    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        widget.repository.getById(_expense.id),
        _siteRepository.getAll(),
        _projectRepository.getAll(),
        _costCodeRepository.getAll(),
        _vendorRepository.getAll(isActive: true),
      ]);

      final expense = results[0] as Expense;
      final sites = results[1] as List<Site>;
      final projects = results[2] as List<Project>;
      final costCodes = results[3] as List<CostCode>;
      final vendors = results[4] as List<Vendor>;

      Site? site;
      Project? project;
      CostCode? costCode;
      Vendor? vendor;

      for (final item in sites) {
        if (item.id == expense.constructionSiteId) {
          site = item;
          break;
        }
      }

      if (expense.projectId != null) {
        for (final item in projects) {
          if (item.id == expense.projectId) {
            project = item;
            break;
          }
        }
      }

      for (final item in costCodes) {
        if (item.id == expense.costCodeId) {
          costCode = item;
          break;
        }
      }

      if (expense.vendorId != null) {
        for (final item in vendors) {
          if (item.id == expense.vendorId) {
            vendor = item;
            break;
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _expense = expense;
        _site = site;
        _project = project;
        _costCode = costCode;
        _vendor = vendor;
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

  List<ExpenseStatus> _availableTransitions() {
    switch (_expense.status) {
      case ExpenseStatus.draft:
        return [
          ExpenseStatus.submitted,
          ExpenseStatus.cancelled,
        ];

      case ExpenseStatus.submitted:
        return [
          ExpenseStatus.approved,
          ExpenseStatus.rejected,
          ExpenseStatus.cancelled,
        ];

      case ExpenseStatus.approved:
        return [
          ExpenseStatus.paid,
        ];

      case ExpenseStatus.rejected:
        return [
          ExpenseStatus.submitted,
          ExpenseStatus.cancelled,
        ];

      case ExpenseStatus.paid:
      case ExpenseStatus.cancelled:
        return [];
    }
  }

  Future<void> _refresh() async {
    await _loadDetails();
  }

  Future<void> _changeStatus(
      ExpenseStatus nextStatus,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Change Status'),
          content: Text(
            'Change expense status to '
                '${nextStatus.displayName}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isChangingStatus = true;
    });

    try {
      await widget.repository.changeStatus(
        expenseId: _expense.id,
        status: nextStatus,
      );

      await _refresh();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status changed to '
                '${nextStatus.displayName}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isChangingStatus = false;
        });
      }
    }
  }

  String _money(double value) {
    return value.toStringAsFixed(2);
  }

  String _siteDisplayName() {
    if (_site == null) {
      return '—';
    }

    return '${_site!.siteCode} - ${_site!.name}';
  }

  String _projectDisplayName() {
    if (_project == null) {
      return '—';
    }

    return '${_project!.projectCode} - ${_project!.name}';
  }

  String _costCodeDisplayName() {
    if (_costCode == null) {
      return '—';
    }

    return '${_costCode!.code} - ${_costCode!.name}';
  }

  String _vendorDisplayName() {
    if (_expense.vendorId == null) {
      return 'No Vendor';
    }

    if (_vendor == null) {
      return '—';
    }

    return '${_vendor!.vendorCode} - ${_vendor!.name}';
  }

  bool get _canEdit =>
      _expense.status != ExpenseStatus.paid &&
          _expense.status != ExpenseStatus.cancelled;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_expense.expenseNumber),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading
                ? null
                : _refresh,
            icon: const Icon(Icons.refresh),
          ),
          if (_canEdit)
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final updated =
                await Navigator.of(context)
                    .push<bool>(
                  MaterialPageRoute(
                    builder: (_) =>
                        ExpenseCreateScreen(
                          repository:
                          widget.repository,
                          siteRepository:
                          _siteRepository,
                          projectRepository:
                          _projectRepository,
                          costCodeRepository:
                          _costCodeRepository,
                          vendorRepository:
                          _vendorRepository,
                          expense: _expense,
                        ),
                  ),
                );

                if (updated == true && mounted) {
                  await _refresh();
                }
              },
            ),
        ],
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
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 120),
            const Icon(
              Icons.error_outline,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              32,
            ),
            children: [
              _buildMainCard(context),

              const SizedBox(height: 16),

              _buildReferenceCard(context),

              const SizedBox(height: 16),

              if (_availableTransitions().isNotEmpty)
                _buildStatusCard(context),
            ],
          ),

          if (_isChangingStatus)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildMainCard(
      BuildContext context,
      ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _expense.expenseNumber,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall,
                  ),
                ),
                Chip(
                  label: Text(
                    _expense.status.displayName,
                  ),
                ),
              ],
            ),

            const Divider(height: 28),

            _InfoRow(
              label: 'Description',
              value: _expense.description,
            ),

            _InfoRow(
              label: 'Date',
              value: _formatDate(
                _expense.expenseDate,
              ),
            ),

            _InfoRow(
              label: 'Amount',
              value:
              '${_money(_expense.amount)} '
                  '${_expense.currencyCode}',
            ),

            _InfoRow(
              label: 'Tax',
              value:
              '${_money(_expense.taxAmount)} '
                  '${_expense.currencyCode}',
            ),

            _InfoRow(
              label: 'Exchange',
              value:
              _expense.exchangeRate
                  .toStringAsFixed(2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferenceCard(
      BuildContext context,
      ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Classification',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
            ),

            const SizedBox(height: 16),

            _InfoRow(
              label: 'Construction Site',
              value: _siteDisplayName(),
            ),

            _InfoRow(
              label: 'Project',
              value: _projectDisplayName(),
            ),

            _InfoRow(
              label: 'Cost Code',
              value: _costCodeDisplayName(),
            ),

            _InfoRow(
              label: 'Vendor',
              value: _vendorDisplayName(),
            ),

            const Divider(height: 24),

            _InfoRow(
              label: 'Reference',
              value:
              _expense.referenceNumber ??
                  '—',
            ),

            _InfoRow(
              label: 'Receipt',
              value:
              _expense.receiptDocumentUrl ??
                  '—',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
      BuildContext context,
      ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              'Change Status',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
              _availableTransitions()
                  .map(
                    (status) =>
                    FilledButton(
                      onPressed:
                      _isChangingStatus
                          ? null
                          : () =>
                          _changeStatus(
                            status,
                          ),
                      child: Text(
                        status.displayName,
                      ),
                    ),
              )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(
      DateTime date,
      ) {
    final local = date.toLocal();

    String two(int value) =>
        value.toString().padLeft(2, '0');

    return '${local.year}-'
        '${two(local.month)}-'
        '${two(local.day)}';
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
  Widget build(
      BuildContext context,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
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