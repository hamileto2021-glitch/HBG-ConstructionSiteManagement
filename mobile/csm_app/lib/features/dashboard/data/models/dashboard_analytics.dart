class DashboardAnalytics {
  const DashboardAnalytics({
    required this.activeProjects,
    required this.totalSites,
    required this.totalEmployees,
    required this.totalEquipment,
    required this.lowStockItems,
    required this.equipmentAvailable,
    required this.equipmentInUse,
    required this.projectProgress,
  });

  final int activeProjects;
  final int totalSites;
  final int totalEmployees;
  final int totalEquipment;
  final int lowStockItems;

  final int equipmentAvailable;
  final int equipmentInUse;

  final List<double> projectProgress;

  factory DashboardAnalytics.fromJson(Map<String, dynamic> json) {
    return DashboardAnalytics(
      activeProjects: json['activeProjects'],
      totalSites: json['totalSites'],
      totalEmployees: json['totalEmployees'],
      totalEquipment: json['totalEquipment'],
      lowStockItems: json['lowStockItems'],
      equipmentAvailable: json['equipmentAvailable'],
      equipmentInUse: json['equipmentInUse'],
      projectProgress: (json['projectProgress'] as List)
          .map((e) => (e as num).toDouble())
          .toList(),
    );
  }
}