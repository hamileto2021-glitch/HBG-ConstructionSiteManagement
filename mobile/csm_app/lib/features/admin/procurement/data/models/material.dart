enum MaterialType {
  bulk,
  rebarLinear,
}

class Material {
  const Material({
    required this.id,
    required this.companyId,
    required this.materialCode,
    required this.name,
    this.description,
    required this.category,
    required this.unitOfMeasure,
    required this.materialType,
    this.rebarDiameterMm,
    this.rebarGrade,
    this.defaultCostCodeId,
    this.defaultCostCode,
    this.defaultCostCodeName,
    this.standardUnitCost,
    required this.isActive,
    required this.createdAtUtc,
    this.updatedAtUtc,
  });

  final String id;
  final String companyId;
  final String materialCode;
  final String name;
  final String? description;
  final String category;
  final String unitOfMeasure;
  final MaterialType materialType;
  final double? rebarDiameterMm;
  final String? rebarGrade;
  final String? defaultCostCodeId;
  final String? defaultCostCode;
  final String? defaultCostCodeName;
  final double? standardUnitCost;
  final bool isActive;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;

  factory Material.fromJson(
    Map<String, dynamic> json,
  ) {
    return Material(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      materialCode: json['materialCode'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      unitOfMeasure: json['unitOfMeasure'] as String,
      materialType: _materialTypeFromValue(
        json['materialType'],
      ),
      rebarDiameterMm:
          (json['rebarDiameterMm'] as num?)?.toDouble(),
      rebarGrade:
          json['rebarGrade'] as String?,
      defaultCostCodeId:
          json['defaultCostCodeId'] as String?,
      defaultCostCode:
          json['defaultCostCode'] as String?,
      defaultCostCodeName:
          json['defaultCostCodeName'] as String?,
      standardUnitCost:
          (json['standardUnitCost'] as num?)?.toDouble(),
      isActive: json['isActive'] as bool,
      createdAtUtc:
          DateTime.parse(json['createdAtUtc'] as String),
      updatedAtUtc: json['updatedAtUtc'] == null
          ? null
          : DateTime.tryParse(
              json['updatedAtUtc'].toString(),
            ),
    );
  }

  static MaterialType _materialTypeFromValue(
    dynamic value,
  ) {
    if (value is num) {
      switch (value.toInt()) {
        case 2:
          return MaterialType.rebarLinear;
        case 1:
        default:
          return MaterialType.bulk;
      }
    }

    if (value is String) {
      switch (value.toLowerCase()) {
        case 'rebarlinear':
        case 'rebar_linear':
          return MaterialType.rebarLinear;
        case 'bulk':
        default:
          return MaterialType.bulk;
      }
    }

    return MaterialType.bulk;
  }
}
