enum BudgetStatus {
  draft,
  pendingApproval,
  approved,
  active,
  closed,
  cancelled,
}

class Budget {
  const Budget({
    required this.id,
    required this.companyId,
    required this.constructionSiteId,
    this.projectId,
    required this.constructionSiteName,
    required this.projectName,
    required this.budgetNumber,
    required this.name,
    this.description,
    required this.totalAmount,
    required this.currencyCode,
    this.effectiveFrom,
    this.effectiveTo,
    required this.status,
    this.approvedBy,
    this.approvedAtUtc,
    required this.createdAtUtc,
    this.updatedAtUtc,
  });

  final String id;
  final String companyId;
  final String constructionSiteId;
  final String? projectId;
  final String constructionSiteName;
  final String? projectName;
  final String budgetNumber;
  final String name;
  final String? description;
  final double totalAmount;
  final String currencyCode;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final BudgetStatus status;
  final String? approvedBy;
  final DateTime? approvedAtUtc;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      companyId: json['companyId'],

      constructionSiteId: json['constructionSiteId'],
      constructionSiteName:
      json['constructionSiteName'] ?? '',

      projectId: json['projectId'],
      projectName: json['projectName'],

      budgetNumber: json['budgetNumber'],
      name: json['name'],
      description: json['description'],
      totalAmount:
      (json['totalAmount'] as num).toDouble(),
      currencyCode: json['currencyCode'],

      effectiveFrom:
      DateTime.parse(json['effectiveFrom']),
      effectiveTo: json['effectiveTo'] == null
          ? null
          : DateTime.parse(json['effectiveTo']),

      status: BudgetStatus.values.firstWhere(
            (e) =>
        e.name.toLowerCase() ==
            json['status'].toString().toLowerCase(),
      ),

      approvedBy: json['approvedBy'],
      approvedAtUtc: json['approvedAtUtc'] == null
          ? null
          : DateTime.parse(json['approvedAtUtc']),
      createdAtUtc: DateTime.parse(json['createdAtUtc']),
      updatedAtUtc: json['updatedAtUtc'] == null
          ? null
          : DateTime.parse(json['updatedAtUtc']),
    );
  }




}
