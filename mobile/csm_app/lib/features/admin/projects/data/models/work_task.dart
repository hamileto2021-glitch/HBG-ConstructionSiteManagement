enum WorkTaskStatus {
  notStarted,
  inProgress,
  onHold,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case WorkTaskStatus.notStarted:
        return 'Not Started';
      case WorkTaskStatus.inProgress:
        return 'In Progress';
      case WorkTaskStatus.onHold:
        return 'On Hold';
      case WorkTaskStatus.completed:
        return 'Completed';
      case WorkTaskStatus.cancelled:
        return 'Cancelled';
    }
  }

  factory WorkTaskStatus.fromJson(String value) {
    switch (value.toLowerCase()) {
      case 'inprogress':
        return WorkTaskStatus.inProgress;
      case 'onhold':
        return WorkTaskStatus.onHold;
      case 'completed':
        return WorkTaskStatus.completed;
      case 'cancelled':
        return WorkTaskStatus.cancelled;
      default:
        return WorkTaskStatus.notStarted;
    }
  }
}

enum Priority {
  low,
  normal,
  high,
  critical;

  String get displayName {
    switch (this) {
      case Priority.low:
        return 'Low';
      case Priority.normal:
        return 'Normal';
      case Priority.high:
        return 'High';
      case Priority.critical:
        return 'Critical';
    }
  }

  factory Priority.fromJson(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return Priority.low;
      case 'high':
        return Priority.high;
      case 'critical':
        return Priority.critical;
      default:
        return Priority.normal;
    }
  }
}

class WorkTaskDependency {
  const WorkTaskDependency({
    required this.workTaskId,
    required this.dependsOnTaskId,
  });

  final String workTaskId;
  final String dependsOnTaskId;

  factory WorkTaskDependency.fromJson(
      Map<String, dynamic> json,
      ) {
    return WorkTaskDependency(
      workTaskId: json['workTaskId'],
      dependsOnTaskId: json['dependsOnTaskId'],
    );
  }
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
    required this.dependencies,
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
  final Priority priority;
  final WorkTaskStatus status;
  final List<WorkTaskDependency> dependencies;

  factory WorkTask.fromJson(Map<String, dynamic> json) {
    return WorkTask(
      id: json['id'],
      projectId: json['projectId'],
      projectPhaseId: json['projectPhaseId'],
      milestoneId: json['milestoneId'],
      taskNumber: json['taskNumber'],
      title: json['title'],
      description: json['description'],
      plannedStartDate: json['plannedStartDate'] == null
          ? null
          : DateTime.parse(json['plannedStartDate']),
      plannedEndDate: json['plannedEndDate'] == null
          ? null
          : DateTime.parse(json['plannedEndDate']),
      actualStartDate: json['actualStartDate'] == null
          ? null
          : DateTime.parse(json['actualStartDate']),
      actualEndDate: json['actualEndDate'] == null
          ? null
          : DateTime.parse(json['actualEndDate']),
      progressPercentage:
      (json['progressPercentage'] as num).toDouble(),
      priority: Priority.fromJson(json['priority']),
      status: WorkTaskStatus.fromJson(json['status']),
      dependencies:
      (json['dependencies'] as List<dynamic>? ?? [])
          .map(
            (e) => WorkTaskDependency.fromJson(
          e as Map<String, dynamic>,
        ),
      )
          .toList(),
    );
  }
}