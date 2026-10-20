class DashboardStats {
  final int activeProjects;
  final int totalSites;
  final int totalEmployees;
  final int todayAttendance;
  final int openWorkPermits;
  final int lowStockItems;
  final int backupCount;
  final DateTime? lastBackupUtc;

  const DashboardStats({
    required this.activeProjects,
    required this.totalSites,
    required this.totalEmployees,
    required this.todayAttendance,
    required this.openWorkPermits,
    required this.lowStockItems,
    required this.backupCount,
    required this.lastBackupUtc,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      activeProjects: json['activeProjects'] ?? 0,
      totalSites: json['totalSites'] ?? 0,
      totalEmployees: json['totalEmployees'] ?? 0,
      todayAttendance: json['todayAttendance'] ?? 0,
      openWorkPermits: json['openWorkPermits'] ?? 0,
      lowStockItems: json['lowStockItems'] ?? 0,
      backupCount: json['backupCount'] ?? 0,
      lastBackupUtc: json['lastBackupUtc'] != null
          ? DateTime.parse(json['lastBackupUtc'])
          : null,
    );
  }
}