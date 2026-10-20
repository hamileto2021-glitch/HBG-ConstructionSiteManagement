class AuditLog {
  const AuditLog({
    required this.id,
    required this.userName,
    required this.module,
    required this.action,
    required this.entityName,
    required this.description,
    required this.createdAtUtc,
  });

  final String id;
  final String userName;
  final String module;
  final String action;
  final String entityName;
  final String description;
  final DateTime createdAtUtc;

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'],
      userName: json['userName'],
      module: json['module'],
      action: json['action'],
      entityName: json['entityName'],
      description: json['description'],
      createdAtUtc: DateTime.parse(json['createdAtUtc']),
    );
  }
}