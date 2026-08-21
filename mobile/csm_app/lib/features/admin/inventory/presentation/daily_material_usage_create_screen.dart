import 'package:flutter/material.dart';

import '../../procurement/data/models/material.dart' as procurement;
import '../../procurement/data/repositories/material_repository.dart';
import '../../projects/data/models/daily_progress_log.dart';
import '../../projects/data/repositories/daily_progress_log_repository.dart';
import '../../projects/data/models/project.dart';
import '../../projects/data/repositories/project_repository.dart';
import '../../sites/data/models/site.dart';
import '../../sites/data/repositories/site_repository.dart';
import '../data/models/daily_material_usage.dart';
import '../data/repositories/daily_material_usage_repository.dart';

class DailyMaterialUsageCreateScreen extends StatefulWidget {
  const DailyMaterialUsageCreateScreen({
    super.key,
    required this.repository,
    required this.materialRepository,
    required this.siteRepository,
    required this.projectRepository,
    required this.dailyProgressLogRepository,
  });

  final DailyMaterialUsageRepository repository;
  final MaterialRepository materialRepository;
  final SiteRepository siteRepository;
  final ProjectRepository projectRepository;
  final DailyProgressLogRepository dailyProgressLogRepository;

  @override
  State<DailyMaterialUsageCreateScreen> createState() =>
      _DailyMaterialUsageCreateScreenState();
}

