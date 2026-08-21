import 'package:flutter/material.dart';

import '../data/models/document.dart';
import '../data/repositories/document_repository.dart';

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

  DocumentType _type = DocumentType.permit;
  bool _confidential = false;

  DateTime? _issueDate;
  DateTime? _expiryDate;

  bool _saving = false;

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
        documentNumber: _number.text.trim(),
        name: _name.text.trim(),
        documentType: _type,
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

  @override
  void dispose() {
    _number.dispose();
    _name.dispose();
    _fileName.dispose();
    _storagePath.dispose();
    _contentType.dispose();
    _fileSize.dispose();
    _description.dispose();
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
            field(_number, 'Document Number', required: true),
            field(_name, 'Document Name', required: true),

            DropdownButtonFormField<DocumentType>(
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

            const SizedBox(height: 14),

            field(_fileName, 'File Name', required: true),
            field(_storagePath, 'Storage Path', required: true),
            field(_contentType, 'Content Type'),
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
              subtitle: const Text('Restrict document access'),
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