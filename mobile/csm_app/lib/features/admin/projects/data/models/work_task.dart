
enum WorkTaskStatus {
  notStarted,
  inProgress,
  blocked,
  onHold,
  completed,
  cancelled,
}

enum TaskPriority {
  low,
  normal,
  high,
  critical,
}

class WorkTask {
  const WorkTask({
    required this.id,
    required this.projectId,
    this.projectPhaseId,
    this.milestoneId,
    required this.taskNumber,
    required this.title,
    this.description,
    this.plannedStartDate,
    this.plannedEndDate,
    this.actualStartDate,
    this.actualEndDate,
    required this.progressPercentage,
    required this.priority,
    required this.status,
    required this.createdAtUtc,
  });

  final String id;
  final String projectId;
  final String? projectPhaseId;
  final String? milestoneId;
  final String taskNumber;
  final String title;
  final String? description;
  final DateTime? plannedStartDate;
  final DateTime? plannedEndDate;
  final DateTime? actualStartDate;
  final DateTime? actualEndDate;
  final double progressPercentage;
  final TaskPriority priority;
  final WorkTaskStatus status;
  final DateTime createdAtUtc;

  factory WorkTask.fromJson(Map<String, dynamic> json) {
    return WorkTask(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      projectPhaseId: json['projectPhaseId'] as String?,
      milestoneId: json['milestoneId'] as String?,
      taskNumber: json['taskNumber'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      plannedStartDate: _parseDate(json['plannedStartDate']),
      plannedEndDate: _parseDate(json['plannedEndDate']),
      actualStartDate: _parseDate(json['actualStartDate']),
      actualEndDate: _parseDate(json['actualEndDate']),
      progressPercentage:
          (json['progressPercentage'] as num?)?.toDouble() ?? 0,
      priority: _parsePriority(json['priority']),
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

    return DateTime.tryParse(value.toString());
  }

  static TaskPriority _parsePriority(dynamic value) {
    final name = value.toString().split('.').last;

    switch (name) {
      case 'low':
      case 'Low':
        return TaskPriority.low;
      case 'high':
      case 'High':
        return TaskPriority.high;
      case 'critical':
      case 'Critical':
        return TaskPriority.critical;
      case 'normal':
      case 'Normal':
      default:
        return TaskPriority.normal;
    }
  }

  static WorkTaskStatus _parseStatus(dynamic value) {
    final name = value.toString().split('.').last;

    switch (name) {
      case 'inProgress':
      case 'InProgress':
        return WorkTaskStatus.inProgress;
      case 'blocked':
      case 'Blocked':
        return WorkTaskStatus.blocked;
      case 'onHold':
      case 'OnHold':
        return WorkTaskStatus.onHold;
      case 'completed':
      case 'Completed':
        return WorkTaskStatus.completed;
      case 'cancelled':
      case 'Cancelled':
        return WorkTaskStatus.cancelled;
      case 'notStarted':
      case 'NotStarted':
      default:
        return WorkTaskStatus.notStarted;
    }
  }
}
