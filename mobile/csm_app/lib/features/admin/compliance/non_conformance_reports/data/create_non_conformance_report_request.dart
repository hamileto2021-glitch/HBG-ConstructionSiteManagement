class CreateNonConformanceReportRequest {
  const CreateNonConformanceReportRequest({
    required this.constructionSiteId,
    required this.ncrNumber,
    required this.title,
    required this.description,
    required this.location,
    required this.severity,
    required this.reportedDate,
    this.projectId,
    this.assignedToEmployeeId,
    this.dueDate,
  });

  final String constructionSiteId;
  final String? projectId;
  final String? assignedToEmployeeId;

  final String ncrNumber;
  final String title;
  final String description;
  final String location;

  final String severity;

  final DateTime reportedDate;
  final DateTime? dueDate;

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
      'reportedDate': reportedDate.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
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
}