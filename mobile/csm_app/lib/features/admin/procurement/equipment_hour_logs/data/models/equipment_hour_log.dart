class EquipmentHourLog {
  const EquipmentHourLog({
    required this.id,
    required this.equipmentId,
    required this.equipmentCode,
    required this.equipmentName,
    required this.loggedAtUtc,
    required this.previousMeterReading,
    required this.currentMeterReading,
    required this.hoursWorked,
    this.operatorEmployeeId,
    this.operatorName,
    this.projectId,
    this.projectName,
    this.activity,
    this.remarks,
  });

  final String id;
  final String equipmentId;
  final String equipmentCode;
  final String equipmentName;

  final DateTime loggedAtUtc;

  final double previousMeterReading;
  final double currentMeterReading;
  final double hoursWorked;

  final String? operatorEmployeeId;
  final String? operatorName;

  final String? projectId;
  final String? projectName;

  final String? activity;
  final String? remarks;

  factory EquipmentHourLog.fromJson(
      Map<String, dynamic> json,
      ) {
    return EquipmentHourLog(
      id: json['id'],
      equipmentId: json['equipmentId'],
      equipmentCode: json['equipmentCode'],
      equipmentName: json['equipmentName'],
      loggedAtUtc: DateTime.parse(json['loggedAtUtc']),
      previousMeterReading:
      (json['previousMeterReading'] as num).toDouble(),
      currentMeterReading:
      (json['currentMeterReading'] as num).toDouble(),
      hoursWorked:
      (json['hoursWorked'] as num).toDouble(),
      operatorEmployeeId: json['operatorEmployeeId'],
      operatorName: json['operatorName'],
      projectId: json['projectId'],
      projectName: json['projectName'],
      activity: json['activity'],
      remarks: json['remarks'],
    );
  }
}