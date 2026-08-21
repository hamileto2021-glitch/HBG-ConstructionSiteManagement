import 'package:flutter/material.dart';

import '../../procurement/data/models/vendor.dart';
import '../../procurement/data/repositories/vendor_repository.dart';
import '../../projects/data/models/project.dart';
import '../../projects/data/repositories/project_repository.dart';
import '../../sites/data/models/site.dart';
import '../../sites/data/repositories/site_repository.dart';
import '../data/models/cost_code.dart';
import '../data/models/expense.dart';
import '../data/repositories/cost_code_repository.dart';
import '../data/repositories/expense_repository.dart';

class ExpenseCreateScreen extends StatefulWidget {
  const ExpenseCreateScreen({
    super.key,
    required this.repository,
    this.siteRepository,
    this.projectRepository,
    this.costCodeRepository,
    this.vendorRepository,
    this.expense,
  });

  final ExpenseRepository repository;
  final SiteRepository? siteRepository;
  final ProjectRepository? projectRepository;
  final CostCodeRepository? costCodeRepository;
  final VendorRepository? vendorRepository;
  final Expense? expense;

  bool get isEditing => expense != null;

  @override
  State<ExpenseCreateScreen> createState() => _ExpenseCreateScreenState();
}

class _ExpenseCreateScreenState extends State<ExpenseCreateScreen> {
  late final SiteRepository _siteRepository;
  late final ProjectRepository _projectRepository;
  late final CostCodeRepository _costCodeRepository;
  late final VendorRepository _vendorRepository;

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _expenseNumberController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late final TextEditingController _taxAmountController;
  late final TextEditingController _currencyCodeController;
  late final TextEditingController _exchangeRateController;
  late final TextEditingController _referenceNumberController;
  late final TextEditingController _receiptDocumentUrlController;

  DateTime _expenseDate = DateTime.now();

  List<Site> _sites = [];
  List<Project> _projects = [];
  List<CostCode> _costCodes = [];
  List<Vendor> _vendors = [];

  String? _selectedSiteId;
  String? _selectedProjectId;
  String? _selectedCostCodeId;
  String? _selectedVendorId;

  bool _isLoadingLookups = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _siteRepository = widget.siteRepository ?? SiteRepository();
    _projectRepository = widget.projectRepository ?? ProjectRepository();
    _costCodeRepository = widget.costCodeRepository ?? CostCodeRepository();
    _vendorRepository = widget.vendorRepository ?? VendorRepository();

    final expense = widget.expense;

    _expenseNumberController = TextEditingController(
      text: expense?.expenseNumber ?? '',
    );

    _descriptionController = TextEditingController(
      text: expense?.description ?? '',
    );

    _amountController = TextEditingController(
      text: expense?.amount.toString() ?? '',
    );

    _taxAmountController = TextEditingController(
      text: expense?.taxAmount.toString() ?? '0',
    );

    _currencyCodeController = TextEditingController(
      text: expense?.currencyCode ?? 'ETB',
    );

    _exchangeRateController = TextEditingController(
      text: expense?.exchangeRate.toString() ?? '1',
    );

    _referenceNumberController = TextEditingController(
      text: expense?.referenceNumber ?? '',
    );

    _receiptDocumentUrlController = TextEditingController(
      text: expense?.receiptDocumentUrl ?? '',
    );

    if (expense != null) {
      _expenseDate = expense.expenseDate;
      _selectedSiteId = expense.constructionSiteId;
      _selectedProjectId = expense.projectId;
      _selectedCostCodeId = expense.costCodeId;
      _selectedVendorId = expense.vendorId;
    }

