class BackupInfo {
  const BackupInfo({
    required this.fileName,
    required this.createdAtUtc,
    required this.fileSizeBytes,
  });

  final String fileName;
  final DateTime createdAtUtc;
  final int fileSizeBytes;

  factory BackupInfo.fromJson(Map<String, dynamic> json) {
    return BackupInfo(
      fileName: json['fileName'] as String,
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
      fileSizeBytes: json['fileSizeBytes'] as int,
    );
  }

  String get formattedSize {
    final kb = fileSizeBytes / 1024;
    final mb = kb / 1024;

    if (mb >= 1) {
      return '${mb.toStringAsFixed(1)} MB';
    }

    return '${kb.toStringAsFixed(0)} KB';
  }
}