class _DailyMaterialUsageCreateScreenState
    extends State<DailyMaterialUsageCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _quantityIssuedController = TextEditingController();
  final _quantityUsedController = TextEditingController();
  final _quantityReturnedController = TextEditingController();
  final _unitController = TextEditingController();
  final _notesController = TextEditingController();

  List<Site> _sites = [];
  List<Project> _projects = [];
  List<DailyProgressLog> _progressLogs = [];
  List<procurement.Material> _materials = [];

  String? _selectedSiteId;
  String? _selectedProjectId;
  String? _selectedProgressLogId;
  String? _selectedMaterialId;

  DateTime _date = DateTime.now();

  bool _isLoadingSites = true;
  bool _isLoadingProjects = false;
  bool _isLoadingProgressLogs = false;
  bool _isLoadingMaterials = true;
  bool _isSaving = false;

  String? _error;
  DailyMaterialUsage? _createdUsage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _quantityIssuedController.dispose();
    _quantityUsedController.dispose();
    _quantityReturnedController.dispose();
    _unitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingSites = true;
      _isLoadingMaterials = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        widget.siteRepository.getAll(),
        widget.materialRepository.getAll(isActive: true),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _sites = results[0] as List<Site>;
        _materials =
            results[1] as List<procurement.Material>;
        _isLoadingSites = false;
        _isLoadingMaterials = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString();
        _isLoadingSites = false;
        _isLoadingMaterials = false;
      });
    }
  }

  Future<void> _loadProjects(String siteId) async {
    setState(() {
      _selectedProjectId = null;
      _selectedProgressLogId = null;
      _projects = [];
      _progressLogs = [];
      _isLoadingProjects = true;
      _error = null;
    });

    try {
      final projects =
          await widget.projectRepository.getAll(
        constructionSiteId: siteId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _projects = projects;
        _isLoadingProjects = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString();
        _isLoadingProjects = false;
      });
    }
  }

  Future<void> _loadProgressLogs(String projectId) async {
    setState(() {
      _selectedProgressLogId = null;
      _progressLogs = [];
      _isLoadingProgressLogs = true;
      _error = null;
    });

    try {
      final logs =
          await widget.dailyProgressLogRepository.getAll(
        projectId: projectId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _progressLogs = logs;
        _isLoadingProgressLogs = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString();
        _isLoadingProgressLogs = false;
      });
    }
  }



  void _onMaterialChanged(String? materialId) {
    if (materialId == null) {
      return;
    }

    final material = _materials
        .where((item) => item.id == materialId)
        .firstOrNull;

    setState(() {
      _selectedMaterialId = materialId;

      if (material != null) {
        _unitController.text = material.unitOfMeasure;
      }
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

    if (_selectedProjectId == null) {
      _showMessage('Please select a project.');
      return;
    }

    if (_selectedProgressLogId == null) {
      _showMessage('Please select a daily progress log.');
      return;
    }

    if (_selectedMaterialId == null) {
      _showMessage('Please select a material.');
      return;
    }

    final issued = double.tryParse(
      _quantityIssuedController.text.trim(),
    );

    final used = double.tryParse(
      _quantityUsedController.text.trim(),
    );

    final returned = double.tryParse(
      _quantityReturnedController.text.trim(),
    );

    if (issued == null || issued <= 0) {
      _showMessage('Quantity issued must be greater than zero.');
      return;
    }

    if (used == null || used < 0) {
      _showMessage('Quantity used cannot be negative.');
      return;
    }

    if (returned == null || returned < 0) {
      _showMessage('Quantity returned cannot be negative.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
      _createdUsage = null;
    });

    try {
      final usage = await widget.repository.create(
        CreateDailyMaterialUsageRequest(
          constructionSiteId: _selectedSiteId!,
          materialId: _selectedMaterialId!,
          dailyProgressLogId: _selectedProgressLogId!,
          date: _date,
          quantityIssued: issued,
          quantityUsed: used,
          quantityReturned: returned,
          unit: _unitController.text.trim(),
          notes: _cleanOptional(_notesController.text),
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _createdUsage = usage;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Daily material usage created successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _error = error.toString();
      });

      _showMessage(error.toString());
    }
  }

  String? _cleanOptional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _formatDate(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        _isLoadingSites || _isLoadingMaterials;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Material Usage'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                    child: Text(site.name),
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
                    });

                    _loadProjects(value);
                  },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Construction site is required.';
              }

              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedProjectId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Project',
              border: OutlineInputBorder(),
            ),
            items: _projects
                .map(
                  (project) => DropdownMenuItem<String>(
                    value: project.id,
                    child: Text(
                      '${project.projectCode} - ${project.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged:
                _isSaving || _isLoadingProjects
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _selectedProjectId = value;
                        });

                        _loadProgressLogs(value);
                      },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Project is required.';
              }

              return null;
            },
          ),
          if (_isLoadingProjects) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedProgressLogId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Daily Progress Log',
              border: OutlineInputBorder(),
            ),
            items: _progressLogs
                .map(
                  (log) => DropdownMenuItem<String>(
                    value: log.id,
                    child: Text(
                      '${_formatDate(log.logDate)} - '
                      '${log.progressPercentage.toStringAsFixed(1)}% progress',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged:
            _isSaving || _isLoadingProgressLogs
                ? null
                : (value) {
              if (value == null) {
                return;
              }

              final selectedLog = _progressLogs
                  .where((log) => log.id == value)
                  .firstOrNull;

              if (selectedLog == null) {
                return;
              }

              setState(() {
                _selectedProgressLogId = value;
                _date = selectedLog.logDate;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Daily progress log is required.';
              }

              return null;
            },
          ),
          if (_isLoadingProgressLogs) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedMaterialId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Material',
              border: OutlineInputBorder(),
            ),
            items: _materials
                .map(
                  (material) => DropdownMenuItem<String>(
                    value: material.id,
                    child: Text(
                      '${material.materialCode} - '
                      '${material.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: _isSaving
                ? null
                : _onMaterialChanged,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Material is required.';
              }

              return null;
            },
          ),
          const SizedBox(height: 16),
          _DateField(
            label: 'Usage Date (from Daily Progress Log)',
            value: _formatDate(_date),
            onPressed: null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _quantityIssuedController,
            decoration: const InputDecoration(
              labelText: 'Quantity Issued',
              border: OutlineInputBorder(),
            ),
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            validator: (value) {
              final number = double.tryParse(
                value?.trim() ?? '',
              );

              if (number == null || number <= 0) {
                return 'Enter a quantity greater than zero.';
              }

              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _quantityUsedController,
            decoration: const InputDecoration(
              labelText: 'Quantity Used',
              border: OutlineInputBorder(),
            ),
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            validator: (value) {
              final number = double.tryParse(
                value?.trim() ?? '',
              );

              if (number == null || number < 0) {
                return 'Enter zero or a positive quantity.';
              }

              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _quantityReturnedController,
            decoration: const InputDecoration(
              labelText: 'Quantity Returned',
              border: OutlineInputBorder(),
            ),
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            validator: (value) {
              final number = double.tryParse(
                value?.trim() ?? '',
              );

              if (number == null || number < 0) {
                return 'Enter zero or a positive quantity.';
              }

              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _unitController,
            decoration: const InputDecoration(
              labelText: 'Unit',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Unit is required.';
              }

              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
              hintText: 'Optional',
            ),
            maxLines: 3,
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(
              _isSaving
                  ? 'Saving...'
                  : 'Save Daily Material Usage',
            ),
          ),
          if (_createdUsage != null) ...[
            const SizedBox(height: 24),
            _buildResultCard(_createdUsage!),
          ],
        ],
      ),
    );
  }

  Widget _buildResultCard(DailyMaterialUsage usage) {
    final requiresReview =
        usage.requiresSupervisorReview;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Usage Result',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _ResultRow(
              label: 'Quantity Issued',
              value:
                  '${usage.quantityIssued} ${usage.unit}',
            ),
            _ResultRow(
              label: 'Quantity Used',
              value:
                  '${usage.quantityUsed} ${usage.unit}',
            ),
            _ResultRow(
              label: 'Quantity Returned',
              value:
                  '${usage.quantityReturned} ${usage.unit}',
            ),
            _ResultRow(
              label: 'Quantity Variance',
              value:
                  '${usage.quantityVariance} ${usage.unit}',
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(
                  requiresReview
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    requiresReview
                        ? 'Supervisor review required.'
                        : 'Usage reconciled successfully.',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
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
        children: [
          Expanded(
            child: Text(label),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final String label;
  final String value;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Usage Date',
          border: OutlineInputBorder(),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(value),
            ),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }
}






