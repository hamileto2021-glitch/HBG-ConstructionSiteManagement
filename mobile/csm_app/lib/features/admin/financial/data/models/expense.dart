

enum ExpenseStatus {
  draft,
  submitted,
  approved,
  rejected,
  paid,
  cancelled,
}

extension ExpenseStatusX on ExpenseStatus {
  String get apiValue {
    switch (this) {
      case ExpenseStatus.draft:
        return 'Draft';
      case ExpenseStatus.submitted:
        return 'Submitted';
      case ExpenseStatus.approved:
        return 'Approved';
      case ExpenseStatus.rejected:
        return 'Rejected';
      case ExpenseStatus.paid:
        return 'Paid';
      case ExpenseStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get displayName {
    switch (this) {
      case ExpenseStatus.draft:
        return 'Draft';
      case ExpenseStatus.submitted:
        return 'Submitted';
      case ExpenseStatus.approved:
        return 'Approved';
      case ExpenseStatus.rejected:
        return 'Rejected';
      case ExpenseStatus.paid:
        return 'Paid';
      case ExpenseStatus.cancelled:
        return 'Cancelled';
    }
  }

  static ExpenseStatus fromJson(dynamic value) {
    final text = value.toString().toLowerCase();

    switch (text) {
      case 'draft':
      case '1':
        return ExpenseStatus.draft;
      case 'submitted':
      case '2':
        return ExpenseStatus.submitted;
      case 'approved':
      case '3':
        return ExpenseStatus.approved;
      case 'rejected':
      case '4':
        return ExpenseStatus.rejected;
      case 'paid':
      case '5':
        return ExpenseStatus.paid;
      case 'cancelled':
      case '6':
        return ExpenseStatus.cancelled;
      default:
        throw FormatException(
          'Unknown expense status: $value',
        );
    }
  }
}

class Expense {
  const Expense({
    required this.id,
    required this.companyId,
    required this.constructionSiteId,
    this.projectId,
    required this.costCodeId,
    this.vendorId,
    required this.expenseNumber,
    required this.expenseDate,
    required this.description,
    required this.amount,
    required this.taxAmount,
    required this.currencyCode,
    required this.exchangeRate,
    this.referenceNumber,
    this.receiptDocumentUrl,
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
  final String costCodeId;
  final String? vendorId;
  final String expenseNumber;
  final DateTime expenseDate;
  final String description;
  final double amount;
  final double taxAmount;
  final String currencyCode;
  final double exchangeRate;
  final String? referenceNumber;
  final String? receiptDocumentUrl;
  final ExpenseStatus status;
  final String? approvedBy;
  final DateTime? approvedAtUtc;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;

  factory Expense.fromJson(
    Map<String, dynamic> json,
  ) {
    return Expense(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      constructionSiteId:
          json['constructionSiteId'] as String,
      projectId: json['projectId'] as String?,
      costCodeId: json['costCodeId'] as String,
      vendorId: json['vendorId'] as String?,
      expenseNumber:
          json['expenseNumber'] as String,
      expenseDate: DateTime.parse(
        json['expenseDate'] as String,
      ),
      description:
          json['description'] as String,
      amount:
          (json['amount'] as num).toDouble(),
      taxAmount:
          (json['taxAmount'] as num).toDouble(),
      currencyCode:
          json['currencyCode'] as String,
      exchangeRate:
          (json['exchangeRate'] as num).toDouble(),
      referenceNumber:
          json['referenceNumber'] as String?,
      receiptDocumentUrl:
          json['receiptDocumentUrl'] as String?,
      status:
          ExpenseStatusX.fromJson(json['status']),
      approvedBy:
          json['approvedBy'] as String?,
      approvedAtUtc:
          _parseDate(json['approvedAtUtc']),
      createdAtUtc: DateTime.parse(
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
}
