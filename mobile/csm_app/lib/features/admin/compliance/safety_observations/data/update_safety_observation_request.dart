class UpdateSafetyObservationRequest {
  const UpdateSafetyObservationRequest({
    required this.constructionSiteId,
    required this.observationNumber,
    required this.category,
    required this.observationDate,
    required this.location,
    required this.description,
    required this.riskLevel,
    required this.positiveObservation,
    required this.status,
    this.projectId,
    this.employeeId,
    this.immediateAction,
    this.recommendedAction,
    this.closedAtUtc,
  });

  final String constructionSiteId;
  final String? projectId;
  final String? employeeId;

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

  Map<String, dynamic> toJson() {
    return {
      'constructionSiteId': constructionSiteId,
      'projectId': projectId,
      'employeeId': employeeId,
      'observationNumber': observationNumber,
      'category': _categoryValue(category),
      'observationDate': observationDate.toIso8601String(),
      'location': location,
      'description': description,
      'riskLevel': _riskValue(riskLevel),
      'positiveObservation': positiveObservation,
      'immediateAction': immediateAction,
      'recommendedAction': recommendedAction,
      'status': _statusValue(status),
      'closedAtUtc': closedAtUtc?.toIso8601String(),
    };
  }

  static int _categoryValue(String value) {
    switch (value) {
      case 'Housekeeping':
        return 1;
      case 'PPE':
        return 2;
      case 'WorkingAtHeight':
        return 3;
      case 'Electrical':
        return 4;
      case 'Excavation':
        return 5;
      case 'Lifting':
        return 6;
      case 'FireSafety':
        return 7;
      case 'Environmental':
        return 8;
      default:
        return 9;
    }
  }

  static int _riskValue(String value) {
    switch (value) {
      case 'Low':
        return 1;
      case 'Medium':
        return 2;
      case 'High':
        return 3;
      case 'Critical':
        return 4;
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