class ComplianceSummaryReport {
  final int totalInspections;
  final int compliantItems;
  final int nonCompliantItems;
  final int openCorrectiveActions;
  final int activePermits;
  final int expiredPermits;
  final int safetyIncidents;
  final int safetyObservations;

  ComplianceSummaryReport({
    required this.totalInspections,
    required this.compliantItems,
    required this.nonCompliantItems,
    required this.openCorrectiveActions,
    required this.activePermits,
    required this.expiredPermits,
    required this.safetyIncidents,
    required this.safetyObservations,
  });

  factory ComplianceSummaryReport.fromJson(Map<String, dynamic> json) {
    return ComplianceSummaryReport(
      totalInspections: json['totalInspections'],
      compliantItems: json['compliantItems'],
      nonCompliantItems: json['nonCompliantItems'],
      openCorrectiveActions: json['openCorrectiveActions'],
      activePermits: json['activePermits'],
      expiredPermits: json['expiredPermits'],
      safetyIncidents: json['safetyIncidents'],
      safetyObservations: json['safetyObservations'],
    );
  }
}