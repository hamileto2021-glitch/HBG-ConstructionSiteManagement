import 'package:flutter/material.dart';

import '../data/models/document.dart';
import '../data/repositories/document_repository.dart';
import 'package:csm_app/features/admin/sites/data/models/site.dart';
import 'package:csm_app/features/admin/sites/data/repositories/site_repository.dart';



class DocumentCreateScreen extends StatefulWidget {
  const DocumentCreateScreen({
    super.key,
    required this.repository,
  });

  final DocumentRepository repository;

  @override
  State<DocumentCreateScreen> createState() =>
      _DocumentCreateScreenState();
}

class _DocumentCreateScreenState
    extends State<DocumentCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _number = TextEditingController();
  final _name = TextEditingController();
  final _fileName = TextEditingController();
  final _storagePath = TextEditingController();
  final _contentType = TextEditingController();
  final _fileSize = TextEditingController();
  final _description = TextEditingController();

  final _drawingNumber = TextEditingController();
  final _sheetNumber = TextEditingController();
  final _currentRevision = TextEditingController();
  final _siteRepository = SiteRepository();

  List<Site> _sites = [];
  String? _selectedSiteId;

  DrawingDiscipline? _discipline;
  DrawingStatus? _drawingStatus;

  DocumentType _type = DocumentType.permit;
  bool _confidential = false;

  DateTime? _issueDate;
  DateTime? _expiryDate;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSites();
  }

  Future<void> _loadSites() async {
    try {
      final result = await _siteRepository.getAll();

      if (!mounted) return;

      setState(() {
        _sites = result;
      });
    } catch (_) {}
  }

  Future<void> _pickIssue() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _issueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() => _issueDate = date);
    }
  }

  Future<void> _pickExpiry() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() => _expiryDate = date);
    }
  }

  String _date(DateTime? value) {
    if (value == null) return 'Select Date';

    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await widget.repository.create(
        constructionSiteId: _selectedSiteId,
        documentNumber: _number.text.trim(),
        name: _name.text.trim(),
        documentType: _type,

        drawingNumber: _type == DocumentType.drawing
            ? _drawingNumber.text.trim().isEmpty
            ? null
            : _drawingNumber.text.trim()
            : null,
        sheetNumber: _type == DocumentType.drawing
            ? _sheetNumber.text.trim().isEmpty
            ? null
            : _sheetNumber.text.trim()
            : null,
        discipline:
        _type == DocumentType.drawing ? _discipline : null,
        drawingStatus:
        _type == DocumentType.drawing ? _drawingStatus : null,
        currentRevision: _type == DocumentType.drawing
            ? _currentRevision.text.trim().isEmpty
            ? null
            : _currentRevision.text.trim()
            : null,

        fileName: _fileName.text.trim(),
        storagePath: _storagePath.text.trim(),
        contentType: _contentType.text.trim().isEmpty
            ? null
            : _contentType.text.trim(),
        fileSizeBytes: int.tryParse(_fileSize.text) ?? 0,
        issueDate: _issueDate,
        expiryDate: _expiryDate,
        isConfidential: _confidential,
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
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

  Widget field(
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
            ? (v) =>
        v == null || v.trim().isEmpty ? 'Required' : null
            : null,
      ),
    );

  }

  Widget drawingSection() {
    if (_type != DocumentType.drawing) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 28),

        const Text(
          'Drawing Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 14),

        field(
          _drawingNumber,
          'Drawing Number',
          required: true,
        ),

        field(
          _sheetNumber,
          'Sheet Number',
        ),

        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: DropdownButtonFormField<DrawingDiscipline>(
            initialValue: _discipline,
            decoration: const InputDecoration(
              labelText: 'Discipline',
              border: OutlineInputBorder(),
            ),
            items: DrawingDiscipline.values
                .map(
                  (e) => DropdownMenuItem(
                value: e,
                child: Text(e.displayName),
              ),
            )
                .toList(),
            onChanged: (v) => setState(() => _discipline = v),
            validator: (v) {
              if (_type == DocumentType.drawing && v == null) {
                return 'Required';
              }
              return null;
            },
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: DropdownButtonFormField<DrawingStatus>(
            initialValue: _drawingStatus,
            decoration: const InputDecoration(
              labelText: 'Drawing Status',
              border: OutlineInputBorder(),
            ),
            items: DrawingStatus.values
                .map(
                  (e) => DropdownMenuItem(
                value: e,
                child: Text(e.displayName),
              ),
            )
                .toList(),
            onChanged: (v) => setState(() => _drawingStatus = v),
            validator: (v) {
              if (_type == DocumentType.drawing && v == null) {
                return 'Required';
              }
              return null;
            },
          ),
        ),

        field(
          _currentRevision,
          'Current Revision',
        ),
      ],
    );
  }

  @override
  void dispose() {
    _number.dispose();
    _name.dispose();
    _fileName.dispose();
    _storagePath.dispose();
    _contentType.dispose();
    _fileSize.dispose();
    _description.dispose();

    _drawingNumber.dispose();
    _sheetNumber.dispose();
    _currentRevision.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Document'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            field(
              _number,
              'Document Number',
              required: true,
            ),

            field(
              _name,
              'Document Name',
              required: true,
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: DropdownButtonFormField<DocumentType>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Document Type',
                  border: OutlineInputBorder(),
                ),
                items: DocumentType.values
                    .map(
                      (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e.displayName),
                  ),
                )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _type = value);
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedSiteId,
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
                onChanged: (value) {
                  setState(() => _selectedSiteId = value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Construction site is required';
                  }
                  return null;
                },
              ),
            ),

            drawingSection(),

            field(
              _fileName,
              'File Name',
              required: true,
            ),

            field(
              _storagePath,
              'Storage Path',
              required: true,
            ),

            field(
              _contentType,
              'Content Type',
            ),

            field(
              _fileSize,
              'File Size (Bytes)',
              keyboard: TextInputType.number,
            ),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Issue Date'),
              subtitle: Text(_date(_issueDate)),
              trailing: const Icon(Icons.calendar_month),
              onTap: _pickIssue,
            ),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Expiry Date'),
              subtitle: Text(_date(_expiryDate)),
              trailing: const Icon(Icons.calendar_month),
              onTap: _pickExpiry,
            ),

            SwitchListTile(
              value: _confidential,
              title: const Text('Confidential'),
              subtitle:
              const Text('Restrict document access'),
              onChanged: (value) {
                setState(() => _confidential = value);
              },
            ),

            field(
              _description,
              'Description',
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(
                _saving ? 'Saving...' : 'Upload Document',
              ),
            ),
          ],
        ),
      ),
    );
  }
}