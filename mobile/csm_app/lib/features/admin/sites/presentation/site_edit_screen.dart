import 'package:flutter/material.dart';

import '../data/models/site.dart';
import '../data/repositories/site_repository.dart';

class SiteEditScreen extends StatefulWidget {
  const SiteEditScreen({
    super.key,
    required this.site,
    required this.repository,
  });

  final Site site;
  final SiteRepository repository;

  @override
  State<SiteEditScreen> createState() => _SiteEditScreenState();
}

class _SiteEditScreenState extends State<SiteEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _region;
  late final TextEditingController _country;
  late final TextEditingController _latitude;
  late final TextEditingController _longitude;
  late final TextEditingController _geofence;

  late SiteStatus _status;
  late bool _isActive;

  DateTime? _plannedStart;
  DateTime? _plannedEnd;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final s = widget.site;

    _name = TextEditingController(text: s.name);
    _description = TextEditingController(text: s.description ?? '');
    _address = TextEditingController(text: s.address ?? '');
    _city = TextEditingController(text: s.city ?? '');
    _region = TextEditingController(text: s.region ?? '');
    _country = TextEditingController(text: s.country ?? '');
    _latitude = TextEditingController(text: s.latitude?.toString() ?? '');
    _longitude = TextEditingController(text: s.longitude?.toString() ?? '');
    _geofence = TextEditingController(
      text: s.geofenceRadiusMeters?.toString() ?? '',
    );

    _plannedStart = s.plannedStartDate;
    _plannedEnd = s.plannedEndDate;

    _status = s.status;
    _isActive = s.isActive;
  }

  Future<void> _pickStart() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _plannedStart ?? DateTime.now(),
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
      initialDate: _plannedEnd ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() => _plannedEnd = date);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await widget.repository.update(
        siteId: widget.site.id,
        name: _name.text.trim(),
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        address:
        _address.text.trim().isEmpty ? null : _address.text.trim(),
        city: _city.text.trim().isEmpty ? null : _city.text.trim(),
        region: _region.text.trim().isEmpty ? null : _region.text.trim(),
        country:
        _country.text.trim().isEmpty ? null : _country.text.trim(),
        latitude: double.tryParse(_latitude.text),
        longitude: double.tryParse(_longitude.text),
        geofenceRadiusMeters: double.tryParse(_geofence.text),
        plannedStartDate: _plannedStart,
        plannedEndDate: _plannedEnd,
      );

      await widget.repository.changeStatus(
        siteId: widget.site.id,
        status: _status.name,
      );

      if (_isActive != widget.site.isActive) {
        if (_isActive) {
          await widget.repository.activate(widget.site.id);
        } else {
          await widget.repository.deactivate(widget.site.id);
        }
      }

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

  String _dateText(DateTime? date) {
    if (date == null) return 'Select date';

    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _field(
      TextEditingController controller,
      String label, {
        bool required = false,
        TextInputType? keyboard,
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (v) => v == null || v.trim().isEmpty ? 'Required' : null
            : null,
      ),
    );
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Site'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_name, 'Site Name', required: true),
            _field(_description, 'Description', maxLines: 3),
            _field(_address, 'Address'),
            _field(_city, 'City'),
            _field(_region, 'Region'),
            _field(_country, 'Country'),

            _field(
              _latitude,
              'Latitude',
              keyboard: const TextInputType.numberWithOptions(decimal: true),
            ),
            _field(
              _longitude,
              'Longitude',
              keyboard: const TextInputType.numberWithOptions(decimal: true),
            ),
            _field(
              _geofence,
              'Geofence Radius (m)',
              keyboard: const TextInputType.numberWithOptions(decimal: true),
            ),

            const SizedBox(height: 8),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Planned Start'),
              subtitle: Text(_dateText(_plannedStart)),
              trailing: const Icon(Icons.calendar_month),
              onTap: _pickStart,
            ),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Planned End'),
              subtitle: Text(_dateText(_plannedEnd)),
              trailing: const Icon(Icons.calendar_month),
              onTap: _pickEnd,
            ),

            const Divider(height: 32),

            DropdownButtonFormField<SiteStatus>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Site Status',
                border: OutlineInputBorder(),
              ),
              items: SiteStatus.values
                  .map(
                    (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e.displayName),
                ),
              )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _status = value);
                }
              },
            ),

            const SizedBox(height: 16),

            SwitchListTile(
              value: _isActive,
              title: const Text('Active Site'),
              subtitle: Text(
                _isActive ? 'Site is active' : 'Site is inactive',
              ),
              onChanged: (value) {
                setState(() => _isActive = value);
              },
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(_saving ? 'Saving...' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}