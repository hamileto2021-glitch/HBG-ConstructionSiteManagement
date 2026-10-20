import 'package:flutter/material.dart';
import 'package:csm_app/core/network/api_client.dart';

import '../../../sites/data/models/site.dart';
import '../../../sites/data/repositories/site_repository.dart';
import '../data/quality_checklist.dart';
import '../data/quality_checklist_repository.dart';
import '../data/update_quality_checklist_request.dart';

class EditQualityChecklistScreen extends StatefulWidget {
  const EditQualityChecklistScreen({
    super.key,
    required this.checklist,
  });

  final QualityChecklist checklist;

  @override
  State<EditQualityChecklistScreen> createState() =>
      _EditQualityChecklistScreenState();
}

class _EditQualityChecklistScreenState
    extends State<EditQualityChecklistScreen> {
  final _formKey = GlobalKey<FormState>();

  late final QualityChecklistRepository _repository;
  late final SiteRepository _siteRepository;

  final _name = TextEditingController();
  final _description = TextEditingController();

  String _category = 'Concrete';
  String? _siteId;
  bool _isActive = true;

  List<Site> _sites = [];
  final List<_ItemRow> _items = [];

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final api = ApiClient();

    _repository = QualityChecklistRepository(api);
    _siteRepository = SiteRepository(apiClient: api);

    final c = widget.checklist;

    _name.text = c.name;
    _description.text = c.description ?? '';
    _category = c.category;

    _isActive = c.isActive;

    for (final item in c.items) {
      _items.add(
        _ItemRow(
          id: item.id,
          controller: TextEditingController(text: item.requirement),
          mandatory: item.isMandatory,
        ),
      );
    }

    _loadSites();
  }

  Future<void> _loadSites() async {
    final data = await _siteRepository.getAll();

    if (!mounted) return;

    // 1. Try matching by ID
    Site? selected;
    try {
      selected = data.firstWhere(
            (s) => s.id == widget.checklist.constructionSiteId,
      );
    } catch (_) {}

    // 2. If ID is stale, match by site name
    if (selected == null) {
      try {
        selected = data.firstWhere(
              (s) => s.name == widget.checklist.constructionSiteName,
        );
      } catch (_) {}
    }

    // 3. Final fallback
    selected ??= data.first;

    setState(() {
      _sites = data;
      _siteId = selected!.id;
    });

    debugPrint('Selected Site: ${selected.name}');
    debugPrint('Selected ID: ${selected.id}');
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();

    for (final item in _items) {
      item.controller.dispose();
    }

    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(
        _ItemRow(
          controller: TextEditingController(),
          mandatory: true,
        ),
      );
    });
  }

  void _removeItem(int index) {
    if (_items.length == 1) return;

    _items[index].controller.dispose();

    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Always resolve a valid site ID before sending
    final selectedSiteId = _siteId ??
        (_sites.isNotEmpty ? _sites.first.id : null);

    if (selectedSiteId == null || selectedSiteId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a construction site'),
        ),
      );
      return;
    }

    debugPrint('Sending Site ID: $selectedSiteId');

    setState(() => _saving = true);

    try {
      await _repository.update(
        widget.checklist.id,
        UpdateQualityChecklistRequest(
          constructionSiteId: selectedSiteId,
          name: _name.text.trim(),
          category: _category,
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          isActive: _isActive,
          items: List.generate(
            _items.length,
                (i) => UpdateQualityChecklistItem(
              id: _items[i].id,
              sequence: i + 1,
              requirement: _items[i].controller.text.trim(),
              isMandatory: _items[i].mandatory,
            ),
          ),
        ),
      );
      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Quality Checklist'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _siteId,
              decoration: const InputDecoration(
                labelText: 'Construction Site',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null ? 'Select a site' : null,
              items: _sites.map((site) {
                return DropdownMenuItem<String>(
                  value: site.id,
                  child: Text(site.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _siteId = value);
              },
            ),


            const SizedBox(height: 16),

            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Checklist Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              v == null || v.isEmpty ? 'Required' : null,
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: const [
                'Concrete',
                'Rebar',
                'Masonry',
                'Finishing',
                'General',
              ]
                  .map(
                    (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e),
                ),
              )
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),

            const SizedBox(height: 16),

            SwitchListTile(
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              title: const Text('Active Checklist'),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Checklist Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            ...List.generate(_items.length, (index) {
              final row = _items[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'Item ${index + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => _removeItem(index),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                      TextFormField(
                        controller: row.controller,
                        decoration: const InputDecoration(
                          labelText: 'Requirement',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                      ),
                      CheckboxListTile(
                        value: row.mandatory,
                        onChanged: (v) {
                          setState(() {
                            row.mandatory = v ?? true;
                          });
                        },
                        title: const Text('Mandatory'),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity:
                        ListTileControlAffinity.leading,
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(
                _saving ? 'Updating...' : 'Update Checklist',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow {
  _ItemRow({
    this.id,
    TextEditingController? controller,
    required this.mandatory,
  }) : controller = controller ?? TextEditingController();

  final String? id;
  final TextEditingController controller;
  bool mandatory;
}