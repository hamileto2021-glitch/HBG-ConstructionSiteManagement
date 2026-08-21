import 'package:flutter/material.dart';

import '../data/repositories/site_repository.dart';

class SiteCreateScreen extends StatefulWidget {
  const SiteCreateScreen({
    super.key,
    required this.repository,
  });

  final SiteRepository repository;

  @override
  State<SiteCreateScreen> createState() =>
      _SiteCreateScreenState();
}

class _SiteCreateScreenState
    extends State<SiteCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _siteCode = TextEditingController();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _region = TextEditingController();
  final _country = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  final _geofence = TextEditingController();

  DateTime? _plannedStart;
  DateTime? _plannedEnd;

  bool _saving = false;

  Future<void> _pickStart() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
      _plannedStart ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() => _plannedStart = date);
    }
  }

  Future<void> _pickEnd() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
      _plannedEnd ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() => _plannedEnd = date);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);

    try {
      await widget.repository.create(
        siteCode: _siteCode.text.trim(),
        name: _name.text.trim(),
        description:
        _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        address:
        _address.text.trim().isEmpty
            ? null
            : _address.text.trim(),
        city: _city.text.trim().isEmpty
            ? null
            : _city.text.trim(),
        region: _region.text.trim().isEmpty
            ? null
            : _region.text.trim(),
        country:
        _country.text.trim().isEmpty
            ? null
            : _country.text.trim(),
        latitude:
        double.tryParse(_latitude.text),
        longitude:
        double.tryParse(_longitude.text),
        geofenceRadiusMeters:
        double.tryParse(_geofence.text),
        plannedStartDate: _plannedStart,
        plannedEndDate: _plannedEnd,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _format(DateTime? date) {
    if (date == null) return 'Select Date';

    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _siteCode.dispose();
    _name.dispose();
    _description.dispose();
    _address.dispose();
    _city.dispose();
    _region.dispose();
    _country.dispose();
    _latitude.dispose();
    _longitude.dispose();
    _geofence.dispose();
    super.dispose();
  }

  Widget _textField(
      TextEditingController controller,
      String label, {
        TextInputType? keyboard,
        bool required = false,
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (v) => v == null || v.trim().isEmpty
            ? 'Required'
            : null
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      AppBar(title: const Text('Create Site')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _textField(
              _siteCode,
              'Site Code',
              required: true,
            ),
            _textField(
              _name,
              'Site Name',
              required: true,
            ),
            _textField(
              _description,
              'Description',
              maxLines: 3,
            ),
            _textField(_address, 'Address'),
            _textField(_city, 'City'),
            _textField(_region, 'Region'),
            _textField(_country, 'Country'),
            _textField(
              _latitude,
              'Latitude',
              keyboard:
              const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            _textField(
              _longitude,
              'Longitude',
              keyboard:
              const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            _textField(
              _geofence,
              'Geofence Radius (m)',
              keyboard:
              const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                  'Planned Start Date'),
              subtitle: Text(
                  _format(_plannedStart)),
              trailing: const Icon(
                  Icons.calendar_month),
              onTap: _pickStart,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title:
              const Text('Planned End Date'),
              subtitle:
              Text(_format(_plannedEnd)),
              trailing: const Icon(
                  Icons.calendar_month),
              onTap: _pickEnd,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed:
              _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(
                _saving
                    ? 'Saving...'
                    : 'Create Site',
              ),
            ),
          ],
        ),
      ),
    );
  }
}