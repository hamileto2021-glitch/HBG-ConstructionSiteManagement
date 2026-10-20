enum DelayCategory {
  weather,
  material,
  labor,
  equipment,
  client,
  design,
  permit,
  other,
}

class ProjectDelay {
  final String id;
  final String projectId;
  final String siteId;
  final DateTime delayDate;
  final DelayCategory category;
  final String title;
  final String description;
  final int timeImpactDays;
  final double costImpact;
  final String? mitigationAction;
  final bool isResolved;

  ProjectDelay({
    required this.id,
    required this.projectId,
    required this.siteId,
    required this.delayDate,
    required this.category,
    required this.title,
    required this.description,
    required this.timeImpactDays,
    required this.costImpact,
    this.mitigationAction,
    required this.isResolved,
  });

  factory ProjectDelay.fromJson(Map<String, dynamic> json) {
    return ProjectDelay(
      id: json['id'],
      projectId: json['projectId'],
      siteId: json['siteId'],
      delayDate: DateTime.parse(json['delayDate']),
      category: DelayCategory.values.firstWhere(
            (e) => e.name.toLowerCase() ==
            json['category'].toString().toLowerCase(),
        orElse: () => DelayCategory.other,
      ),
      title: json['title'],
      description: json['description'],
      timeImpactDays: json['timeImpactDays'],
      costImpact: (json['costImpact'] as num).toDouble(),
      mitigationAction: json['mitigationAction'],
      isResolved: json['isResolved'],
    );
  }

  Map<String, dynamic> toCreateJson() => {
    'projectId': projectId,
    'siteId': siteId,
    'delayDate': delayDate.toIso8601String().split('T').first,
    'category': category.name,
    'title': title,
    'description': description,
    'timeImpactDays': timeImpactDays,
    'costImpact': costImpact,
    'mitigationAction': mitigationAction,
  };
}