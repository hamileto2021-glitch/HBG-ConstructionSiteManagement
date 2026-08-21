class Milestone {
  const Milestone({
    required this.id,
    required this.companyId,
    required this.projectId,
    this.projectPhaseId,
    required this.name,
    this.description,
    required this.plannedDate,
    this.completedDate,
    required this.isCompleted,
    required this.createdAtUtc,
  });

  final String id;
  final String companyId;
  final String projectId;
  final String? projectPhaseId;
  final String name;
  final String? description;
  final DateTime plannedDate;
  final DateTime? completedDate;
  final bool isCompleted;
  final DateTime createdAtUtc;

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      projectId: json['projectId'] as String,
      projectPhaseId: json['projectPhaseId'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      plannedDate: DateTime.parse(
        json['plannedDate'] as String,
      ),
      completedDate: _parseDate(json['completedDate']),
      isCompleted: json['isCompleted'] as bool,
      createdAtUtc: DateTime.parse(
        json['createdAtUtc'] as String,
      ),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
