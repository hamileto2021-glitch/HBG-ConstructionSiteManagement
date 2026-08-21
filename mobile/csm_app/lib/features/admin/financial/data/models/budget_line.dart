class BudgetLine {
  const BudgetLine({
    required this.id,
    required this.companyId,
    required this.budgetId,
    required this.costCodeId,
    required this.costCode,
    this.description,
    required this.budgetedAmount,
    required this.revisedAmount,
    required this.createdAtUtc,
    this.updatedAtUtc,
  });

  final String id;
  final String companyId;
  final String budgetId;
  final String costCodeId;
  final String costCode;
  final String? description;
  final double budgetedAmount;
  final double revisedAmount;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;

  factory BudgetLine.fromJson(
    Map<String, dynamic> json,
  ) {
    return BudgetLine(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      budgetId: json['budgetId'] as String,
      costCodeId: json['costCodeId'] as String,
      costCode: json['costCode'] as String,
      description: json['description'] as String?,
      budgetedAmount:
          (json['budgetedAmount'] as num).toDouble(),
      revisedAmount:
          (json['revisedAmount'] as num).toDouble(),
      createdAtUtc:
          DateTime.parse(json['createdAtUtc'] as String),
      updatedAtUtc:
          json['updatedAtUtc'] == null
              ? null
              : DateTime.parse(
                  json['updatedAtUtc'] as String,
                ),
    );
  }
}
