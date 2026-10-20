class SalaryStructure {
  const SalaryStructure({
    required this.id,
    required this.employeeId,
    required this.basicSalary,
    required this.housingAllowance,
    required this.transportAllowance,
    required this.positionAllowance,
    required this.overtimeMultiplier,
    required this.pensionPercentage,
    required this.bankName,
    required this.bankAccountNumber,
    required this.isActive,
  });

  final String id;
  final String employeeId;

  final double basicSalary;
  final double housingAllowance;
  final double transportAllowance;
  final double positionAllowance;

  final double overtimeMultiplier;
  final double pensionPercentage;

  final String bankName;
  final String bankAccountNumber;

  final bool isActive;

  factory SalaryStructure.fromJson(Map<String, dynamic> json) {
    return SalaryStructure(
      id: json['id'],
      employeeId: json['employeeId'],
      basicSalary: (json['basicSalary'] as num).toDouble(),
      housingAllowance:
      (json['housingAllowance'] as num).toDouble(),
      transportAllowance:
      (json['transportAllowance'] as num).toDouble(),
      positionAllowance:
      (json['positionAllowance'] as num).toDouble(),
      overtimeMultiplier:
      (json['overtimeMultiplier'] as num).toDouble(),
      pensionPercentage:
      (json['pensionPercentage'] as num).toDouble(),
      bankName: json['bankName'],
      bankAccountNumber: json['bankAccountNumber'],
      isActive: json['isActive'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'basicSalary': basicSalary,
      'housingAllowance': housingAllowance,
      'transportAllowance': transportAllowance,
      'positionAllowance': positionAllowance,
      'overtimeMultiplier': overtimeMultiplier,
      'pensionPercentage': pensionPercentage,
      'bankName': bankName,
      'bankAccountNumber': bankAccountNumber,
      'isActive': isActive,
    };
  }
}