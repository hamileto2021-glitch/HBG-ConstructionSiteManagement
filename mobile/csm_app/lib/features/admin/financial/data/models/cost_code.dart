class CostCode {
  const CostCode({
    required this.id,
    required this.companyId,
    required this.code,
    required this.name,
    this.description,
    this.parentCostCodeId,
    required this.isActive,
    required this.createdAtUtc,
    this.updatedAtUtc,
  });

  final String id;
  final String companyId;
  final String code;
  final String name;
  final String? description;
  final String? parentCostCodeId;
  final bool isActive;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;

  factory CostCode.fromJson(
    Map<String, dynamic> json,
  ) {
    return CostCode(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      parentCostCodeId:
          json['parentCostCodeId'] as String?,
      isActive: json['isActive'] as bool,
      createdAtUtc:
          DateTime.parse(json['createdAtUtc'] as String),
      updatedAtUtc:
          _parseDate(json['updatedAtUtc']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
