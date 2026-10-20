

class SafetyIncident {
  const SafetyIncident({
    required this.id,
    required this.companyId,
    required this.constructionSiteId,
    required this.constructionSiteName,
    required this.incidentNumber,
    required this.occurredAtUtc,
    required this.reportedAtUtc,
    required this.reportedBy,
    required this.locationDescription,
    required this.description,
    required this.severity,
    required this.status,
    required this.injuryOccurred,
    required this.medicalTreatmentRequired,
    required this.lostTimeIncident,
    this.projectId,
    this.employeeId,
    this.immediateActionTaken,
    this.rootCause,
    this.correctiveAction,
    this.investigatedBy,
    this.investigationCompletedAtUtc,
    this.closedAtUtc,
    this.createdAtUtc,
    this.updatedAtUtc,
  });

  final String id;
  final String companyId;

  final String constructionSiteId;
  final String constructionSiteName;

  final String? projectId;
  final String? employeeId;

  final String incidentNumber;

  final DateTime occurredAtUtc;
  final DateTime reportedAtUtc;

  final String reportedBy;

  final String locationDescription;
  final String description;

  final String severity;
  final String status;

  final bool injuryOccurred;
  final bool medicalTreatmentRequired;
  final bool lostTimeIncident;

  final String? immediateActionTaken;
  final String? rootCause;
  final String? correctiveAction;

  final String? investigatedBy;

  final DateTime? investigationCompletedAtUtc;
  final DateTime? closedAtUtc;

  final DateTime? createdAtUtc;
  final DateTime? updatedAtUtc;

  factory SafetyIncident.fromJson(
      Map<String, dynamic> json,
      ) {
    return SafetyIncident(
      id: _string(json['id']),
      companyId: _string(json['companyId']),
      constructionSiteId: _string(
        json['constructionSiteId'] ??
            json['siteId'],
      ),
      constructionSiteName: _string(
        json['constructionSiteName'] ??
            json['constructionSite']?['name'] ??
            json['siteName'],
        fallback: 'Unknown Site',
      ),
      projectId: _nullableString(
        json['projectId'],
      ),
      employeeId: _nullableString(
        json['employeeId'],
      ),
      incidentNumber: _string(
        json['incidentNumber'],
      ),
      occurredAtUtc: _dateTime(
        json['occurredAtUtc'],
      ),
      reportedAtUtc: _dateTime(
        json['reportedAtUtc'],
      ),
      reportedBy: _string(
        json['reportedBy'],
        fallback: 'Unknown',
      ),
      locationDescription: _string(
        json['locationDescription'],
      ),
      description: _string(
        json['description'],
      ),
      severity: _enumName(
        json['severity'],
        _severityNames,
        'Minor',
      ),
      status: _enumName(
        json['status'],
        _statusNames,
        'Reported',
      ),
      injuryOccurred: _bool(
        json['injuryOccurred'],
      ),
      medicalTreatmentRequired: _bool(
        json['medicalTreatmentRequired'],
      ),
      lostTimeIncident: _bool(
        json['lostTimeIncident'],
      ),
      immediateActionTaken: _nullableString(
        json['immediateActionTaken'],
      ),
      rootCause: _nullableString(
        json['rootCause'],
      ),
      correctiveAction: _nullableString(
        json['correctiveAction'],
      ),
      investigatedBy: _nullableString(
        json['investigatedBy'],
      ),
      investigationCompletedAtUtc:
      _nullableDateTime(
        json['investigationCompletedAtUtc'],
      ),
      closedAtUtc: _nullableDateTime(
        json['closedAtUtc'],
      ),
      createdAtUtc: _nullableDateTime(
        json['createdAtUtc'],
      ),
      updatedAtUtc: _nullableDateTime(
        json['updatedAtUtc'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'constructionSiteId':
      constructionSiteId,
      'constructionSiteName':
      constructionSiteName,
      'projectId': projectId,
      'employeeId': employeeId,
      'incidentNumber': incidentNumber,
      'occurredAtUtc':
      occurredAtUtc.toIso8601String(),
      'reportedAtUtc':
      reportedAtUtc.toIso8601String(),
      'reportedBy': reportedBy,
      'locationDescription':
      locationDescription,
      'description': description,
      'severity':
      _severityValue(severity),
      'status':
      _statusValue(status),
      'injuryOccurred':
      injuryOccurred,
      'medicalTreatmentRequired':
      medicalTreatmentRequired,
      'lostTimeIncident':
      lostTimeIncident,
      'immediateActionTaken':
      immediateActionTaken,
      'rootCause':
      rootCause,
      'correctiveAction':
      correctiveAction,
      'investigatedBy':
      investigatedBy,
      'investigationCompletedAtUtc':
      investigationCompletedAtUtc
          ?.toIso8601String(),
      'closedAtUtc':
      closedAtUtc?.toIso8601String(),
      'createdAtUtc':
      createdAtUtc?.toIso8601String(),
      'updatedAtUtc':
      updatedAtUtc?.toIso8601String(),
    };
  }

  static const Map<int, String>
  _severityNames = {
    1: 'NearMiss',
    2: 'Minor',
    3: 'Moderate',
    4: 'Serious',
    5: 'Critical',
    6: 'Fatal',
  };

  static const Map<int, String>
  _statusNames = {
    1: 'Reported',
    2: 'UnderInvestigation',
    3: 'CorrectiveActionRequired',
    4: 'Resolved',
    5: 'Closed',
  };

  static String _enumName(
      dynamic value,
      Map<int, String> names,
      String fallback,
      ) {
    if (value is int) {
      return names[value] ?? fallback;
    }

    if (value is String) {
      final trimmed = value.trim();

      if (trimmed.isEmpty) {
        return fallback;
      }

      final numericValue =
      int.tryParse(trimmed);

      if (numericValue != null) {
        return names[numericValue] ?? fallback;
      }

      return trimmed;
    }

    return fallback;
  }

  static int _severityValue(
      String value,
      ) {
    final normalized =
    value.trim().toLowerCase();

    switch (normalized) {
      case 'nearmiss':
      case 'near miss':
        return 1;
      case 'minor':
        return 2;
      case 'moderate':
        return 3;
      case 'serious':
        return 4;
      case 'critical':
        return 5;
      case 'fatal':
        return 6;
      default:
        return 2;
    }
  }

  static int _statusValue(
      String value,
      ) {
    final normalized =
    value.trim().toLowerCase();

    switch (normalized) {
      case 'reported':
        return 1;
      case 'underinvestigation':
      case 'under investigation':
        return 2;
      case 'correctiveactionrequired':
      case 'corrective action required':
        return 3;
      case 'resolved':
        return 4;
      case 'closed':
        return 5;
      default:
        return 1;
    }
  }

  static String _string(
      dynamic value, {
        String fallback = '',
      }) {
    if (value == null) {
      return fallback;
    }

    return value.toString();
  }

  static String? _nullableString(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    final result = value.toString().trim();

    return result.isEmpty ? null : result;
  }

  static bool _bool(
      dynamic value,
      ) {
    if (value is bool) {
      return value;
    }

    if (value is int) {
      return value != 0;
    }

    if (value is String) {
      return value.toLowerCase() == 'true' ||
          value == '1';
    }

    return false;
  }

  static DateTime _dateTime(
      dynamic value,
      ) {
    final parsed =
    _nullableDateTime(value);

    return parsed ?? DateTime.now().toUtc();
  }

  static DateTime? _nullableDateTime(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }
}