class EquipmentMaintenance {
  const EquipmentMaintenance({
    required this.id,
    required this.companyId,
    required this.equipmentId,
    required this.equipmentCode,
    required this.equipmentName,
    required this.maintenanceType,
    required this.scheduledAtUtc,
    this.startedAtUtc,
    this.completedAtUtc,
    this.meterReading,
    this.cost,
    required this.currencyCode,
    this.serviceProvider,
    this.description,
    this.partsReplaced,
    this.nextMaintenanceAtUtc,
    this.nextMaintenanceMeterReading,
    required this.createdAtUtc,
    this.updatedAtUtc,
  });

  final String id;
  final String companyId;
  final String equipmentId;
  final String equipmentCode;
  final String equipmentName;
  final String maintenanceType;
  final DateTime scheduledAtUtc;
  final DateTime? startedAtUtc;
  final DateTime? completedAtUtc;
  final double? meterReading;
  final double? cost;
  final String currencyCode;
  final String? serviceProvider;
  final String? description;
  final String? partsReplaced;
  final DateTime? nextMaintenanceAtUtc;
  final double? nextMaintenanceMeterReading;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;

  factory EquipmentMaintenance.fromJson(
    Map<String, dynamic> json,
  ) {
    return EquipmentMaintenance(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      equipmentId: json['equipmentId'] as String,
      equipmentCode: json['equipmentCode'] as String,
      equipmentName: json['equipmentName'] as String,
      maintenanceType: json['maintenanceType'] as String,
      scheduledAtUtc:
          DateTime.parse(json['scheduledAtUtc'] as String),
      startedAtUtc: _parseDate(json['startedAtUtc']),
      completedAtUtc: _parseDate(json['completedAtUtc']),
      meterReading:
          (json['meterReading'] as num?)?.toDouble(),
      cost: (json['cost'] as num?)?.toDouble(),
      currencyCode: json['currencyCode'] as String,
      serviceProvider:
          json['serviceProvider'] as String?,
      description: json['description'] as String?,
      partsReplaced:
          json['partsReplaced'] as String?,
      nextMaintenanceAtUtc:
          _parseDate(json['nextMaintenanceAtUtc']),
      nextMaintenanceMeterReading:
          (json['nextMaintenanceMeterReading'] as num?)
              ?.toDouble(),
      createdAtUtc:
          DateTime.parse(json['createdAtUtc'] as String),
      updatedAtUtc: _parseDate(json['updatedAtUtc']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
