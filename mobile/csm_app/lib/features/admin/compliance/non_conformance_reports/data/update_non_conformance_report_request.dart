class UpdateNonConformanceReportRequest {
  const UpdateNonConformanceReportRequest({
    required this.constructionSiteId,
    required this.ncrNumber,
    required this.title,
    required this.description,
    required this.location,
    required this.severity,
    required this.status,
    required this.reportedDate,
    this.projectId,
    this.assignedToEmployeeId,
    this.dueDate,
    this.closedDate,
    this.rootCause,
    this.correctiveAction,
    this.preventiveAction,
  });

  final String constructionSiteId;
  final String? projectId;
  final String? assignedToEmployeeId;

  final String ncrNumber;
  final String title;
  final String description;
  final String location;

  final String severity;
  final String status;

  final DateTime reportedDate;
  final DateTime? dueDate;
  final DateTime? closedDate;

  final String? rootCause;
  final String? correctiveAction;
  final String? preventiveAction;

  Map<String, dynamic> toJson() {
    return {
      'constructionSiteId': constructionSiteId,
      'projectId': projectId,
      'assignedToEmployeeId': assignedToEmployeeId,
      'ncrNumber': ncrNumber,
      'title': title,
      'description': description,
      'location': location,
      'severity': _severityValue(severity),
      'status': _statusValue(status),
      'reportedDate': reportedDate.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'closedDate': closedDate?.toIso8601String(),
      'rootCause': rootCause,
      'correctiveAction': correctiveAction,
      'preventiveAction': preventiveAction,
    };
  }

  static int _severityValue(String value) {
    switch (value) {
      case 'Minor':
        return 1;
      case 'Major':
        return 2;
      case 'Critical':
        return 3;
      default:
        return 1;
    }
  }

  static int _statusValue(String value) {
    switch (value) {
      case 'Open':
        return 1;
      case 'InProgress':
        return 2;
      case 'Closed':
        return 3;
      default:
        return 1;
    }
  }
}