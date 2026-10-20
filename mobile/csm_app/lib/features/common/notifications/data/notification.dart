class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.readAtUtc,
    this.relatedEntityType,
    this.relatedEntityId,
    required this.createdAtUtc,
  });

  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime? readAtUtc;
  final String? relatedEntityType;
  final String? relatedEntityId;
  final DateTime createdAtUtc;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      isRead: json['isRead'] as bool,
      readAtUtc: json['readAtUtc'] == null
          ? null
          : DateTime.parse(json['readAtUtc'] as String),
      relatedEntityType: json['relatedEntityType'] as String?,
      relatedEntityId: json['relatedEntityId'] as String?,
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
    );
  }
}