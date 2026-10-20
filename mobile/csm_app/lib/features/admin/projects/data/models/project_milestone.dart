enum MilestoneStatus {
  pending,
  inProgress,
  completed,
  delayed,
}

class ProjectMilestone {
  const ProjectMilestone({
    required this.id,
    required this.companyId,
    required this.projectId,
    required this.name,
    this.description,
    required this.plannedDate,
    this.actualDate,
    required this.status,
    required this.progressPercentage,
    this.notes,
    this.projectName,
  });

  final String id;
  final String companyId;
  final String projectId;

  final String name;
  final String? description;

  final DateTime plannedDate;
  final DateTime? actualDate;

  final MilestoneStatus status;
  final double progressPercentage;

  final String? notes;
  final String? projectName;

  factory ProjectMilestone.fromJson(
      Map<String, dynamic> json,
      ) {
    return ProjectMilestone(
      id: json['id'],
      companyId: json['companyId'],
      projectId: json['projectId'],
      name: json['name'],
      description: json['description'],
      plannedDate: DateTime.parse(json['plannedDate']),
      actualDate: json['actualDate'] == null
          ? null
          : DateTime.parse(json['actualDate']),
      status: MilestoneStatus.values.firstWhere(
            (e) =>
        e.name ==
            (json['status'] as String)
                .replaceAll(' ', '')
                .toLowerCase(),
        orElse: () => MilestoneStatus.pending,
      ),
      progressPercentage:
      (json['progressPercentage'] as num)
          .toDouble(),
      notes: json['notes'],
      projectName: json['projectName'],
    );
  }
}