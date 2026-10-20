import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class DocumentPdfViewerScreen extends StatelessWidget {
  const DocumentPdfViewerScreen({
    super.key,
    required this.title,
    required this.url,
  });

  final String title;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SfPdfViewer.network(
        url,
        canShowPaginationDialog: true,
        canShowScrollHead: true,
        canShowScrollStatus: true,
      ),
    );
  }
}