class DailyProgressPhoto {
  final String id;
  final String dailySiteDiaryId;
  final String fileName;
  final String filePath;
  final String? caption;
  final DateTime uploadedAtUtc;

  const DailyProgressPhoto({
    required this.id,
    required this.dailySiteDiaryId,
    required this.fileName,
    required this.filePath,
    this.caption,
    required this.uploadedAtUtc,
  });

  factory DailyProgressPhoto.fromJson(Map<String, dynamic> json) {
    return DailyProgressPhoto(
      id: json['id'],
      dailySiteDiaryId: json['dailySiteDiaryId'],
      fileName: json['fileName'],
      filePath: json['filePath'],
      caption: json['caption'],
      uploadedAtUtc: DateTime.parse(json['uploadedAtUtc']),
    );
  }
}