enum EmployeeType { permanent, temporary, contract, dailyLabor }

enum EmployeeStatus {
  active,
  inactive,
  suspended,
  terminated,
  onLeave,
}

enum WageType { hourly, daily, weekly, monthly }

class Employee {
  const Employee({
    required this.id,
    required this.companyId,
    required this.employeeNumber,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.phoneNumber,
    this.email,
    this.nationalIdNumber,
    this.taxIdentificationNumber,
    this.dateOfBirth,
    required this.hireDate,
    this.terminationDate,
    this.jobTitle,
    this.department,
    required this.employeeType,
    required this.status,
    required this.wageType,
    required this.baseWage,
    required this.currencyCode,
    this.bankName,
    this.bankAccountNumber,
    this.emergencyContactName,
    this.emergencyContactPhone,
    required this.createdAtUtc,
  });

  final String id;
  final String companyId;
  final String employeeNumber;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? phoneNumber;
  final String? email;
  final String? nationalIdNumber;
  final String? taxIdentificationNumber;
  final DateTime? dateOfBirth;
  final DateTime hireDate;
  final DateTime? terminationDate;
  final String? jobTitle;
  final String? department;
  final EmployeeType employeeType;
  final EmployeeStatus status;
  final WageType wageType;
  final double baseWage;
  final String currencyCode;
  final String? bankName;
  final String? bankAccountNumber;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final DateTime createdAtUtc;

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      employeeNumber: json['employeeNumber'] as String,
      firstName: json['firstName'] as String,
      middleName: json['middleName'] as String?,
      lastName: json['lastName'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      email: json['email'] as String?,
      nationalIdNumber: json['nationalIdNumber'] as String?,
      taxIdentificationNumber: json['taxIdentificationNumber'] as String?,
      dateOfBirth: _parseDate(json['dateOfBirth']),
      hireDate: DateTime.parse(json['hireDate'] as String),
      terminationDate: _parseDate(json['terminationDate']),
      jobTitle: json['jobTitle'] as String?,
      department: json['department'] as String?,
      employeeType: _parseEmployeeType(json['employeeType']),
      status: _parseEmployeeStatus(json['status']),
      wageType: _parseWageType(json['wageType']),
      baseWage: (json['baseWage'] as num).toDouble(),
      currencyCode: json['currencyCode'] as String,
      bankName: json['bankName'] as String?,
      bankAccountNumber: json['bankAccountNumber'] as String?,
      emergencyContactName: json['emergencyContactName'] as String?,
      emergencyContactPhone: json['emergencyContactPhone'] as String?,
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }

  static EmployeeType _parseEmployeeType(dynamic value) {
    final name = value.toString().split('.').last;

    switch (name) {
      case 'permanent':
      case 'Permanent':
        return EmployeeType.permanent;
      case 'temporary':
      case 'Temporary':
        return EmployeeType.temporary;
      case 'contract':
      case 'Contract':
        return EmployeeType.contract;
      case 'dailyLabor':
      case 'DailyLabor':
        return EmployeeType.dailyLabor;
      default:
        throw FormatException('Unknown employee type: $value');
    }
  }

  static EmployeeStatus _parseEmployeeStatus(dynamic value) {
    final name = value.toString().split('.').last;

    switch (name) {
      case 'active':
      case 'Active':
        return EmployeeStatus.active;
      case 'inactive':
      case 'Inactive':
        return EmployeeStatus.inactive;
      case 'suspended':
      case 'Suspended':
        return EmployeeStatus.suspended;
      case 'terminated':
      case 'Terminated':
        return EmployeeStatus.terminated;
      case 'onLeave':
      case 'OnLeave':
        return EmployeeStatus.onLeave;
      default:
        throw FormatException('Unknown employee status: $value');
    }
  }

  static WageType _parseWageType(dynamic value) {
    final name = value.toString().split('.').last;

    switch (name) {
      case 'hourly':
      case 'Hourly':
        return WageType.hourly;
      case 'daily':
      case 'Daily':
        return WageType.daily;
      case 'weekly':
      case 'Weekly':
        return WageType.weekly;
      case 'monthly':
      case 'Monthly':
        return WageType.monthly;
      default:
        throw FormatException('Unknown wage type: $value');
    }
  }
}
