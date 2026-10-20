class EquipmentFuelLog {
  const EquipmentFuelLog({
    required this.id,
    required this.equipmentId,
    required this.equipmentCode,
    required this.equipmentName,
    this.siteId,
    this.siteName,
    required this.refueledAtUtc,
    required this.liters,
    required this.unitPrice,
    required this.totalCost,
    required this.meterReading,
    required this.fuelType,
    this.supplierName,
    this.invoiceNumber,
    this.remarks,
  });

  final String id;
  final String equipmentId;
  final String equipmentCode;
  final String equipmentName;

  final String? siteId;
  final String? siteName;

  final DateTime refueledAtUtc;

  final double liters;
  final double unitPrice;
  final double totalCost;
  final double meterReading;

  final String fuelType;

  final String? supplierName;
  final String? invoiceNumber;
  final String? remarks;

  factory EquipmentFuelLog.fromJson(
      Map<String, dynamic> json,
      ) {
    return EquipmentFuelLog(
      id: json['id'],
      equipmentId: json['equipmentId'],
      equipmentCode: json['equipmentCode'],
      equipmentName: json['equipmentName'],
      siteId: json['siteId'],
      siteName: json['siteName'],
      refueledAtUtc: DateTime.parse(json['refueledAtUtc']),
      liters: (json['liters'] as num).toDouble(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      totalCost: (json['totalCost'] as num).toDouble(),
      meterReading: (json['meterReading'] as num).toDouble(),
      fuelType: json['fuelType'],
      supplierName: json['supplierName'],
      invoiceNumber: json['invoiceNumber'],
      remarks: json['remarks'],
    );
  }
}