import 'package:flutter/material.dart';

import '../data/models/document.dart';
import '../data/repositories/document_repository.dart';
import 'document_edit_screen.dart';
import '../data/models/document_version.dart';




class DocumentDetailScreen extends StatefulWidget {
  const DocumentDetailScreen({
    super.key,
    required this.documentId,
    required this.repository,
  });

  final String documentId;
  final DocumentRepository repository;

  @override
  State<DocumentDetailScreen> createState() =>
      _DocumentDetailScreenState();
}

class _DocumentDetailScreenState
    extends State<DocumentDetailScreen> {
  ComplianceDocument? _document;

  List<DocumentVersion> _versions = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final document = await widget.repository.getById(
        widget.documentId,
      );

      final versions = await widget.repository.getVersions(
        widget.documentId,
      );

      _document = document;
      _versions = versions;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Color _typeColor(DocumentType type) {
    switch (type) {
      case DocumentType.permit:
        return Colors.green;
      case DocumentType.drawing:
        return Colors.blue;
      case DocumentType.contract:
        return Colors.deepPurple;
      case DocumentType.safety:
        return Colors.red;
      case DocumentType.qaqc:
        return Colors.orange;
      case DocumentType.manual:
        return Colors.teal;
      case DocumentType.other:
        return Colors.grey;
    }
  }

  Widget rowItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String dateText(DateTime? date) {
    if (date == null) return '-';

    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String fileSize(int bytes) {
    if (bytes >= 1048576) {
      return '${(bytes / 1048576).toStringAsFixed(2)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }
  Future<void> _addVersion() async {
    final fileName = TextEditingController();
    final storage = TextEditingController();
    final content = TextEditingController();
    final size = TextEditingController();
    final notes = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Version'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fileName,
                decoration: const InputDecoration(
                  labelText: 'File Name',
                ),
              ),
              TextField(
                controller: storage,
                decoration: const InputDecoration(
                  labelText: 'Storage Path',
                ),
              ),
              TextField(
                controller: content,
                decoration: const InputDecoration(
                  labelText: 'Content Type',
                ),
              ),
              TextField(
                controller: size,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'File Size',
                ),
              ),
              TextField(
                controller: notes,
                decoration: const InputDecoration(
                  labelText: 'Revision Notes',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await widget.repository.createVersion(
                documentId: widget.documentId,
                fileName: fileName.text,
                storagePath: storage.text,
                contentType: content.text,
                fileSizeBytes: int.tryParse(size.text) ?? 0,
                revisionNotes: notes.text,
              );

              if (context.mounted) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (created == true) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final doc = _document;

    if (doc == null) {
      return const Scaffold(
        body: Center(child: Text('Document not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(doc.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor:
                    _typeColor(doc.documentType),
                    child: const Icon(
                      Icons.description,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    doc.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text(
                          doc.documentType.displayName,
                        ),
                        backgroundColor:
                        _typeColor(doc.documentType)
                            .withValues(alpha: 0.15),
                      ),
                      if (doc.isConfidential)
                        const Chip(
                          avatar: Icon(Icons.lock, size: 16),
                          label: Text('Confidential'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  rowItem(
                    'Document No',
                    doc.documentNumber,
                  ),
                  rowItem('File', doc.fileName),
                  rowItem(
                    'Content Type',
                    doc.contentType ?? '-',
                  ),
                  rowItem(
                    'File Size',
                    fileSize(doc.fileSizeBytes),
                  ),
                  rowItem(
                    'Storage Path',
                    doc.storagePath,
                  ),
                  rowItem(
                    'Issue Date',
                    dateText(doc.issueDate),
                  ),
                  rowItem(
                    'Expiry Date',
                    dateText(doc.expiryDate),
                  ),
                  rowItem(
                    'Description',
                    doc.description ?? '-',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Version History',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _addVersion,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (_versions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('No versions available'),
                    ),
                  ..._versions.map(
                        (v) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        child: Text('V${v.versionNumber}'),
                      ),
                      title: Text(v.fileName),
                      subtitle: Text(
                        v.revisionNotes ?? 'No revision notes',
                      ),
                      trailing: v.isCurrent
                          ? const Chip(label: Text('Current'))
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => DocumentEditScreen(
                    document: doc,
                    repository: widget.repository,
                  ),
                ),
              );

              if (updated == true) {
                _load();
              }
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Document'),
          )
        ],
      ),
    );
  }
}