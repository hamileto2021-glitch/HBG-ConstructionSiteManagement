class TaskResourceAssignment {
  final String id;
  final String wbsTaskId;
  final String employeeId;
  final String employeeName;
  final String role;
  final double plannedHours;
  final double actualHours;
  final DateTime assignedDate;
  final String? remarks;

  const TaskResourceAssignment({
    required this.id,
    required this.wbsTaskId,
    required this.employeeId,
    required this.employeeName,
    required this.role,
    required this.plannedHours,
    required this.actualHours,
    required this.assignedDate,
    this.remarks,
  });

  factory TaskResourceAssignment.fromJson(Map<String, dynamic> json) {
    return TaskResourceAssignment(
      id: json['id'],
      wbsTaskId: json['wbsTaskId'],
      employeeId: json['employeeId'],
      employeeName: json['employeeName'],
      role: json['role'],
      plannedHours: (json['plannedHours'] as num).toDouble(),
      actualHours: (json['actualHours'] as num).toDouble(),
      assignedDate: DateTime.parse(json['assignedDate']),
      remarks: json['remarks'],
    );
  }

  Map<String, dynamic> toCreateJson() => {
    'wbsTaskId': wbsTaskId,
    'employeeId': employeeId,
    'role': role,
    'plannedHours': plannedHours,
    'actualHours': actualHours,
    'assignedDate':
    assignedDate.toIso8601String().split('T').first,
    'remarks': remarks,
  };
}