enum EquipmentHourStatus {
  draft,
  synchronized,
}

class EquipmentHour {
  const EquipmentHour({
    required this.id,
    required this.equipmentId,
    required this.projectId,
    required this.workDate,
    required this.startHour,
    required this.endHour,
    required this.totalHours,
    required this.operatorName,
    required this.createdAtUtc,
    this.remarks,
    this.status = EquipmentHourStatus.draft,
  });

  final String id;
  final String equipmentId;
  final String projectId;
  final DateTime workDate;
  final double startHour;
  final double endHour;
  final double totalHours;
  final String operatorName;
  final DateTime createdAtUtc;
  final String? remarks;
  final EquipmentHourStatus status;

  Map<String, dynamic> toJson() => {
    'id': id,
    'equipmentId': equipmentId,
    'projectId': projectId,
    'workDate': workDate.toIso8601String(),
    'startHour': startHour,
    'endHour': endHour,
    'totalHours': totalHours,
    'operatorName': operatorName,
    'createdAtUtc': createdAtUtc.toIso8601String(),
    'remarks': remarks,
    'status': status.name,
  };

  factory EquipmentHour.fromJson(Map<String, dynamic> json) {
    return EquipmentHour(
      id: json['id'],
      equipmentId: json['equipmentId'],
      projectId: json['projectId'],
      workDate: DateTime.parse(json['workDate']),
      startHour: (json['startHour'] as num).toDouble(),
      endHour: (json['endHour'] as num).toDouble(),
      totalHours: (json['totalHours'] as num).toDouble(),
      operatorName: json['operatorName'],
      createdAtUtc: DateTime.parse(json['createdAtUtc']),
      remarks: json['remarks'],
      status: EquipmentHourStatus.values.byName(json['status']),
    );
  }
}