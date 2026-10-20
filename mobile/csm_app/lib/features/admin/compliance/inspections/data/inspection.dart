class InspectionChecklistItem {
  const InspectionChecklistItem({
    required this.id,
    required this.sequence,
    required this.requirement,
    this.isCompliant,
    this.observation,
    this.correctiveAction,
    this.dueDate,
    required this.isResolved,
  });

  final String id;
  final int sequence;
  final String requirement;

  final bool? isCompliant;
  final String? observation;
  final String? correctiveAction;
  final DateTime? dueDate;

  final bool isResolved;

  factory InspectionChecklistItem.fromJson(
      Map<String, dynamic> json,
      ) {
    return InspectionChecklistItem(
      id: (json['id'] ?? '').toString(),
      sequence: (json['sequence'] ?? 0) as int,
      requirement: (json['requirement'] ?? '').toString(),
      isCompliant: json['isCompliant'] as bool?,
      observation: json['observation']?.toString(),
      correctiveAction:
      json['correctiveAction']?.toString(),
      dueDate: json['dueDate'] == null
          ? null
          : DateTime.tryParse(json['dueDate']),
      isResolved:
      (json['isResolved'] ?? false) as bool,
    );
  }
}

class Inspection {
  const Inspection({
    required this.id,
    required this.companyId,
    required this.constructionSiteId,
    required this.constructionSiteName,
    this.projectId,
    required this.inspectionNumber,
    required this.inspectionType,
    required this.title,
    required this.scheduledAtUtc,
    this.startedAtUtc,
    this.completedAtUtc,
    this.inspectorEmployeeId,
    this.externalInspectorName,
    this.externalOrganization,
    required this.status,
    this.summary,
    this.correctiveActionRequired,
    this.correctiveActionDueDate,
    this.signedOffBy,
    this.signedOffAtUtc,
    required this.checklistItems,
    required this.createdAtUtc,
    this.updatedAtUtc,
  });

  final String id;
  final String companyId;
  final String constructionSiteId;
  final String constructionSiteName;
  final String? projectId;

  final String inspectionNumber;
  final String inspectionType;
  final String title;

  final DateTime scheduledAtUtc;
  final DateTime? startedAtUtc;
  final DateTime? completedAtUtc;

  final String? inspectorEmployeeId;
  final String? externalInspectorName;
  final String? externalOrganization;

  final String status;

  final String? summary;
  final String? correctiveActionRequired;
  final DateTime? correctiveActionDueDate;

  final String? signedOffBy;
  final DateTime? signedOffAtUtc;

  final List<InspectionChecklistItem> checklistItems;

  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;

  bool get isCompleted =>
      status == 'Passed' ||
          status == 'Passed With Observations' ||
          status == 'Failed' ||
          status == 'Closed';

  int get checklistTotal => checklistItems.length;

  int get compliantItems => checklistItems
      .where((e) => e.isCompliant == true)
      .length;

  int get unresolvedItems => checklistItems
      .where((e) => !e.isResolved)
      .length;

  static String _statusName(dynamic value) {
    final status = value?.toString() ?? 'Scheduled';

    switch (status) {
      case '1':
      case 'Scheduled':
        return 'Scheduled';

      case '2':
      case 'InProgress':
      case 'In Progress':
        return 'In Progress';

      case '3':
      case 'Passed':
        return 'Passed';

      case '4':
      case 'PassedWithObservations':
      case 'Passed With Observations':
        return 'Passed With Observations';

      case '5':
      case 'Failed':
        return 'Failed';

      case '6':
      case 'CorrectiveActionRequired':
      case 'Corrective Action Required':
        return 'Corrective Action Required';

      case '7':
      case 'Closed':
        return 'Closed';

      case '8':
      case 'Cancelled':
        return 'Cancelled';

      default:
        return 'Scheduled';
    }
  }

  factory Inspection.fromJson(
      Map<String, dynamic> json,
      ) {
    return Inspection(
      id: (json['id'] ?? '').toString(),
      companyId: (json['companyId'] ?? '').toString(),
      constructionSiteId:
      (json['constructionSiteId'] ?? '').toString(),
      constructionSiteName:
      (json['constructionSiteName'] ?? '').toString(),
      projectId: json['projectId']?.toString(),
      inspectionNumber:
      (json['inspectionNumber'] ?? '').toString(),
      inspectionType:
      (json['inspectionType'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      scheduledAtUtc:
      DateTime.parse(json['scheduledAtUtc']),
      startedAtUtc: json['startedAtUtc'] == null
          ? null
          : DateTime.parse(json['startedAtUtc']),
      completedAtUtc:
      json['completedAtUtc'] == null
          ? null
          : DateTime.parse(
        json['completedAtUtc'],
      ),
      inspectorEmployeeId:
      json['inspectorEmployeeId']?.toString(),
      externalInspectorName:
      json['externalInspectorName']?.toString(),
      externalOrganization:
      json['externalOrganization']?.toString(),
      status: _statusName(json['status']),
      summary: json['summary']?.toString(),
      correctiveActionRequired:
      json['correctiveActionRequired']
          ?.toString(),
      correctiveActionDueDate:
      json['correctiveActionDueDate'] == null
          ? null
          : DateTime.tryParse(
        json['correctiveActionDueDate'],
      ),
      signedOffBy:
      json['signedOffBy']?.toString(),
      signedOffAtUtc:
      json['signedOffAtUtc'] == null
          ? null
          : DateTime.parse(
        json['signedOffAtUtc'],
      ),
      checklistItems:
      (json['checklistItems'] as List<dynamic>? ??
          [])
          .map(
            (e) => InspectionChecklistItem
            .fromJson(e),
      )
          .toList(),
      createdAtUtc:
      DateTime.parse(json['createdAtUtc']),
      updatedAtUtc:
      json['updatedAtUtc'] == null
          ? null
          : DateTime.parse(
        json['updatedAtUtc'],
      ),
    );
  }
}