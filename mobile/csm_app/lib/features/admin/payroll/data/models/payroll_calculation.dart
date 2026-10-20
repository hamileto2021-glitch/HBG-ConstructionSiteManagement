class PayrollCalculation {
  const PayrollCalculation({
    required this.employeeId,
    required this.employeeName,
    required this.basicSalary,
    required this.housingAllowance,
    required this.transportAllowance,
    required this.positionAllowance,
    required this.overtimeHours,
    required this.overtimeAmount,
    required this.grossSalary,
    required this.pensionDeduction,
    required this.taxDeduction,
    required this.otherDeduction,
    required this.totalDeductions,
    required this.netSalary,
  });

  final String employeeId;
  final String employeeName;

  final double basicSalary;
  final double housingAllowance;
  final double transportAllowance;
  final double positionAllowance;

  final double overtimeHours;
  final double overtimeAmount;

  final double grossSalary;
  final double pensionDeduction;
  final double taxDeduction;
  final double otherDeduction;
  final double totalDeductions;
  final double netSalary;

  factory PayrollCalculation.fromJson(Map<String, dynamic> json) {
    double numValue(dynamic value) => (value as num).toDouble();

    return PayrollCalculation(
      employeeId: json['employeeId'],
      employeeName: json['employeeName'],
      basicSalary: numValue(json['basicSalary']),
      housingAllowance: numValue(json['housingAllowance']),
      transportAllowance: numValue(json['transportAllowance']),
      positionAllowance: numValue(json['positionAllowance']),
      overtimeHours: numValue(json['overtimeHours']),
      overtimeAmount: numValue(json['overtimeAmount']),
      grossSalary: numValue(json['grossSalary']),
      pensionDeduction: numValue(json['pensionDeduction']),
      taxDeduction: numValue(json['taxDeduction']),
      otherDeduction: numValue(json['otherDeduction']),
      totalDeductions: numValue(json['totalDeductions']),
      netSalary: numValue(json['netSalary']),
    );
  }
}