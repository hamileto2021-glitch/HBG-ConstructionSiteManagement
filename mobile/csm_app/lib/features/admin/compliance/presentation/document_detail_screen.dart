import 'package:flutter/material.dart';

import '../../../../core/config/api_config.dart';
import '../data/models/document.dart';
import '../data/repositories/document_repository.dart';
import 'document_edit_screen.dart';
import '../data/models/document_version.dart';
import 'package:file_picker/file_picker.dart';
import 'document_pdf_viewer_screen.dart';



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
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final notes = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Upload New Revision'),
        content: TextField(
          controller: notes,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Revision Notes',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Choose File'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final files = await FilePicker.pickFiles(
      type: FileType.any,
    );

    if (files.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No file selected')),
      );
      return;
    }

    final file = files.first;

// Accept only PDF or DWG
    final ext = file.name.split('.').last.toLowerCase();
    if (ext != 'pdf' && ext != 'dwg') {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please select a PDF or DWG file')),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(content: Text('Selected: ${file.name}')),
    );

    showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await widget.repository.uploadVersion(
        documentId: widget.documentId,
        file: file,
        revisionNotes:
        notes.text.trim().isEmpty ? null : notes.text.trim(),
      );

      navigator.pop();

      await _load();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Revision uploaded successfully'),
        ),
      );
    } catch (e) {
      navigator.pop();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
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
                    backgroundColor: _typeColor(doc.documentType),
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
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text(doc.documentType.displayName),
                        backgroundColor:
                        _typeColor(doc.documentType).withValues(alpha: 0.15),
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
                  rowItem('Document No', doc.documentNumber),

                  if (doc.constructionSiteName != null &&
                      doc.constructionSiteName!.isNotEmpty)
                    rowItem('Construction Site', doc.constructionSiteName!),

                  rowItem('File', doc.fileName),
                  rowItem('Content Type', doc.contentType ?? '-'),
                  rowItem('File Size', fileSize(doc.fileSizeBytes)),
                  rowItem('Storage Path', doc.storagePath),
                  rowItem('Issue Date', dateText(doc.issueDate)),
                  rowItem('Expiry Date', dateText(doc.expiryDate)),
                  rowItem('Description', doc.description ?? '-'),
                ],
              ),
            ),
          ),

          if (doc.documentType == DocumentType.drawing) ...[
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Drawing Information',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Divider(),
                    rowItem('Drawing No', doc.drawingNumber ?? '-'),
                    rowItem('Sheet', doc.sheetNumber ?? '-'),
                    rowItem('Discipline', doc.discipline?.displayName ?? '-'),
                    rowItem('Status', doc.drawingStatus?.displayName ?? '-'),
                    rowItem('Revision', doc.currentRevision ?? '-'),
                    const SizedBox(height: 12),

                    FilledButton.icon(
                      onPressed: () {
                        final pdfUrl = ApiConfig.fileUrl(doc.storagePath);

                        debugPrint('PDF URL: $pdfUrl');

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DocumentPdfViewerScreen(
                              title: doc.name,
                              url: pdfUrl,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Open Current Drawing'),
                    ),
                  ],
                ),
              ),
            ),
          ],

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
                          isThreeLine: true,
                          onTap: () {
                            final pdfUrl = ApiConfig.fileUrl(v.storagePath);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DocumentPdfViewerScreen(
                                  title: '${doc.name} - Rev ${v.versionNumber}',
                                  url: pdfUrl,
                                ),
                              ),
                            );
                          },
                          leading: CircleAvatar(
                            backgroundColor: v.isCurrent ? Colors.green : Colors.grey,
                            child: Text(
                              'R${v.versionNumber}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            v.fileName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (v.revisionNotes != null && v.revisionNotes!.isNotEmpty)
                                Text(
                                  v.revisionNotes!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 2),
                              Text(
                                dateText(v.createdAtUtc),
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (v.isCurrent)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Current',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 6),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        )
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
          ),
        ],
      ),
    );
  }
}