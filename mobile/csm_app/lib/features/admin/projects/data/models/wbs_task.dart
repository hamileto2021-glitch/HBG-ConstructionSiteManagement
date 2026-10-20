enum WbsTaskStatus {
  notStarted,
  inProgress,
  onHold,
  completed,
  cancelled,
}

enum TaskPriority {
  low,
  medium,
  high,
  critical,
}

class WbsTask {
  final String id;
  final String companyId;
  final String projectId;
  final String projectMilestoneId;
  final String? assignedEmployeeId;

  final String taskCode;
  final String name;
  final String? description;

  final DateTime plannedStartDate;
  final DateTime plannedFinishDate;
  final DateTime? actualStartDate;
  final DateTime? actualFinishDate;

  final WbsTaskStatus status;
  final TaskPriority priority;

  final double progressPercentage;
  final double estimatedHours;
  final double actualHours;

  const WbsTask({
    required this.id,
    required this.companyId,
    required this.projectId,
    required this.projectMilestoneId,
    this.assignedEmployeeId,
    required this.taskCode,
    required this.name,
    this.description,
    required this.plannedStartDate,
    required this.plannedFinishDate,
    this.actualStartDate,
    this.actualFinishDate,
    required this.status,
    required this.priority,
    required this.progressPercentage,
    required this.estimatedHours,
    required this.actualHours,
  });

  factory WbsTask.fromJson(Map<String, dynamic> json) {
    return WbsTask(
      id: json['id'],
      companyId: json['companyId'],
      projectId: json['projectId'],
      projectMilestoneId: json['projectMilestoneId'],
      assignedEmployeeId: json['assignedEmployeeId'],
      taskCode: json['taskCode'],
      name: json['name'],
      description: json['description'],
      plannedStartDate: DateTime.parse(json['plannedStartDate']),
      plannedFinishDate: DateTime.parse(json['plannedFinishDate']),
      actualStartDate: json['actualStartDate'] != null
          ? DateTime.parse(json['actualStartDate'])
          : null,
      actualFinishDate: json['actualFinishDate'] != null
          ? DateTime.parse(json['actualFinishDate'])
          : null,
      status: _statusFromJson(json['status']),
      priority: _priorityFromJson(json['priority']),
      progressPercentage:
      (json['progressPercentage'] as num).toDouble(),
      estimatedHours:
      (json['estimatedHours'] as num).toDouble(),
      actualHours:
      (json['actualHours'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'companyId': companyId,
    'projectId': projectId,
    'projectMilestoneId': projectMilestoneId,
    'assignedEmployeeId': assignedEmployeeId,
    'taskCode': taskCode,
    'name': name,
    'description': description,
    'plannedStartDate':
    plannedStartDate.toIso8601String().split('T').first,
    'plannedFinishDate':
    plannedFinishDate.toIso8601String().split('T').first,
    'actualStartDate':
    actualStartDate?.toIso8601String().split('T').first,
    'actualFinishDate':
    actualFinishDate?.toIso8601String().split('T').first,
    'status': status.name,
    'priority': priority.name,
    'progressPercentage': progressPercentage,
    'estimatedHours': estimatedHours,
    'actualHours': actualHours,
  };

  static WbsTaskStatus _statusFromJson(dynamic value) {
    final text = value.toString().toLowerCase();

    switch (text) {
      case '1':
      case 'notstarted':
        return WbsTaskStatus.notStarted;
      case '2':
      case 'inprogress':
        return WbsTaskStatus.inProgress;
      case '3':
      case 'onhold':
        return WbsTaskStatus.onHold;
      case '4':
      case 'completed':
        return WbsTaskStatus.completed;
      case '5':
      case 'cancelled':
        return WbsTaskStatus.cancelled;
      default:
        return WbsTaskStatus.notStarted;
    }
  }

  static TaskPriority _priorityFromJson(dynamic value) {
    final text = value.toString().toLowerCase();

    switch (text) {
      case '1':
      case 'low':
        return TaskPriority.low;
      case '2':
      case 'medium':
        return TaskPriority.medium;
      case '3':
      case 'high':
        return TaskPriority.high;
      case '4':
      case 'critical':
        return TaskPriority.critical;
      default:
        return TaskPriority.medium;
    }
  }
}