import 'package:flutter/material.dart';

import '../data/models/document.dart';
import '../data/repositories/document_repository.dart';

class DocumentEditScreen extends StatefulWidget {
  const DocumentEditScreen({
    super.key,
    required this.document,
    required this.repository,
  });

  final ComplianceDocument document;
  final DocumentRepository repository;

  @override
  State<DocumentEditScreen> createState() =>
      _DocumentEditScreenState();
}

class _DocumentEditScreenState
    extends State<DocumentEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _fileName;
  late final TextEditingController _storagePath;
  late final TextEditingController _contentType;
  late final TextEditingController _fileSize;
  late final TextEditingController _description;

  late DocumentType _type;
  late bool _confidential;

  DateTime? _issueDate;
  DateTime? _expiryDate;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final d = widget.document;

    _name = TextEditingController(text: d.name);
    _fileName = TextEditingController(text: d.fileName);
    _storagePath = TextEditingController(text: d.storagePath);
    _contentType =
        TextEditingController(text: d.contentType ?? '');
    _fileSize =
        TextEditingController(text: d.fileSizeBytes.toString());
    _description =
        TextEditingController(text: d.description ?? '');

    _type = d.documentType;
    _confidential = d.isConfidential;
    _issueDate = d.issueDate;
    _expiryDate = d.expiryDate;
  }

  Future<void> _pickIssue() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _issueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _issueDate = date);
  }

  Future<void> _pickExpiry() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _expiryDate = date);
  }

  String _date(DateTime? d) => d == null
      ? 'Select Date'
      : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await widget.repository.update(
        documentId: widget.document.id,
        documentNumber: widget.document.documentNumber,
        name: _name.text.trim(),
        documentType: _type,
        fileName: _fileName.text.trim(),
        storagePath: _storagePath.text.trim(),
        contentType: _contentType.text.trim().isEmpty
            ? null
            : _contentType.text.trim(),
        fileSizeBytes: int.tryParse(_fileSize.text) ?? 0,
        constructionSiteId: widget.document.constructionSiteId,
        projectId: widget.document.projectId,
        employeeId: widget.document.employeeId,
        relatedEntityId: widget.document.relatedEntityId,
        relatedEntityType: widget.document.relatedEntityType,
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
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _fileName.dispose();
    _storagePath.dispose();
    _contentType.dispose();
    _fileSize.dispose();
    _description.dispose();
    super.dispose();
  }

  Widget field(
      TextEditingController controller,
      String label, {
        TextInputType? keyboard,
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        validator: (v) =>
        v == null || v.trim().isEmpty ? 'Required' : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Document')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            field(_name, 'Document Name'),

            DropdownButtonFormField<DocumentType>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Document Type',
                border: OutlineInputBorder(),
              ),
              items: DocumentType.values
                  .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e.displayName),
              ))
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),

            const SizedBox(height: 14),

            field(_fileName, 'File Name'),
            field(_storagePath, 'Storage Path'),
            field(_contentType, 'Content Type'),
            field(
              _fileSize,
              'File Size',
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
              onChanged: (v) =>
                  setState(() => _confidential = v),
            ),

            field(
              _description,
              'Description',
              maxLines: 3,
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(
                _saving ? 'Saving...' : 'Save Changes',
              ),
            ),
          ],
        ),
      ),
    );
  }
}