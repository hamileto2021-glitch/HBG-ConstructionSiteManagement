enum PayrollStatus {
  draft,
  calculated,
  approved,
  paid,
  cancelled,
}

class PayrollAdjustment {
  const PayrollAdjustment({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.isDeduction,
    required this.otherDeduction,
  });

  final String id;
  final String type;
  final String description;
  final double amount;
  final bool isDeduction;
  final double otherDeduction;

  factory PayrollAdjustment.fromJson(
      Map<String, dynamic> json,
      ) {
    double numValue(dynamic value) =>
        (value as num?)?.toDouble() ?? 0.0;

    return PayrollAdjustment(
      id: json['id'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      amount: numValue(json['amount']),
      isDeduction: json['isDeduction'] as bool? ?? false,
      otherDeduction: numValue(json['otherDeduction']),
    );
  }
}

class Payroll {
  const Payroll({
    required this.id,
    required this.companyId,
    required this.employeeId,
    required this.employeeNumber,
    required this.employeeName,
    required this.periodStart,
    required this.periodEnd,
    required this.basePay,
    required this.regularHours,
    required this.overtimeHours,
    required this.overtimePay,
    required this.allowances,
    required this.bonuses,
    required this.grossPay,
    required this.taxDeduction,
    required this.pensionDeduction,
    required this.otherDeductions,
    required this.totalDeductions,
    required this.netPay,
    required this.currencyCode,
    required this.status,
    this.approvedBy,
    this.approvedAtUtc,
    this.paidAtUtc,
    this.paymentReference,
    required this.adjustments,
    required this.createdAtUtc,
  });

  final String id;
  final String companyId;
  final String employeeId;
  final String employeeNumber;
  final String employeeName;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double basePay;
  final double regularHours;
  final double overtimeHours;
  final double overtimePay;
  final double allowances;
  final double bonuses;
  final double grossPay;
  final double taxDeduction;
  final double pensionDeduction;
  final double otherDeductions;
  final double totalDeductions;
  final double netPay;
  final String currencyCode;
  final PayrollStatus status;
  final String? approvedBy;
  final DateTime? approvedAtUtc;
  final DateTime? paidAtUtc;
  final String? paymentReference;
  final List<PayrollAdjustment> adjustments;
  final DateTime createdAtUtc;

  factory Payroll.fromJson(Map<String, dynamic> json) {
    double numValue(dynamic value) =>
        (value as num?)?.toDouble() ?? 0.0;

    return Payroll(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      employeeId: json['employeeId'] as String,
      employeeNumber: json['employeeNumber'] as String,
      employeeName: json['employeeName'] as String,
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),

      basePay: numValue(json['basePay']),
      regularHours: numValue(json['regularHours']),
      overtimeHours: numValue(json['overtimeHours']),
      overtimePay: numValue(json['overtimePay']),
      allowances: numValue(json['allowances']),
      bonuses: numValue(json['bonuses']),
      grossPay: numValue(json['grossPay']),
      taxDeduction: numValue(json['taxDeduction']),
      pensionDeduction: numValue(json['pensionDeduction']),
      otherDeductions: numValue(json['otherDeductions']),
      totalDeductions: numValue(json['totalDeductions']),
      netPay: numValue(json['netPay']),

      currencyCode: json['currencyCode'] as String,
      status: _parsePayrollStatus(json['status']),
      approvedBy: json['approvedBy'] as String?,
      approvedAtUtc: _parseDate(json['approvedAtUtc']),
      paidAtUtc: _parseDate(json['paidAtUtc']),
      paymentReference: json['paymentReference'] as String?,
      adjustments: (json['adjustments'] as List<dynamic>? ?? [])
          .map((e) => PayrollAdjustment.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
    );
  } // <-- Factory ends here

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static PayrollStatus _parsePayrollStatus(dynamic value) {
    final name = value.toString().split('.').last;

    switch (name) {
      case 'draft':
      case 'Draft':
        return PayrollStatus.draft;
      case 'calculated':
      case 'Calculated':
        return PayrollStatus.calculated;
      case 'approved':
      case 'Approved':
        return PayrollStatus.approved;
      case 'paid':
      case 'Paid':
        return PayrollStatus.paid;
      case 'cancelled':
      case 'Cancelled':
        return PayrollStatus.cancelled;
      default:
        throw FormatException('Unknown payroll status: $value');
    }
  }
}

