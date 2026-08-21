enum ProjectPhaseStatus {
  notStarted,
  inProgress,
  onHold,
  completed,
  cancelled,
}

class ProjectPhase {
  const ProjectPhase({
    required this.id,
    required this.companyId,
    required this.projectId,
    required this.name,
    required this.sequence,
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
  final String projectId;
  final String name;
  final String? description;
  final int sequence;
  final DateTime? plannedStartDate;
  final DateTime? plannedEndDate;
  final DateTime? actualStartDate;
  final DateTime? actualEndDate;
  final double progressPercentage;
  final ProjectPhaseStatus status;
  final DateTime createdAtUtc;

  factory ProjectPhase.fromJson(Map<String, dynamic> json) {
    return ProjectPhase(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      projectId: json['projectId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      sequence: (json['sequence'] as num).toInt(),
      plannedStartDate: _parseDate(json['plannedStartDate']),
      plannedEndDate: _parseDate(json['plannedEndDate']),
      actualStartDate: _parseDate(json['actualStartDate']),
      actualEndDate: _parseDate(json['actualEndDate']),
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

  static ProjectPhaseStatus _parseStatus(dynamic value) {
    final normalized = value.toString().toLowerCase();

    switch (normalized) {
      case 'notstarted':
      case 'not_started':
      case 'not started':
        return ProjectPhaseStatus.notStarted;

      case 'inprogress':
      case 'in_progress':
      case 'in progress':
        return ProjectPhaseStatus.inProgress;

      case 'onhold':
      case 'on_hold':
      case 'on hold':
        return ProjectPhaseStatus.onHold;

      case 'completed':
        return ProjectPhaseStatus.completed;

      case 'cancelled':
      case 'canceled':
        return ProjectPhaseStatus.cancelled;

      default:
        throw FormatException(
          'Unknown project phase status: $value',
        );
    }
  }
}
