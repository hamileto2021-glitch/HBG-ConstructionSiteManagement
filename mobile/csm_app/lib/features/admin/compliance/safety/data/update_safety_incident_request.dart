

class UpdateSafetyIncidentRequest {
  const UpdateSafetyIncidentRequest({
    required this.constructionSiteId,
    required this.incidentNumber,
    required this.occurredAtUtc,
    required this.reportedAtUtc,
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
  });

  final String constructionSiteId;
  final String? projectId;
  final String? employeeId;

  final String incidentNumber;

  final DateTime occurredAtUtc;
  final DateTime reportedAtUtc;

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

  Map<String, dynamic> toJson() {
    return {
      'constructionSiteId':
      constructionSiteId,

      'projectId':
      projectId,

      'employeeId':
      employeeId,

      'incidentNumber':
      incidentNumber,

      'occurredAtUtc':
      occurredAtUtc.toIso8601String(),

      'reportedAtUtc':
      reportedAtUtc.toIso8601String(),

      'locationDescription':
      locationDescription,

      'description':
      description,

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
    };
  }

  static int _severityValue(
      String value,
      ) {
    switch (value.trim().toLowerCase()) {
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
    switch (value.trim().toLowerCase()) {
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
}