    _loadLookups();
  }

  @override
  void dispose() {
    _expenseNumberController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _taxAmountController.dispose();
    _currencyCodeController.dispose();
    _exchangeRateController.dispose();
    _referenceNumberController.dispose();
    _receiptDocumentUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    setState(() {
      _isLoadingLookups = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _siteRepository.getAll(),
        _projectRepository.getAll(),
        _costCodeRepository.getAll(),
        _vendorRepository.getAll(isActive: true),
      ]);

      if (!mounted) return;

      setState(() {
        _sites = results[0] as List<Site>;
        _projects = results[1] as List<Project>;
        _costCodes = (results[2] as List<CostCode>)
            .where((item) => item.isActive)
            .toList();
        _vendors = results[3] as List<Vendor>;

        _isLoadingLookups = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingLookups = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _selectExpenseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selected == null || !mounted) return;

    setState(() {
      _expenseDate = selected;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSiteId == null) {
      _showMessage('Please select a construction site.');
      return;
    }

    if (_selectedCostCodeId == null) {
      _showMessage('Please select a cost code.');
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());

    final taxAmount = double.tryParse(_taxAmountController.text.trim());

    final exchangeRate = double.tryParse(_exchangeRateController.text.trim());

    if (amount == null) {
      _showMessage('Enter a valid amount.');
      return;
    }

    if (taxAmount == null) {
      _showMessage('Enter a valid tax amount.');
      return;
    }

    if (exchangeRate == null) {
      _showMessage('Enter a valid exchange rate.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final expense = widget.expense;

      if (expense == null) {
        await widget.repository.create(
          constructionSiteId: _selectedSiteId!,
          projectId: _selectedProjectId,
          costCodeId: _selectedCostCodeId!,
          vendorId: _selectedVendorId,
          expenseNumber: _expenseNumberController.text.trim(),
          expenseDate: _expenseDate,
          description: _descriptionController.text.trim(),
          amount: amount,
          taxAmount: taxAmount,
          currencyCode: _currencyCodeController.text.trim(),
          exchangeRate: exchangeRate,
          referenceNumber: _optionalValue(_referenceNumberController.text),
          receiptDocumentUrl: _optionalValue(
            _receiptDocumentUrlController.text,
          ),
        );
      } else {
        await widget.repository.update(
          expenseId: expense.id,
          constructionSiteId: _selectedSiteId!,
          projectId: _selectedProjectId,
          costCodeId: _selectedCostCodeId!,
          vendorId: _selectedVendorId,
          expenseDate: _expenseDate,
          description: _descriptionController.text.trim(),
          amount: amount,
          taxAmount: taxAmount,
          currencyCode: _currencyCodeController.text.trim(),
          exchangeRate: exchangeRate,
          referenceNumber: _optionalValue(_referenceNumberController.text),
          receiptDocumentUrl: _optionalValue(
            _receiptDocumentUrlController.text,
          ),
        );
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _errorMessage = error.toString();
      });
    }
  }

  String? _optionalValue(String value) {
    final trimmed = value.trim();

    return trimmed.isEmpty ? null : trimmed;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.isEditing;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Expense' : 'Create Expense'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoadingLookups) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _sites.isEmpty && _costCodes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadLookups,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (_errorMessage != null) ...[
            _ErrorBanner(message: _errorMessage!),
            const SizedBox(height: 16),
          ],

          if (!widget.isEditing)
            TextFormField(
              controller: _expenseNumberController,
              decoration: const InputDecoration(
                labelText: 'Expense Number',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Expense number is required.';
                }

                return null;
              },
            ),

          if (!widget.isEditing) const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _selectedSiteId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Construction Site',
              border: OutlineInputBorder(),
            ),
            items: _sites
                .map(
                  (site) => DropdownMenuItem<String>(
                    value: site.id,
                    child: Text(
                      _siteLabel(site),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: _isSaving
                ? null
                : (value) {
                    setState(() {
                      _selectedSiteId = value;
                    });
                  },
            validator: (value) {
              if (value == null) {
                return 'Construction site is required.';
              }

              return null;
            },
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<String?>(
            initialValue: _selectedProjectId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Project (Optional)',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('No Project'),
              ),
              ..._projects.map(
                (project) => DropdownMenuItem<String?>(
                  value: project.id,
                  child: SizedBox(
                    width: 240,
                    child: Text(
                      _projectLabel(project),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
            onChanged: _isSaving
                ? null
                : (value) {
                    setState(() {
                      _selectedProjectId = value;
                    });
                  },
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _selectedCostCodeId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Cost Code',
              border: OutlineInputBorder(),
            ),
            items: _costCodes
                .map(
                  (costCode) => DropdownMenuItem<String>(
                    value: costCode.id,
                    child: Text(
                      '${costCode.code} — ${costCode.name}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: _isSaving
                ? null
                : (value) {
                    setState(() {
                      _selectedCostCodeId = value;
                    });
                  },
            validator: (value) {
              if (value == null) {
                return 'Cost code is required.';
              }

              return null;
            },
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<String?>(
            initialValue: _selectedVendorId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Vendor (Optional)',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('No Vendor'),
              ),
              ..._vendors.map(
                (vendor) => DropdownMenuItem<String?>(
                  value: vendor.id,
                  child: Text(
                    '${vendor.vendorCode} — ${vendor.name}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: _isSaving
                ? null
                : (value) {
                    setState(() {
                      _selectedVendorId = value;
                    });
                  },
          ),

          const SizedBox(height: 16),

          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Expense Date'),
            subtitle: Text(_formatDate(_expenseDate)),
            trailing: OutlinedButton(
              onPressed: _isSaving ? null : _selectExpenseDate,
              child: const Text('Change'),
            ),
          ),

          const SizedBox(height: 8),

          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Description is required.';
              }

              return null;
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount',
              border: OutlineInputBorder(),
            ),
            validator: _validateNumber,
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _taxAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Tax Amount',
              border: OutlineInputBorder(),
            ),
            validator: _validateNumber,
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _currencyCodeController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Currency Code',
              hintText: 'ETB',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Currency code is required.';
              }

              return null;
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _exchangeRateController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Exchange Rate',
              border: OutlineInputBorder(),
            ),
            validator: _validateNumber,
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _referenceNumberController,
            decoration: const InputDecoration(
              labelText: 'Reference Number (Optional)',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _receiptDocumentUrlController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Receipt Document URL (Optional)',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(widget.isEditing ? 'Save Changes' : 'Create Expense'),
          ),
        ],
      ),
    );
  }

  String? _validateNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }

    final number = double.tryParse(value.trim());

    if (number == null) {
      return 'Enter a valid number.';
    }

    if (number < 0) {
      return 'Value cannot be negative.';
    }

    return null;
  }

  String _siteLabel(Site site) {
    return site.name;
  }

  String _projectLabel(Project project) {
    return '${project.projectCode} — ${project.name}';
  }

  String _formatDate(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.error_outline,
          color: Theme.of(context).colorScheme.error,
        ),
        title: const Text('Unable to load Expense data'),
        subtitle: Text(message),
      ),
    );
  }
}
