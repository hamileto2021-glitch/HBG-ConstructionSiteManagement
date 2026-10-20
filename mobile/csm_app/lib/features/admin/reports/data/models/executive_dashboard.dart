class ExecutiveDashboard {
  const ExecutiveDashboard({
    required this.activeProjects,
    required this.completedProjects,
    required this.totalBudget,
    required this.totalExpenses,
    required this.budgetUtilization,
    required this.openDelays,
    required this.totalEmployees,
    required this.lowStockItems,
    required this.openSafetyIncidents,
    required this.generatedAtUtc,
  });

  final int activeProjects;
  final int completedProjects;
  final double totalBudget;
  final double totalExpenses;
  final double budgetUtilization;
  final int openDelays;
  final int totalEmployees;
  final int lowStockItems;
  final int openSafetyIncidents;
  final DateTime generatedAtUtc;

  factory ExecutiveDashboard.fromJson(Map<String, dynamic> json) {
    return ExecutiveDashboard(
      activeProjects: json['activeProjects'],
      completedProjects: json['completedProjects'],
      totalBudget: (json['totalBudget'] as num).toDouble(),
      totalExpenses: (json['totalExpenses'] as num).toDouble(),
      budgetUtilization:
      (json['budgetUtilization'] as num).toDouble(),
      openDelays: json['openDelays'],
      totalEmployees: json['totalEmployees'],
      lowStockItems: json['lowStockItems'],
      openSafetyIncidents: json['openSafetyIncidents'],
      generatedAtUtc: DateTime.parse(json['generatedAtUtc']),
    );
  }
}