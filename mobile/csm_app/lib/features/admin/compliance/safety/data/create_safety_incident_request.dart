class CreateSafetyIncidentRequest {
  const CreateSafetyIncidentRequest({
    required this.constructionSiteId,
    required this.incidentNumber,
    required this.occurredAtUtc,
    required this.locationDescription,
    required this.description,
    required this.severity,
    this.projectId,
    this.employeeId,
    this.status = 'Reported',
    this.injuryOccurred = false,
    this.medicalTreatmentRequired = false,
    this.lostTimeIncident = false,
    this.immediateActionTaken,
    this.rootCause,
    this.correctiveAction,
    this.investigatedBy,
  });

  final String constructionSiteId;
  final String? projectId;
  final String? employeeId;

  final String incidentNumber;
  final DateTime occurredAtUtc;
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

  Map<String, dynamic> toJson() {
    return {
      'constructionSiteId': constructionSiteId,
      'projectId': projectId,
      'employeeId': employeeId,
      'incidentNumber': incidentNumber,
      'occurredAtUtc': occurredAtUtc.toIso8601String(),
      'locationDescription': locationDescription,
      'description': description,
      'severity': severity,
      'status': status,
      'injuryOccurred': injuryOccurred,
      'medicalTreatmentRequired': medicalTreatmentRequired,
      'lostTimeIncident': lostTimeIncident,
      'immediateActionTaken': immediateActionTaken,
      'rootCause': rootCause,
      'correctiveAction': correctiveAction,
      'investigatedBy': investigatedBy,
    };
  }
}