import '../../../../../core/network/api_client.dart';
import '../models/payroll.dart';

class PayrollRepository {
  PayrollRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Payroll>> getAll({
    String? employeeId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final query = <String, String>{};

    if (employeeId != null) {
      query['employeeId'] = employeeId;
    }

    if (fromDate != null) {
      query['fromDate'] = _dateOnly(fromDate);
    }

    if (toDate != null) {
      query['toDate'] = _dateOnly(toDate);
    }

    final response = await _apiClient.getList(
      '/Payroll',
      queryParameters: query,
    );

    return response
        .map(
          (item) => Payroll.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<Payroll> getById(String payrollId) async {
    final response = await _apiClient.get(
      '/Payroll/$payrollId',
    );

    return Payroll.fromJson(response);
  }

  Future<Payroll> create({
    required String employeeId,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final response = await _apiClient.post(
      '/Payroll',
      body: <String, dynamic>{
        'employeeId': employeeId,
        'periodStart': _dateOnly(periodStart),
        'periodEnd': _dateOnly(periodEnd),
      },
    );

    return Payroll.fromJson(response);
  }

  Future<Payroll> calculate({
    required String payrollId,
    required double overtimeMultiplier,
    required double allowances,
    required double bonuses,
    required double taxDeduction,
    required double pensionDeduction,
    required double otherDeductions,
  }) async {
    final response = await _apiClient.put(
      '/Payroll/$payrollId/calculate',
      body: <String, dynamic>{
        'overtimeMultiplier': overtimeMultiplier,
        'allowances': allowances,
        'bonuses': bonuses,
        'taxDeduction': taxDeduction,
        'pensionDeduction': pensionDeduction,
        'otherDeductions': otherDeductions,
      },
    );

    return Payroll.fromJson(response);
  }

  Future<Payroll> approve({
    required String payrollId,
    String? remarks,
  }) async {
    final response = await _apiClient.put(
      '/Payroll/$payrollId/approve',
      body: <String, dynamic>{
        'remarks': remarks,
      },
    );

    return Payroll.fromJson(response);
  }

  Future<Payroll> markPaid({
    required String payrollId,
    required String paymentReference,
  }) async {
    final response = await _apiClient.put(
      '/Payroll/$payrollId/paid',
      body: <String, dynamic>{
        'paymentReference': paymentReference,
      },
    );

    return Payroll.fromJson(response);
  }

  Future<Payroll> cancel({
    required String payrollId,
    String? remarks,
  }) async {
    final response = await _apiClient.put(
      '/Payroll/$payrollId/cancel',
      body: <String, dynamic>{
        'remarks': remarks,
      },
    );

    return Payroll.fromJson(response);
  }

  Future<Payroll> addAdjustment({
    required String payrollId,
    required String type,
    required String description,
    required double amount,
    required bool isDeduction,
  }) async {
    final response = await _apiClient.post(
      '/Payroll/$payrollId/adjustments',
      body: <String, dynamic>{
        'type': type,
        'description': description,
        'amount': amount,
        'isDeduction': isDeduction,
      },
    );

    return Payroll.fromJson(response);
  }

  String _dateOnly(DateTime date) {
    return date.toIso8601String().split('T').first;
  }
}
