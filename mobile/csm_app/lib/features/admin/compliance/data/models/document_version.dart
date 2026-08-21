class DocumentVersion {
  const DocumentVersion({
    required this.id,
    required this.documentId,
    required this.versionNumber,
    required this.fileName,
    required this.storagePath,
    this.contentType,
    required this.fileSizeBytes,
    this.revisionNotes,
    required this.isCurrent,
    required this.uploadedByUserId,
    required this.createdAtUtc,
  });

  final String id;
  final String documentId;
  final int versionNumber;
  final String fileName;
  final String storagePath;
  final String? contentType;
  final int fileSizeBytes;
  final String? revisionNotes;
  final bool isCurrent;
  final String uploadedByUserId;
  final DateTime createdAtUtc;

  factory DocumentVersion.fromJson(
      Map<String, dynamic> json,
      ) {
    return DocumentVersion(
      id: json['id'],
      documentId: json['documentId'],
      versionNumber: json['versionNumber'],
      fileName: json['fileName'],
      storagePath: json['storagePath'],
      contentType: json['contentType'],
      fileSizeBytes: json['fileSizeBytes'],
      revisionNotes: json['revisionNotes'],
      isCurrent: json['isCurrent'],
      uploadedByUserId: json['uploadedByUserId'],
      createdAtUtc: DateTime.parse(json['createdAtUtc']),
    );
  }
}