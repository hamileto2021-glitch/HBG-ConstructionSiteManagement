import '../../../../../core/network/api_client.dart';
import '../models/employee.dart';

class EmployeeRepository {
  EmployeeRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Employee>> getAll({EmployeeStatus? status}) async {
    final query = <String, String>{};

    if (status != null) {
      query['status'] = _statusName(status);
    }

    final response = await _apiClient.getList(
      '/Employees',
      queryParameters: query,
    );

    return response
        .map((item) => Employee.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Employee> getById(String employeeId) async {
    final response = await _apiClient.get('/Employees/$employeeId');

    return Employee.fromJson(response);
  }

  Future<Employee> create({
    required String employeeNumber,
    required String firstName,
    String? middleName,
    required String lastName,
    String? phoneNumber,
    String? email,
    String? nationalIdNumber,
    String? taxIdentificationNumber,
    DateTime? dateOfBirth,
    required DateTime hireDate,
    String? jobTitle,
    String? department,
    required EmployeeType employeeType,
    required WageType wageType,
    required double baseWage,
    required String currencyCode,
    String? bankName,
    String? bankAccountNumber,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) async {
    final response = await _apiClient.post(
      '/Employees',
      body: <String, dynamic>{
        'employeeNumber': employeeNumber,
        'firstName': firstName,
        'middleName': middleName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'email': email,
        'nationalIdNumber': nationalIdNumber,
        'taxIdentificationNumber': taxIdentificationNumber,
        'dateOfBirth': _dateOnly(dateOfBirth),
        'hireDate': _dateOnly(hireDate),
        'jobTitle': jobTitle,
        'department': department,
        'employeeType': _employeeTypeName(employeeType),
        'wageType': _wageTypeName(wageType),
        'baseWage': baseWage,
        'currencyCode': currencyCode,
        'bankName': bankName,
        'bankAccountNumber': bankAccountNumber,
        'emergencyContactName': emergencyContactName,
        'emergencyContactPhone': emergencyContactPhone,
      },
    );

    return Employee.fromJson(response);
  }

  Future<Employee> update({
    required String employeeId,
    required String firstName,
    String? middleName,
    required String lastName,
    String? phoneNumber,
    String? email,
    String? nationalIdNumber,
    String? taxIdentificationNumber,
    DateTime? dateOfBirth,
    required DateTime hireDate,
    String? jobTitle,
    String? department,
    required EmployeeType employeeType,
    required WageType wageType,
    required double baseWage,
    required String currencyCode,
    String? bankName,
    String? bankAccountNumber,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) async {
    final response = await _apiClient.put(
      '/Employees/$employeeId',
      body: <String, dynamic>{
        'firstName': firstName,
        'middleName': middleName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'email': email,
        'nationalIdNumber': nationalIdNumber,
        'taxIdentificationNumber': taxIdentificationNumber,
        'dateOfBirth': _dateOnly(dateOfBirth),
        'hireDate': _dateOnly(hireDate),
        'jobTitle': jobTitle,
        'department': department,
        'employeeType': _employeeTypeName(employeeType),
        'wageType': _wageTypeName(wageType),
        'baseWage': baseWage,
        'currencyCode': currencyCode,
        'bankName': bankName,
        'bankAccountNumber': bankAccountNumber,
        'emergencyContactName': emergencyContactName,
        'emergencyContactPhone': emergencyContactPhone,
      },
    );

    return Employee.fromJson(response);
  }

  Future<Employee> changeStatus({
    required String employeeId,
    required EmployeeStatus status,
    DateTime? terminationDate,
  }) async {
    final response = await _apiClient.put(
      '/Employees/$employeeId/status',
      body: <String, dynamic>{
        'status': _statusName(status),
        'terminationDate': _dateOnly(terminationDate),
      },
    );

    return Employee.fromJson(response);
  }

  String? _dateOnly(DateTime? date) {
    return date?.toIso8601String().split('T').first;
  }

  String _employeeTypeName(EmployeeType type) {
    switch (type) {
      case EmployeeType.permanent:
        return 'Permanent';
      case EmployeeType.temporary:
        return 'Temporary';
      case EmployeeType.contract:
        return 'Contract';
      case EmployeeType.dailyLabor:
        return 'DailyLabor';
    }
  }

  String _statusName(EmployeeStatus status) {
    switch (status) {
      case EmployeeStatus.active:
        return 'Active';
      case EmployeeStatus.inactive:
        return 'Inactive';
      case EmployeeStatus.suspended:
        return 'Suspended';
      case EmployeeStatus.terminated:
        return 'Terminated';
      case EmployeeStatus.onLeave:
        return 'OnLeave';
    }
  }

  String _wageTypeName(WageType type) {
    switch (type) {
      case WageType.hourly:
        return 'Hourly';
      case WageType.daily:
        return 'Daily';
      case WageType.weekly:
        return 'Weekly';
      case WageType.monthly:
        return 'Monthly';
    }
  }
}
