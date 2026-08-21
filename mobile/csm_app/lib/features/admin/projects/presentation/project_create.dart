import 'package:flutter/material.dart';

import '../data/repositories/project_repository.dart';
import '../../sites/data/models/site.dart';
import '../../sites/data/repositories/site_repository.dart';

class ProjectCreateScreen extends StatefulWidget {
  const ProjectCreateScreen({
    super.key,
    required this.repository,
  });

  final ProjectRepository repository;

  @override
  State<ProjectCreateScreen> createState() => _ProjectCreateScreenState();
}

class _ProjectCreateScreenState extends State<ProjectCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _siteRepository = SiteRepository();
  List<Site> _sites = const [];
  Site? _selectedSite;
  bool _isLoadingSites = true;
  final _projectCodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contractValueController = TextEditingController();

  DateTime? _plannedStartDate;
  DateTime? _plannedEndDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSites();
  }

  @override
  void dispose() {
    _projectCodeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _contractValueController.dispose();
    super.dispose();
  }

  Future<void> _loadSites() async {
    try {
      final sites = await _siteRepository.getAll();

      if (!mounted) {
        return;
      }

      setState(() {
        _sites = sites;
        _isLoadingSites = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingSites = false;
      });

      _showMessage(error.toString());
    }
  }

  Future<void> _selectStartDate() async {
    final date = await _selectDate(
      initialDate: _plannedStartDate ?? DateTime.now(),
    );

    if (date == null || !mounted) {
      return;
    }

    setState(() {
      _plannedStartDate = date;

      if (_plannedEndDate != null &&
          _plannedEndDate!.isBefore(date)) {
        _plannedEndDate = null;
      }
    });
  }

  Future<void> _selectEndDate() async {
    final initialDate =
        _plannedEndDate ??
        _plannedStartDate ??
        DateTime.now();

    final date = await _selectDate(
      initialDate: initialDate,
      firstDate: _plannedStartDate ?? DateTime(2000),
    );

    if (date == null || !mounted) {
      return;
    }

    setState(() {
      _plannedEndDate = date;
    });
  }

  Future<DateTime?> _selectDate({
    required DateTime initialDate,
    DateTime? firstDate,
  }) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: DateTime(2100),
    );
  }

  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final contractValue = double.tryParse(
      _contractValueController.text.trim(),
    );

    if (contractValue == null || contractValue < 0) {
      _showMessage('Enter a valid contract value.');
      return;
    }

    if (_plannedStartDate != null &&
        _plannedEndDate != null &&
        _plannedEndDate!.isBefore(_plannedStartDate!)) {
      _showMessage(
        'Planned end date cannot be before planned start date.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.repository.create(
        constructionSiteId: _selectedSite!.id,
        projectCode: _projectCodeController.text.trim(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        plannedStartDate: _plannedStartDate,
        plannedEndDate: _plannedEndDate,
        contractValue: contractValue,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      _showMessage(error.toString());
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Not selected';
    }

    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Project'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<Site>(
              initialValue: _selectedSite,
              decoration: const InputDecoration(
                labelText: 'Construction Site',
                border: OutlineInputBorder(),
              ),
              hint: const Text('Select a construction site'),
              items: _sites
                  .map(
                    (site) => DropdownMenuItem<Site>(
                      value: site,
                      child: Text(
                        ' — ',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _isSaving || _isLoadingSites
                  ? null
                  : (site) {
                      setState(() {
                        _selectedSite = site;
                      });
                    },
              validator: (value) {
                if (value == null) {
                  return 'Construction Site is required.';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _projectCodeController,
              decoration: const InputDecoration(
                labelText: 'Project Code',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Project Code is required.';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Project Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Project Name is required.';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Planned Dates',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.calendar_today_outlined,
                      ),
                      title: const Text('Planned start'),
                      subtitle: Text(
                        _formatDate(_plannedStartDate),
                      ),
                      onTap: _isSaving
                          ? null
                          : _selectStartDate,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.event_outlined,
                      ),
                      title: const Text('Planned end'),
                      subtitle: Text(
                        _formatDate(_plannedEndDate),
                      ),
                      onTap: _isSaving
                          ? null
                          : _selectEndDate,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contractValueController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Contract Value',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Contract Value is required.';
                }

                final parsed = double.tryParse(
                  value.trim(),
                );

                if (parsed == null || parsed < 0) {
                  return 'Enter a valid non-negative number.';
                }

                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _createProject,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                _isSaving ? 'Creating...' : 'Create Project',
              ),
            ),
          ],
        ),
      ),
    );
  }
}








