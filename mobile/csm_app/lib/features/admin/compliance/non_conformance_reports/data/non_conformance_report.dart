class NonConformanceReport {
  const NonConformanceReport({
    required this.id,
    required this.companyId,
    required this.constructionSiteId,
    required this.constructionSiteName,
    this.projectId,
    this.projectName,
    required this.raisedById,
    required this.raisedByName,
    this.assignedToEmployeeId,
    this.assignedToEmployeeName,
    required this.ncrNumber,
    required this.title,
    required this.description,
    required this.location,
    required this.severity,
    required this.status,
    required this.reportedDate,
    this.dueDate,
    this.closedDate,
    this.rootCause,
    this.correctiveAction,
    this.preventiveAction,
    required this.createdAtUtc,
    this.updatedAtUtc,
  });

  final String id;
  final String companyId;

  final String constructionSiteId;
  final String constructionSiteName;

  final String? projectId;
  final String? projectName;

  final String raisedById;
  final String raisedByName;

  final String? assignedToEmployeeId;
  final String? assignedToEmployeeName;

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

  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;

  factory NonConformanceReport.fromJson(Map<String, dynamic> json) {
    return NonConformanceReport(
      id: json['id']?.toString() ?? '',
      companyId: json['companyId']?.toString() ?? '',
      constructionSiteId:
      json['constructionSiteId']?.toString() ?? '',
      constructionSiteName:
      json['constructionSiteName']?.toString() ?? '',
      projectId: json['projectId']?.toString(),
      projectName: json['projectName']?.toString(),
      raisedById: json['raisedById']?.toString() ?? '',
      raisedByName: json['raisedByName']?.toString() ?? '',
      assignedToEmployeeId:
      json['assignedToEmployeeId']?.toString(),
      assignedToEmployeeName:
      json['assignedToEmployeeName']?.toString(),
      ncrNumber: json['ncrNumber']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      severity: _severity(json['severity']),
      status: _status(json['status']),
      reportedDate:
      _date(json['reportedDate']) ?? DateTime.now(),
      dueDate: _date(json['dueDate']),
      closedDate: _date(json['closedDate']),
      rootCause: json['rootCause']?.toString(),
      correctiveAction: json['correctiveAction']?.toString(),
      preventiveAction: json['preventiveAction']?.toString(),
      createdAtUtc:
      _date(json['createdAtUtc']) ?? DateTime.now(),
      updatedAtUtc: _date(json['updatedAtUtc']),
    );
  }

  static DateTime? _date(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static String _severity(dynamic value) {
    switch (value.toString()) {
      case '1':
      case 'Minor':
        return 'Minor';
      case '2':
      case 'Major':
        return 'Major';
      case '3':
      case 'Critical':
        return 'Critical';
      default:
        return 'Minor';
    }
  }

  static String _status(dynamic value) {
    switch (value.toString()) {
      case '1':
      case 'Open':
        return 'Open';
      case '2':
      case 'InProgress':
        return 'InProgress';
      case '3':
      case 'Closed':
        return 'Closed';
      default:
        return 'Open';
    }
  }
}