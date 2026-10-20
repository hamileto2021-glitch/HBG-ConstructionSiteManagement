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
  final TextEditingController _searchController =
  TextEditingController();

  List<ComplianceDocument> _documents = [];
  List<ComplianceDocument> _filtered = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_onSearchChanged);

    _load();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();

    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final data = await widget.repository.getAll();

      if (!mounted) return;

      setState(() {
        _documents = data;
        _filtered = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  void _onSearchChanged() {
    final query =
    _searchController.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filtered = _documents;
        return;
      }

      _filtered = _documents.where((document) {
        return document.name
            .toLowerCase()
            .contains(query) ||
            document.documentNumber
                .toLowerCase()
                .contains(query) ||
            document.fileName
                .toLowerCase()
                .contains(query);
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

  IconData _typeIcon(DocumentType type) {
    switch (type) {
      case DocumentType.permit:
        return Icons.assignment_turned_in;

      case DocumentType.drawing:
        return Icons.architecture;

      case DocumentType.contract:
        return Icons.description;

      case DocumentType.safety:
        return Icons.health_and_safety;

      case DocumentType.qaqc:
        return Icons.fact_check;

      case DocumentType.manual:
        return Icons.menu_book;

      case DocumentType.other:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _openDocument(
      ComplianceDocument document,
      ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentDetailScreen(
          documentId: document.id,
          repository: widget.repository,
        ),
      ),
    );

    if (!mounted) return;

    await _load();
  }

  Future<void> _createDocument() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentCreateScreen(
          repository: widget.repository,
        ),
      ),
    );

    if (!mounted) return;

    if (created == true) {
      await _load();
    }
  }

  Widget _buildHeader() {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(
              Icons.arrow_back,
              size: 29,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Documents',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        28,
        10,
        28,
        13,
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search documents...',
          hintStyle: TextStyle(
            fontSize: 17,
            color: Colors.grey.shade700,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 29,
            color: Colors.grey.shade700,
          ),
          suffixIcon:
          _searchController.text.isEmpty
              ? null
              : IconButton(
            onPressed: () {
              _searchController.clear();
            },
            icon: const Icon(
              Icons.clear,
            ),
          ),
          contentPadding:
          const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(7),
            borderSide: BorderSide(
              color: Colors.grey.shade600,
              width: 1.2,
            ),
          ),
          enabledBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(7),
            borderSide: BorderSide(
              color: Colors.grey.shade600,
              width: 1.2,
            ),
          ),
          focusedBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(7),
            borderSide: BorderSide(
              color: Theme.of(context)
                  .colorScheme
                  .primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentCard(ComplianceDocument document) {
    final typeColor = _typeColor(document.documentType);

    Color statusColor(DrawingStatus? status) {
      switch (status) {
        case DrawingStatus.issuedForConstruction:
          return Colors.green;
        case DrawingStatus.approved:
          return Colors.blue;
        case DrawingStatus.asBuilt:
          return Colors.purple;
        case DrawingStatus.superseded:
          return Colors.red;
        case DrawingStatus.issuedForReview:
          return Colors.orange;
        default:
          return Colors.grey;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 5),
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => _openDocument(document),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 11, 10, 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: typeColor,
                child: Icon(
                  _typeIcon(document.documentType),
                  color: Colors.white,
                  size: 25,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      document.documentNumber,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),

                    if (document.constructionSiteName != null &&
                        document.constructionSiteName!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 15,
                              color: Colors.grey.shade700,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                document.constructionSiteName!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (document.documentType == DocumentType.drawing &&
                        document.drawingNumber != null) ...[
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          const Icon(Icons.architecture, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              document.drawingNumber!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (document.sheetNumber != null &&
                          document.sheetNumber!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Sheet: ${document.sheetNumber}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),

                      if (document.discipline != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            document.discipline!.displayName,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),

                      if (document.currentRevision != null &&
                          document.currentRevision!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Revision ${document.currentRevision}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ] else ...[
                      const SizedBox(height: 4),

                      Text(
                        document.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            document.documentType.displayName,
                            style: TextStyle(
                              color: typeColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        if (document.documentType == DocumentType.drawing &&
                            document.drawingStatus != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor(document.drawingStatus!)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              document.drawingStatus!.displayName,
                              style: TextStyle(
                                color: statusColor(document.drawingStatus!),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                        if (document.isConfidential)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Confidential',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final searching =
        _searchController.text
            .trim()
            .isNotEmpty;

    return ListView(
      physics:
      const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height:
          MediaQuery.of(context).size.height *
              0.5,
          child: Center(
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                Icon(
                  searching
                      ? Icons.search_off
                      : Icons.folder_open,
                  size: 56,
                  color:
                  Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  searching
                      ? 'No documents found'
                      : 'No documents yet',
                  style: TextStyle(
                    fontSize: 17,
                    color:
                    Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            _buildSearchBox(),

            Expanded(
              child: _loading
                  ? const Center(
                child:
                CircularProgressIndicator(),
              )
                  : RefreshIndicator(
                onRefresh: _load,
                child: _filtered.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                  physics:
                  const AlwaysScrollableScrollPhysics(),
                  padding:
                  const EdgeInsets
                      .only(
                    bottom: 100,
                  ),
                  itemCount:
                  _filtered.length,
                  itemBuilder:
                      (context, index) {
                    return _buildDocumentCard(
                      _filtered[index],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),

      floatingActionButton:
      FloatingActionButton.extended(
        onPressed: _createDocument,
        backgroundColor:
        const Color(0xFFB3E5FC),
        foregroundColor:
        const Color(0xFF075B78),
        elevation: 5,
        icon: const Icon(
          Icons.upload_file,
          size: 24,
        ),
        label: const Text(
          'New Document',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}