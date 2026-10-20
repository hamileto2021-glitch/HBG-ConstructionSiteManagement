class Equipment {
  const Equipment({
    required this.id,
    required this.equipmentCode,
    required this.name,
    required this.category,
    required this.make,
    required this.model,
    this.serialNumber,
    this.registrationNumber,
    this.vendorId,
    required this.ownershipType,
    this.purchaseCost,
    this.rentalRate,
    this.rentalRateUnit,
    required this.currentMeterReading,
    required this.meterUnit,
    required this.status,
    required this.isActive,
    this.siteId,
    this.siteName,
  });

  final String id;
  final String equipmentCode;
  final String name;
  final String category;

  final String make;
  final String model;

  final String? serialNumber;
  final String? registrationNumber;
  final String? vendorId;

  final String ownershipType;

  final double? purchaseCost;
  final double? rentalRate;
  final String? rentalRateUnit;

  final double currentMeterReading;
  final String meterUnit;

  final String status;
  final bool isActive;

  // Active assignment (NEW)
  final String? siteId;
  final String? siteName;

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'] as String,
      equipmentCode: json['equipmentCode'] as String,
      name: json['name'] as String,
      category: json['category'] as String,

      make: json['make'] as String? ?? '',
      model: json['model'] as String? ?? '',

      serialNumber: json['serialNumber'] as String?,
      registrationNumber: json['registrationNumber'] as String?,
      vendorId: json['vendorId'] as String?,

      ownershipType: json['ownershipType'] as String,

      purchaseCost: (json['purchaseCost'] as num?)?.toDouble(),
      rentalRate: (json['rentalRate'] as num?)?.toDouble(),
      rentalRateUnit: json['rentalRateUnit'] as String?,

      currentMeterReading:
      (json['currentMeterReading'] as num?)?.toDouble() ?? 0,

      meterUnit: json['meterUnit'] as String? ?? 'Hours',

      status: json['status'] as String,
      isActive: json['isActive'] as bool? ?? true,

      // NEW
      siteId: json['siteId'] as String?,
      siteName: json['siteName'] as String?,
    );
  }
}