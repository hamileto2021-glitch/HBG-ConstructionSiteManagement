class EquipmentUtilization {
  const EquipmentUtilization({
    required this.equipmentId,
    required this.equipmentCode,
    required this.equipmentName,
    required this.hoursWorked,
    required this.fuelConsumed,
    required this.downtimeHours,
    required this.maintenanceCost,
  });

  final String equipmentId;
  final String equipmentCode;
  final String equipmentName;

  final double hoursWorked;
  final double fuelConsumed;
  final double downtimeHours;
  final double maintenanceCost;

  double get fuelPerHour =>
      hoursWorked == 0 ? 0 : fuelConsumed / hoursWorked;

  double get utilization =>
      (hoursWorked + downtimeHours) == 0
          ? 0
          : (hoursWorked / (hoursWorked + downtimeHours)) * 100;

  factory EquipmentUtilization.fromJson(
      Map<String, dynamic> json,
      ) {
    return EquipmentUtilization(
      equipmentId: json['equipmentId'],
      equipmentCode: json['equipmentCode'],
      equipmentName: json['equipmentName'],
      hoursWorked:
      (json['hoursWorked'] as num).toDouble(),
      fuelConsumed:
      (json['fuelConsumed'] as num).toDouble(),
      downtimeHours:
      (json['downtimeHours'] as num).toDouble(),
      maintenanceCost:
      (json['maintenanceCost'] as num).toDouble(),
    );
  }
}