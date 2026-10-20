class ComplianceDashboard {
  final int totalInspections;
  final int openCorrectiveActions;
  final int activePermits;
  final int expiringPermits;
  final int openNcrs;
  final int safetyIncidents;
  final int safetyObservations;

  ComplianceDashboard({
    required this.totalInspections,
    required this.openCorrectiveActions,
    required this.activePermits,
    required this.expiringPermits,
    required this.openNcrs,
    required this.safetyIncidents,
    required this.safetyObservations,
  });

  factory ComplianceDashboard.fromJson(Map<String, dynamic> json) {
    return ComplianceDashboard(
      totalInspections: json['totalInspections'] ?? 0,
      openCorrectiveActions: json['openCorrectiveActions'] ?? 0,
      activePermits: json['activePermits'] ?? 0,
      expiringPermits: json['expiringPermits'] ?? 0,
      openNcrs: json['openNcrs'] ?? 0,
      safetyIncidents: json['safetyIncidents'] ?? 0,
      safetyObservations: json['safetyObservations'] ?? 0,
    );
  }
}