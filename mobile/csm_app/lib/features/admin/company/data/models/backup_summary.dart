class BackupSummary {
  const BackupSummary({
    required this.backupCount,
    this.lastBackupUtc,
  });

  final int backupCount;
  final DateTime? lastBackupUtc;

  factory BackupSummary.fromJson(Map<String, dynamic> json) {
    return BackupSummary(
      backupCount: json['backupCount'] ?? 0,
      lastBackupUtc: json['lastBackupUtc'] != null
          ? DateTime.parse(json['lastBackupUtc'])
          : null,
    );
  }
}