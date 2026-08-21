enum ProjectStatus {
  draft,
  planning,
  active,
  onHold,
  completed,
  cancelled,
  closed,
}

class Project {
  const Project({
    required this.id,
    required this.companyId,
    required this.constructionSiteId,
    required this.projectCode,
    required this.name,
    required this.contractValue,
    required this.progressPercentage,
    required this.status,
    required this.createdAtUtc,
    this.description,
    this.plannedStartDate,
    this.plannedEndDate,
    this.actualStartDate,
    this.actualEndDate,
  });

  final String id;
  final String companyId;
  final String constructionSiteId;
  final String projectCode;
  final String name;
  final String? description;
  final DateTime? plannedStartDate;
  final DateTime? plannedEndDate;
  final DateTime? actualStartDate;
  final DateTime? actualEndDate;
  final double contractValue;
  final double progressPercentage;
  final ProjectStatus status;
  final DateTime createdAtUtc;

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      constructionSiteId: json['constructionSiteId'] as String,
      projectCode: json['projectCode'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      plannedStartDate: _parseDate(json['plannedStartDate']),
      plannedEndDate: _parseDate(json['plannedEndDate']),
      actualStartDate: _parseDate(json['actualStartDate']),
      actualEndDate: _parseDate(json['actualEndDate']),
      contractValue: (json['contractValue'] as num).toDouble(),
      progressPercentage:
          (json['progressPercentage'] as num).toDouble(),
      status: _parseStatus(json['status']),
      createdAtUtc: DateTime.parse(
        json['createdAtUtc'] as String,
      ),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.parse(value as String);
  }

  static ProjectStatus _parseStatus(dynamic value) {
    final normalized = value.toString().toLowerCase();

    switch (normalized) {
      case 'draft':
        return ProjectStatus.draft;
      case 'planning':
        return ProjectStatus.planning;
      case 'active':
        return ProjectStatus.active;
      case 'onhold':
      case 'on_hold':
      case 'on hold':
        return ProjectStatus.onHold;
      case 'completed':
        return ProjectStatus.completed;
      case 'cancelled':
      case 'canceled':
        return ProjectStatus.cancelled;
      case 'closed':
        return ProjectStatus.closed;
      default:
        throw FormatException(
          'Unknown project status: $value',
        );
    }
  }
}


