class ProjectProgressDashboard {
  final String projectId;
  final String projectName;
  final double plannedProgress;
  final double actualProgress;
  final int totalTasks;
  final int completedTasks;
  final int remainingTasks;
  final int openDelays;
  final int totalDelayDays;

  ProjectProgressDashboard({
    required this.projectId,
    required this.projectName,
    required this.plannedProgress,
    required this.actualProgress,
    required this.totalTasks,
    required this.completedTasks,
    required this.remainingTasks,
    required this.openDelays,
    required this.totalDelayDays,
  });

  factory ProjectProgressDashboard.fromJson(
      Map<String, dynamic> json) {
    return ProjectProgressDashboard(
      projectId: json['projectId'],
      projectName: json['projectName'],
      plannedProgress: (json['plannedProgress'] as num).toDouble(),
      actualProgress: (json['actualProgress'] as num).toDouble(),
      totalTasks: json['totalTasks'],
      completedTasks: json['completedTasks'],
      remainingTasks: json['remainingTasks'],
      openDelays: json['openDelays'],
      totalDelayDays: json['totalDelayDays'],
    );
  }
}