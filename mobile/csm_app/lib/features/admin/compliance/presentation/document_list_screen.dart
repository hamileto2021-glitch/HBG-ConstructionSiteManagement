import 'package:flutter/material.dart';

import '../data/models/document.dart';
import '../data/repositories/document_repository.dart';
import 'document_create_screen.dart';
import 'document_detail_screen.dart';


class DocumentListScreen extends StatefulWidget {
  const DocumentListScreen({
    super.key,
    required this.repository,
  });

  final DocumentRepository repository;

  @override
  State<DocumentListScreen> createState() =>
      _DocumentListScreenState();
}

class _DocumentListScreenState
    extends State<DocumentListScreen> {
  final _search = TextEditingController();

  List<ComplianceDocument> _documents = [];
  List<ComplianceDocument> _filtered = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final data = await widget.repository.getAll();

      _documents = data;
      _filtered = data;
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

  void _filter(String value) {
    final query = value.toLowerCase();

    setState(() {
      _filtered = _documents.where((doc) {
        return doc.name.toLowerCase().contains(query) ||
            doc.documentNumber
                .toLowerCase()
                .contains(query) ||
            doc.fileName.toLowerCase().contains(query);
      }).toList();
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton:
      FloatingActionButton.extended(
        onPressed: () async {
          final created =
          await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => DocumentCreateScreen(
                repository: widget.repository,
              ),
            ),
          );

          if (created == true) {
            _load();
          }
        },
        icon: const Icon(Icons.upload_file),
        label: const Text('New Document'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              onChanged: _filter,
              decoration: const InputDecoration(
                hintText: 'Search documents...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
              child:
              CircularProgressIndicator(),
            )
                : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder:
                    (context, index) {
                  final doc =
                  _filtered[index];

                  return Card(
                    margin:
                    const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                DocumentDetailScreen(
                                  documentId:
                                  doc.id,
                                  repository:
                                  widget
                                      .repository,
                                ),
                          ),
                        );

                        _load();
                      },
                      leading:
                      CircleAvatar(
                        backgroundColor:
                        _typeColor(
                          doc.documentType,
                        ),
                        child: const Icon(
                          Icons.description,
                          color:
                          Colors.white,
                        ),
                      ),
                      title: Text(doc.name),
                      subtitle: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          Text(
                              doc.documentNumber),
                          Text(doc.fileName),
                          const SizedBox(
                              height: 4),
                          Wrap(
                            spacing: 6,
                            children: [
                              Chip(
                                label: Text(
                                  doc
                                      .documentType
                                      .displayName,
                                ),
                                backgroundColor:
                                _typeColor(
                                  doc.documentType,
                                ).withValues(
                                  alpha: 0.15,
                                ),
                              ),
                              if (doc
                                  .isConfidential)
                                const Chip(
                                  label: Text(
                                      'Confidential'),
                                  avatar: Icon(
                                    Icons
                                        .lock,
                                    size: 16,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      trailing:
                      const Icon(
                        Icons.chevron_right,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}