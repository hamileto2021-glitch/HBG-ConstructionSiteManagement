class SafetyObservation {
  const SafetyObservation({
    required this.id,
    required this.companyId,
    required this.constructionSiteId,
    required this.constructionSiteName,
    required this.observerId,
    required this.observerName,
    required this.observationNumber,
    required this.category,
    required this.observationDate,
    required this.location,
    required this.description,
    required this.riskLevel,
    required this.positiveObservation,
    required this.status,
    required this.createdAtUtc,
    this.projectId,
    this.projectName,
    this.employeeId,
    this.employeeName,
    this.immediateAction,
    this.recommendedAction,
    this.closedAtUtc,
    this.updatedAtUtc,
  });

  final String id;
  final String companyId;

  final String constructionSiteId;
  final String constructionSiteName;

  final String? projectId;
  final String? projectName;

  final String observerId;
  final String observerName;

  final String? employeeId;
  final String? employeeName;

  final String observationNumber;

  final String category;

  final DateTime observationDate;

  final String location;
  final String description;

  final String riskLevel;

  final bool positiveObservation;

  final String? immediateAction;
  final String? recommendedAction;

  final String status;

  final DateTime? closedAtUtc;

  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;

  factory SafetyObservation.fromJson(Map<String, dynamic> json) {
    return SafetyObservation(
      id: json['id']?.toString() ?? '',
      companyId: json['companyId']?.toString() ?? '',

      constructionSiteId:
      json['constructionSiteId']?.toString() ?? '',
      constructionSiteName:
      json['constructionSiteName']?.toString() ?? '',

      projectId: json['projectId']?.toString(),
      projectName: json['projectName']?.toString(),

      observerId: json['observerId']?.toString() ?? '',
      observerName: json['observerName']?.toString() ?? '',

      employeeId: json['employeeId']?.toString(),
      employeeName: json['employeeName']?.toString(),

      observationNumber:
      json['observationNumber']?.toString() ?? '',

      category: _normalizeCategory(json['category']),

      observationDate:
      _parseDate(json['observationDate']) ?? DateTime.now(),

      location: json['location']?.toString() ?? '',
      description: json['description']?.toString() ?? '',

      riskLevel: _normalizeRisk(json['riskLevel']),

      positiveObservation:
      json['positiveObservation'] ?? false,

      immediateAction: json['immediateAction']?.toString(),
      recommendedAction: json['recommendedAction']?.toString(),

      status: _normalizeStatus(json['status']),

      closedAtUtc: _parseDate(json['closedAtUtc']),

      createdAtUtc:
      _parseDate(json['createdAtUtc']) ?? DateTime.now(),

      updatedAtUtc: _parseDate(json['updatedAtUtc']),
    );
  }
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    final text = value.toString();
    if (text.isEmpty || text.toLowerCase() == 'null') return null;

    return DateTime.tryParse(text);
  }

  static String _normalizeCategory(
      dynamic value,
      ) {
    if (value is String) return value;

    switch (value) {
      case 1:
        return 'Housekeeping';
      case 2:
        return 'PPE';
      case 3:
        return 'WorkingAtHeight';
      case 4:
        return 'Electrical';
      case 5:
        return 'Excavation';
      case 6:
        return 'Lifting';
      case 7:
        return 'FireSafety';
      case 8:
        return 'Environmental';
      default:
        return 'Other';
    }
  }

  static String _normalizeRisk(
      dynamic value,
      ) {
    if (value is String) return value;

    switch (value) {
      case 1:
        return 'Low';
      case 2:
        return 'Medium';
      case 3:
        return 'High';
      case 4:
        return 'Critical';
      default:
        return 'Low';
    }
  }

  static String _normalizeStatus(
      dynamic value,
      ) {
    if (value is String) return value;

    switch (value) {
      case 1:
        return 'Open';
      case 2:
        return 'InProgress';
      case 3:
        return 'Closed';
      default:
        return 'Open';
    }
  }

}