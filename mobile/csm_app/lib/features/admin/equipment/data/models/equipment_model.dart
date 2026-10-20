class EquipmentModel {
  final String id;
  final String equipmentCode;
  final String name;
  final String category;
  final String? manufacturer;
  final String? model;
  final String? serialNumber;
  final bool isRented;
  final String? supplierName;
  final String? purchaseDate;
  final String? nextMaintenanceDate;
  final bool isActive;

  const EquipmentModel({
    required this.id,
    required this.equipmentCode,
    required this.name,
    required this.category,
    this.manufacturer,
    this.model,
    this.serialNumber,
    required this.isRented,
    this.supplierName,
    this.purchaseDate,
    this.nextMaintenanceDate,
    required this.isActive,
  });

  factory EquipmentModel.fromJson(Map<String, dynamic> json) {
    return EquipmentModel(
      id: json['id'] as String,
      equipmentCode: json['equipmentCode'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      manufacturer: json['manufacturer'],
      model: json['model'],
      serialNumber: json['serialNumber'],
      isRented: json['isRented'] ?? false,
      supplierName: json['supplierName'],
      purchaseDate: json['purchaseDate'],
      nextMaintenanceDate: json['nextMaintenanceDate'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'equipmentCode': equipmentCode,
      'name': name,
      'category': category,
      'manufacturer': manufacturer,
      'model': model,
      'serialNumber': serialNumber,
      'isRented': isRented,
      'supplierName': supplierName,
      'purchaseDate': purchaseDate,
      'nextMaintenanceDate': nextMaintenanceDate,
    };
  }
}