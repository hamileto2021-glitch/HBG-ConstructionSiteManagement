class ExecutiveDashboard {
  const ExecutiveDashboard({
    required this.totalSites,
    required this.activeSites,
    required this.totalProjects,
    required this.totalContractValue,
    required this.totalBudget,
    required this.totalExpenses,
    required this.totalInvoices,
    required this.totalCompletedPayments,
    required this.outstandingInvoices,
    required this.sitesByStatus,
    required this.projectsByStatus,
  });

  final int totalSites;
  final int activeSites;
  final int totalProjects;

  final double totalContractValue;
  final double totalBudget;
  final double totalExpenses;
  final double totalInvoices;
  final double totalCompletedPayments;
  final double outstandingInvoices;

  final Map<String, int> sitesByStatus;
  final Map<String, int> projectsByStatus;

  factory ExecutiveDashboard.fromJson(Map<String, dynamic> json) {
    return ExecutiveDashboard(
      totalSites: json['totalSites'] as int,
      activeSites: json['activeSites'] as int,
      totalProjects: json['totalProjects'] as int,
      totalContractValue:
      (json['totalContractValue'] as num).toDouble(),
      totalBudget: (json['totalBudget'] as num).toDouble(),
      totalExpenses: (json['totalExpenses'] as num).toDouble(),
      totalInvoices: (json['totalInvoices'] as num).toDouble(),
      totalCompletedPayments:
      (json['totalCompletedPayments'] as num).toDouble(),
      outstandingInvoices:
      (json['outstandingInvoices'] as num).toDouble(),
      sitesByStatus: Map<String, int>.from(
        json['sitesByStatus'] as Map,
      ),
      projectsByStatus: Map<String, int>.from(
        json['projectsByStatus'] as Map,
      ),
    );
  }
}