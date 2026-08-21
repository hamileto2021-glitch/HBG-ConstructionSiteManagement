import 'package:flutter/material.dart';

import '../../projects/data/models/project.dart';
import '../../projects/data/repositories/project_repository.dart';
import '../../sites/data/models/site.dart';
import '../../sites/data/repositories/site_repository.dart';
import '../data/repositories/budget_repository.dart';

class BudgetCreateScreen extends StatefulWidget {
  BudgetCreateScreen({
    super.key,
    required this.repository,
    SiteRepository? siteRepository,
    ProjectRepository? projectRepository,
  }) : siteRepository = siteRepository ?? SiteRepository(),
       projectRepository = projectRepository ?? ProjectRepository();

  final BudgetRepository repository;
  final SiteRepository siteRepository;
  final ProjectRepository projectRepository;

  @override
  State<BudgetCreateScreen> createState() => _BudgetCreateScreenState();
}

class _BudgetCreateScreenState extends State<BudgetCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _budgetNumberController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _currencyCodeController = TextEditingController(text: 'ETB');

  List<Site> _sites = [];
  List<Project> _projects = [];

  String? _selectedSiteId;
  String? _selectedProjectId;

  DateTime? _effectiveFrom;
  DateTime? _effectiveTo;

  bool _isLoadingSites = true;
  bool _isLoadingProjects = false;
  bool _isSaving = false;

  String? _siteErrorMessage;
  String? _projectErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadSites();
  }

  @override
  void dispose() {
    _budgetNumberController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _totalAmountController.dispose();
    _currencyCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadSites() async {
    try {
      final sites = await widget.siteRepository.getAll();

      if (!mounted) return;

      setState(() {
        _sites = sites.where((site) => site.isActive).toList();
        _isLoadingSites = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingSites = false;
        _siteErrorMessage = error.toString();
      });
    }
  }

  Future<void> _loadProjects(String siteId) async {
    setState(() {
      _isLoadingProjects = true;
      _projectErrorMessage = null;
      _projects = [];
      _selectedProjectId = null;
    });

    try {
      final projects = await widget.projectRepository.getAll(
        constructionSiteId: siteId,
      );

      if (!mounted) return;

      setState(() {
        _projects = projects;
        _isLoadingProjects = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingProjects = false;
        _projectErrorMessage = error.toString();
      });
    }
  }

  Future<void> _selectDate({required bool isStart}) async {
    final initialDate = isStart
        ? (_effectiveFrom ?? DateTime.now())
        : (_effectiveTo ?? _effectiveFrom ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (!mounted || picked == null) {
      return;
    }

    setState(() {
      if (isStart) {
        _effectiveFrom = picked;

        if (_effectiveTo != null && _effectiveTo!.isBefore(picked)) {
          _effectiveTo = null;
        }
      } else {
        _effectiveTo = picked;
      }
    });
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSiteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a construction site.')),
      );
      return;
    }

    final totalAmount = double.tryParse(_totalAmountController.text.trim());

    if (totalAmount == null || totalAmount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid total amount.')),
      );
      return;
    }

    if (_effectiveFrom != null &&
        _effectiveTo != null &&
        _effectiveTo!.isBefore(_effectiveFrom!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Effective To cannot be before Effective From.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.repository.create(
        constructionSiteId: _selectedSiteId!,
        projectId: _selectedProjectId,
        budgetNumber: _budgetNumberController.text.trim(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        totalAmount: totalAmount,
        currencyCode: _currencyCodeController.text.trim().toUpperCase(),
        effectiveFrom: _effectiveFrom,
        effectiveTo: _effectiveTo,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget created successfully.')),
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Not selected';
    }

    String two(int value) => value.toString().padLeft(2, '0');

    return '${date.year}-${two(date.month)}-'
        '${two(date.day)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Budget')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_isLoadingSites)
              const InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Construction Site',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Loading sites...'),
                  ],
                ),
              )
            else if (_siteErrorMessage != null)
              _ErrorField(
                message: 'Construction sites could not be loaded.',
                onRetry: _loadSites,
              )
            else
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
                        child: Text('${site.siteCode} - ${site.name}'),
                      ),
                    )
                    .toList(),
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _selectedSiteId = value;
                          _projects = [];
                          _selectedProjectId = null;
                        });

                        _loadProjects(value);
                      },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Select a construction site';
                  }

                  return null;
                },
              ),
            const SizedBox(height: 16),
            if (_selectedSiteId != null)
              if (_isLoadingProjects)
                const InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Project',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Loading projects...'),
                    ],
                  ),
                )
              else if (_projectErrorMessage != null)
                Text(
                  'Projects could not be loaded. '
                  'You can continue without selecting a project.',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else
                DropdownButtonFormField<String?>(
                  initialValue: _selectedProjectId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Project',
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
                        child: Text('${project.projectCode} - ${project.name}'),
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
            TextFormField(
              controller: _budgetNumberController,
              enabled: !_isSaving,
              decoration: const InputDecoration(
                labelText: 'Budget Number',
                hintText: 'e.g. BUD-2026-001',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a budget number';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              enabled: !_isSaving,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a budget name';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              enabled: !_isSaving,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _totalAmountController,
              enabled: !_isSaving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Total Amount',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final amount = double.tryParse(value?.trim() ?? '');

                if (amount == null || amount < 0) {
                  return 'Enter a valid amount';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _currencyCodeController,
              enabled: !_isSaving,
              textCapitalization: TextCapitalization.characters,
              maxLength: 3,
              decoration: const InputDecoration(
                labelText: 'Currency Code',
                hintText: 'ETB',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a currency code';
                }

                if (value.trim().length != 3) {
                  return 'Use a 3-letter currency code';
                }

                return null;
              },
            ),
            const SizedBox(height: 8),
            _DateField(
              label: 'Effective From',
              value: _formatDate(_effectiveFrom),
              enabled: !_isSaving,
              onTap: () => _selectDate(isStart: true),
            ),
            const SizedBox(height: 12),
            _DateField(
              label: 'Effective To',
              value: _formatDate(_effectiveTo),
              enabled: !_isSaving,
              onTap: () => _selectDate(isStart: false),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _create,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Saving...' : 'Create Budget'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(value),
      ),
    );
  }
}

class _ErrorField extends StatelessWidget {
  const _ErrorField({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Construction Site',
        border: OutlineInputBorder(),
      ),
      child: Row(
        children: [
          Expanded(child: Text(message)),
          IconButton(
            tooltip: 'Retry',
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}
