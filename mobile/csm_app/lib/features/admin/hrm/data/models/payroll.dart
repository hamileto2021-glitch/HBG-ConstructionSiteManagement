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
  });

  final String id;
  final String type;
  final String description;
  final double amount;
  final bool isDeduction;

  factory PayrollAdjustment.fromJson(
    Map<String, dynamic> json,
  ) {
    return PayrollAdjustment(
      id: json['id'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      isDeduction: json['isDeduction'] as bool,
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

  factory Payroll.fromJson(
    Map<String, dynamic> json,
  ) {
    return Payroll(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      employeeId: json['employeeId'] as String,
      employeeNumber: json['employeeNumber'] as String,
      employeeName: json['employeeName'] as String,
      periodStart: DateTime.parse(
        json['periodStart'] as String,
      ),
      periodEnd: DateTime.parse(
        json['periodEnd'] as String,
      ),
      basePay: (json['basePay'] as num).toDouble(),
      regularHours:
          (json['regularHours'] as num).toDouble(),
      overtimeHours:
          (json['overtimeHours'] as num).toDouble(),
      overtimePay:
          (json['overtimePay'] as num).toDouble(),
      allowances:
          (json['allowances'] as num).toDouble(),
      bonuses:
          (json['bonuses'] as num).toDouble(),
      grossPay:
          (json['grossPay'] as num).toDouble(),
      taxDeduction:
          (json['taxDeduction'] as num).toDouble(),
      pensionDeduction:
          (json['pensionDeduction'] as num).toDouble(),
      otherDeductions:
          (json['otherDeductions'] as num).toDouble(),
      totalDeductions:
          (json['totalDeductions'] as num).toDouble(),
      netPay:
          (json['netPay'] as num).toDouble(),
      currencyCode:
          json['currencyCode'] as String,
      status:
          _parsePayrollStatus(json['status']),
      approvedBy:
          json['approvedBy'] as String?,
      approvedAtUtc:
          _parseDate(json['approvedAtUtc']),
      paidAtUtc:
          _parseDate(json['paidAtUtc']),
      paymentReference:
          json['paymentReference'] as String?,
      adjustments:
          (json['adjustments'] as List<dynamic>? ?? [])
              .map(
                (item) => PayrollAdjustment.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList(),
      createdAtUtc: DateTime.parse(
        json['createdAtUtc'] as String,
      ),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }

  static PayrollStatus _parsePayrollStatus(
    dynamic value,
  ) {
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
        throw FormatException(
          'Unknown payroll status: $value',
        );
    }
  }
}

