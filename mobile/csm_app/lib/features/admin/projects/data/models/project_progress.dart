class ProjectProgress {
  final String projectId;
  final String projectName;

  final int totalTasks;
  final int completedTasks;
  final int inProgressTasks;
  final int notStartedTasks;
  final int overdueTasks;

  final double overallProgress;
  final double estimatedHours;
  final double actualHours;

  final String healthStatus;

  const ProjectProgress({
    required this.projectId,
    required this.projectName,
    required this.totalTasks,
    required this.completedTasks,
    required this.inProgressTasks,
    required this.notStartedTasks,
    required this.overdueTasks,
    required this.overallProgress,
    required this.estimatedHours,
    required this.actualHours,
    required this.healthStatus,
  });

  factory ProjectProgress.fromJson(Map<String, dynamic> json) {
    return ProjectProgress(
      projectId: json['projectId'],
      projectName: json['projectName'],
      totalTasks: json['totalTasks'],
      completedTasks: json['completedTasks'],
      inProgressTasks: json['inProgressTasks'],
      notStartedTasks: json['notStartedTasks'],
      overdueTasks: json['overdueTasks'],
      overallProgress: (json['overallProgress'] as num).toDouble(),
      estimatedHours: (json['estimatedHours'] as num).toDouble(),
      actualHours: (json['actualHours'] as num).toDouble(),
      healthStatus: json['healthStatus'],
    );
  }

  Map<String, dynamic> toJson() => {
    'projectId': projectId,
    'projectName': projectName,
    'totalTasks': totalTasks,
    'completedTasks': completedTasks,
    'inProgressTasks': inProgressTasks,
    'notStartedTasks': notStartedTasks,
    'overdueTasks': overdueTasks,
    'overallProgress': overallProgress,
    'estimatedHours': estimatedHours,
    'actualHours': actualHours,
    'healthStatus': healthStatus,
  };
}