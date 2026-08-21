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

  factory Budget.fromJson(
    Map<String, dynamic> json,
  ) {
    return Budget(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      constructionSiteId:
          json['constructionSiteId'] as String,
      projectId: json['projectId'] as String?,
      budgetNumber:
          json['budgetNumber'] as String,
      name: json['name'] as String,
      description:
          json['description'] as String?,
      totalAmount:
          (json['totalAmount'] as num).toDouble(),
      currencyCode:
          json['currencyCode'] as String,
      effectiveFrom:
          _parseDate(json['effectiveFrom']),
      effectiveTo:
          _parseDate(json['effectiveTo']),
      status: _parseStatus(json['status']),
      approvedBy:
          json['approvedBy'] as String?,
      approvedAtUtc:
          _parseDate(json['approvedAtUtc']),
      createdAtUtc:
          DateTime.parse(
            json['createdAtUtc'] as String,
          ),
      updatedAtUtc:
          _parseDate(json['updatedAtUtc']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  static BudgetStatus _parseStatus(dynamic value) {
    final normalized =
        value.toString().toLowerCase();

    switch (normalized) {
      case 'draft':
        return BudgetStatus.draft;
      case 'pendingapproval':
      case 'pending_approval':
      case 'pending approval':
        return BudgetStatus.pendingApproval;
      case 'approved':
        return BudgetStatus.approved;
      case 'active':
        return BudgetStatus.active;
      case 'closed':
        return BudgetStatus.closed;
      case 'cancelled':
      case 'canceled':
        return BudgetStatus.cancelled;
      default:
        throw FormatException(
          'Unknown budget status: $value',
        );
    }
  }
}
