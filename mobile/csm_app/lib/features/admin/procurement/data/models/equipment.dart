class Equipment {
  const Equipment({
    required this.id,
    required this.companyId,
    required this.equipmentCode,
    required this.name,
    this.category,
    this.make,
    this.model,
    this.serialNumber,
    this.registrationNumber,
    required this.ownershipType,
    required this.status,
    this.vendorId,
    this.purchaseCost,
    this.rentalRate,
    this.rentalRateUnit,
    this.rentalStartDate,
    this.rentalEndDate,
    required this.currentMeterReading,
    required this.meterUnit,
    required this.isActive,
    required this.createdAtUtc,
    this.updatedAtUtc,
  });

  final String id;
  final String companyId;
  final String equipmentCode;
  final String name;
  final String? category;
  final String? make;
  final String? model;
  final String? serialNumber;
  final String? registrationNumber;
  final String ownershipType;
  final String status;
  final String? vendorId;
  final double? purchaseCost;
  final double? rentalRate;
  final String? rentalRateUnit;
  final DateTime? rentalStartDate;
  final DateTime? rentalEndDate;
  final double currentMeterReading;
  final String meterUnit;
  final bool isActive;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      equipmentCode: json['equipmentCode'] as String,
      name: json['name'] as String,
      category: json['category'] as String?,
      make: json['make'] as String?,
      model: json['model'] as String?,
      serialNumber: json['serialNumber'] as String?,
      registrationNumber: json['registrationNumber'] as String?,
      ownershipType: json['ownershipType'] as String,
      status: json['status'] as String,
      vendorId: json['vendorId'] as String?,
      purchaseCost: (json['purchaseCost'] as num?)?.toDouble(),
      rentalRate: (json['rentalRate'] as num?)?.toDouble(),
      rentalRateUnit: json['rentalRateUnit'] as String?,
      rentalStartDate: _parseDate(json['rentalStartDate']),
      rentalEndDate: _parseDate(json['rentalEndDate']),
      currentMeterReading:
          (json['currentMeterReading'] as num).toDouble(),
      meterUnit: json['meterUnit'] as String,
      isActive: json['isActive'] as bool,
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
