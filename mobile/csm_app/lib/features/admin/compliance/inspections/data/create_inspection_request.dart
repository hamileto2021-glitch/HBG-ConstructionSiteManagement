class InspectionChecklistItemRequest {
  const InspectionChecklistItemRequest({
    required this.sequence,
    required this.requirement,
    this.isCompliant,
    this.observation,
    this.correctiveAction,
    this.dueDate,
    this.isResolved = false,
  });

  final int sequence;
  final String requirement;
  final bool? isCompliant;
  final String? observation;
  final String? correctiveAction;
  final DateTime? dueDate;
  final bool isResolved;

  String _date(DateTime value) =>
      value.toIso8601String().split('T').first;

  Map<String, dynamic> toJson() => {
    'sequence': sequence,
    'requirement': requirement,
    'isCompliant': isCompliant,
    'observation': observation,
    'correctiveAction': correctiveAction,
    'dueDate': dueDate == null ? null : _date(dueDate!),
    'isResolved': isResolved,
  };
}

class CreateInspectionRequest {
  const CreateInspectionRequest({
    required this.constructionSiteId,
    required this.inspectionNumber,
    required this.inspectionType,
    required this.title,
    required this.scheduledAtUtc,
    this.startedAtUtc,
    this.completedAtUtc,
    this.projectId,
    this.inspectorEmployeeId,
    this.externalInspectorName,
    this.externalOrganization,
    this.status = 1,
    this.summary,
    this.correctiveActionRequired,
    this.correctiveActionDueDate,
    this.signedOffBy,
    this.signedOffAtUtc,
    this.checklistItems = const [],
  });

  final String constructionSiteId;
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

  final int status;

  final String? summary;
  final String? correctiveActionRequired;
  final DateTime? correctiveActionDueDate;

  final String? signedOffBy;
  final DateTime? signedOffAtUtc;

  final List<InspectionChecklistItemRequest> checklistItems;

  String _date(DateTime value) =>
      value.toIso8601String().split('T').first;

  Map<String, dynamic> toJson() {
    return {
      'constructionSiteId': constructionSiteId,
      'projectId': projectId,
      'inspectionNumber': inspectionNumber,
      'inspectionType': inspectionType,
      'title': title,
      'scheduledAtUtc': scheduledAtUtc.toUtc().toIso8601String(),
      'startedAtUtc': startedAtUtc?.toUtc().toIso8601String(),
      'completedAtUtc': completedAtUtc?.toUtc().toIso8601String(),
      'inspectorEmployeeId': inspectorEmployeeId,
      'externalInspectorName': externalInspectorName,
      'externalOrganization': externalOrganization,
      'status': status,
      'summary': summary,
      'correctiveActionRequired': correctiveActionRequired,
      'correctiveActionDueDate': correctiveActionDueDate == null
          ? null
          : _date(correctiveActionDueDate!),
      'signedOffBy': signedOffBy,
      'signedOffAtUtc': signedOffAtUtc?.toUtc().toIso8601String(),
      'checklistItems':
      checklistItems.map((e) => e.toJson()).toList(),
    };
  }
}