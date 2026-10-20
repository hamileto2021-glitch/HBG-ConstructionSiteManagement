import 'package:flutter/material.dart';

import '../../sites/data/models/site.dart';
import '../../sites/data/repositories/site_repository.dart';
import '../data/repositories/petty_cash_repository.dart';

class PettyCashAccountCreateScreen extends StatefulWidget {
  const PettyCashAccountCreateScreen({
    super.key,
    required this.repository,
  });

  final PettyCashRepository repository;

  @override
  State<PettyCashAccountCreateScreen> createState() =>
      _PettyCashAccountCreateScreenState();
}

class _PettyCashAccountCreateScreenState
    extends State<PettyCashAccountCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _code = TextEditingController();
  final _name = TextEditingController();
  final _opening = TextEditingController(text: '0');

  final _siteRepository = SiteRepository();

  bool _saving = false;
  List<Site> _sites = [];
  Site? _selectedSite;

  @override
  void initState() {
    super.initState();
    _loadSites();
  }

  Future<void> _loadSites() async {
    final data = await _siteRepository.getAll();

    if (!mounted) return;

    setState(() {
      _sites = data;
      if (data.isNotEmpty) {
        _selectedSite = data.first;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSite == null) return;

    setState(() => _saving = true);

    try {
      final account = await widget.repository.create(
        constructionSiteId: _selectedSite!.id,
        accountCode: _code.text.trim(),
        accountName: _name.text.trim(),
        openingBalance:
        double.parse(_opening.text.trim()),
      );

      if (!mounted) return;

      Navigator.pop(context, account);
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
  void dispose() {
    _code.dispose();
    _name.dispose();
    _opening.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Petty Cash Account'),
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
              items: _sites.map(
                    (site) => DropdownMenuItem<Site>(
                  value: site,
                  child: Text(site.name),
                ),
              ).toList(),
              onChanged: (value) {
                setState(() => _selectedSite = value);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _code,
              decoration: const InputDecoration(
                labelText: 'Account Code',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              v == null || v.isEmpty
                  ? 'Required'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Account Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              v == null || v.isEmpty
                  ? 'Required'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _opening,
              keyboardType:
              const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Opening Balance (ETB)',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Required';
                }
                if (double.tryParse(v) == null) {
                  return 'Invalid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(
                _saving
                    ? 'Saving...'
                    : 'Create Account',
              ),
            ),
          ],
        ),
      ),
    );
  }
}