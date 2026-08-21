import 'package:flutter/material.dart';

import '../data/models/equipment.dart';

import '../data/repositories/equipment_assignment_repository.dart';
import '../data/repositories/equipment_repository.dart';
import '../../sites/data/models/site.dart';
import '../../sites/data/repositories/site_repository.dart';


class EquipmentAssignmentCreateScreen extends StatefulWidget {
  EquipmentAssignmentCreateScreen({
    super.key,
    EquipmentAssignmentRepository? assignmentRepository,
    EquipmentRepository? equipmentRepository,
    SiteRepository? siteRepository,
  })  : assignmentRepository =
            assignmentRepository ?? EquipmentAssignmentRepository(),
        equipmentRepository =
            equipmentRepository ?? EquipmentRepository(),
        siteRepository = siteRepository ?? SiteRepository();

  final EquipmentAssignmentRepository assignmentRepository;
  final EquipmentRepository equipmentRepository;
  final SiteRepository siteRepository;

  @override
  State<EquipmentAssignmentCreateScreen> createState() =>
      _EquipmentAssignmentCreateScreenState();
}

class _EquipmentAssignmentCreateScreenState
    extends State<EquipmentAssignmentCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  List<Equipment> _equipment = [];
  List<Site> _sites = [];

  Equipment? _selectedEquipment;
  Site? _selectedSite;

  DateTime _assignedAt = DateTime.now();

  final _meterController = TextEditingController();
  final _remarksController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _meterController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        widget.equipmentRepository.getAll(),
        widget.siteRepository.getAll(),
      ]);

      if (!mounted) return;

      final equipment = results[0] as List<Equipment>;
      final sites = results[1] as List<Site>;

      setState(() {
        _equipment = equipment
            .where((item) => item.isActive)
            .toList();

        _sites = sites
            .where((site) =>
                site.isActive &&
                site.status != SiteStatus.completed &&
                site.status != SiteStatus.closed)
            .toList();

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

  Future<void> _selectAssignedAt() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _assignedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_assignedAt),
    );

    if (time == null || !mounted) return;

    setState(() {
      _assignedAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedEquipment == null) {
      _showMessage('Select equipment.');
      return;
    }

    if (_selectedSite == null) {
      _showMessage('Select a construction site.');
      return;
    }

    final meterText = _meterController.text.trim();

    final meterReading = meterText.isEmpty
        ? null
        : double.tryParse(meterText);

    if (meterText.isNotEmpty &&
        (meterReading == null || meterReading < 0)) {
      _showMessage(
        'Enter a valid non-negative meter reading.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.assignmentRepository.create(
        equipmentId: _selectedEquipment!.id,
        constructionSiteId: _selectedSite!.id,
        assignedAtUtc: _assignedAt.toUtc(),
        meterReadingAtAssignment: meterReading,
        remarks: _nullable(_remarksController.text),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Equipment assigned successfully.',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showMessage(error.toString());
    }
  }

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();

    String two(int value) =>
        value.toString().padLeft(2, '0');

    return '${local.year}-${two(local.month)}-'
        '${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Equipment'),
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
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_equipment.isEmpty || _sites.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.assignment_late_outlined,
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                _equipment.isEmpty
                    ? 'No active equipment is available.'
                    : 'No active construction sites are available.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Create the required equipment and site records first.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<Equipment>(
            initialValue: _selectedEquipment,
            decoration: const InputDecoration(
              labelText: 'Equipment',
              border: OutlineInputBorder(),
            ),
            items: _equipment.map((equipment) {
              return DropdownMenuItem<Equipment>(
                value: equipment,
                child: Text(
                  '${equipment.equipmentCode} — '
                  '${equipment.name}',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: _isSaving
                ? null
                : (value) {
                    setState(() {
                      _selectedEquipment = value;
                    });
                  },
            validator: (value) {
              if (value == null) {
                return 'Equipment is required.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Site>(
            initialValue: _selectedSite,
            decoration: const InputDecoration(
              labelText: 'Construction Site',
              border: OutlineInputBorder(),
            ),
            items: _sites.map((site) {
              return DropdownMenuItem<Site>(
                value: site,
                child: Text(
                  '${site.siteCode} — ${site.name}',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: _isSaving
                ? null
                : (value) {
                    setState(() {
                      _selectedSite = value;
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
          InkWell(
            onTap: _isSaving ? null : _selectAssignedAt,
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Assigned At',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today_outlined),
              ),
              child: Text(_formatDateTime(_assignedAt)),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _meterController,
            enabled: !_isSaving,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Meter Reading at Assignment',
              border: OutlineInputBorder(),
              hintText: 'Optional',
            ),
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return null;
              }

              final parsed =
                  double.tryParse(value.trim());

              if (parsed == null || parsed < 0) {
                return 'Enter a valid non-negative number.';
              }

              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _remarksController,
            enabled: !_isSaving,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Remarks',
              border: OutlineInputBorder(),
              hintText: 'Optional',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.assignment_turned_in_outlined,
                    ),
              label: Text(
                _isSaving
                    ? 'Assigning...'
                    : 'Assign Equipment',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
