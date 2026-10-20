import 'package:flutter/material.dart';
import 'package:csm_app/core/network/api_client.dart';

import '../../../sites/data/models/site.dart';
import '../../../sites/data/repositories/site_repository.dart';
import '../data/create_quality_checklist_request.dart';
import '../data/quality_checklist_repository.dart';

class CreateQualityChecklistScreen extends StatefulWidget {
  const CreateQualityChecklistScreen({super.key});

  @override
  State<CreateQualityChecklistScreen> createState() =>
      _CreateQualityChecklistScreenState();
}

class _CreateQualityChecklistScreenState
    extends State<CreateQualityChecklistScreen> {
  final _formKey = GlobalKey<FormState>();

  late final QualityChecklistRepository _repository;
  late final SiteRepository _siteRepository;

  final _name = TextEditingController();
  final _description = TextEditingController();

  String _category = 'Concrete';

  List<Site> _sites = [];
  String? _siteId;

  final List<_ItemRow> _items = [_ItemRow()];

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final api = ApiClient();

    _repository = QualityChecklistRepository(api);
    _siteRepository = SiteRepository(apiClient: api);

    _loadSites();
  }

  Future<void> _loadSites() async {
    try {
      final data = await _siteRepository.getAll();

      if (!mounted) return;

      setState(() {
        _sites = data;
        if (data.isNotEmpty) {
          _siteId = data.first.id;
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();

    for (final item in _items) {
      item.dispose();
    }

    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(_ItemRow());
    });
  }

  void _removeItem(int index) {
    if (_items.length == 1) return;

    _items[index].dispose();

    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_siteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a construction site'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await _repository.create(
        CreateQualityChecklistRequest(
          constructionSiteId: _siteId!,
          name: _name.text.trim(),
          category: _category,
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          items: List.generate(
            _items.length,
                (i) => CreateQualityChecklistItem(
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
        title: const Text('New Quality Checklist'),
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
              items: _sites
                  .map(
                    (site) => DropdownMenuItem(
                  value: site.id,
                  child: Text(site.name),
                ),
              )
                  .toList(),
              onChanged: (value) => setState(() => _siteId = value),
              validator: (value) =>
              value == null ? 'Select a site' : null,
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
                _saving ? 'Saving...' : 'Create Checklist',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow {
  _ItemRow()
      : controller = TextEditingController(),
        mandatory = true;

  final TextEditingController controller;
  bool mandatory;

  void dispose() => controller.dispose();
}