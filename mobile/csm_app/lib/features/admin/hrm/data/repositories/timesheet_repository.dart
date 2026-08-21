import 'package:csm_app/core/network/api_client.dart';
import '../models/timesheet.dart';

class TimesheetRepository {
  TimesheetRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Timesheet>> getAll({
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
      '/Timesheets',
      queryParameters: query,
    );

    return response
        .map(
          (item) => Timesheet.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<Timesheet> getById(
    String timesheetId,
  ) async {
    final response = await _apiClient.get(
      '/Timesheets/$timesheetId',
    );

    return Timesheet.fromJson(response);
  }

  Future<Timesheet> create({
    required String employeeId,
    required DateTime periodStartDate,
    required DateTime periodEndDate,
    String? remarks,
  }) async {
    final response = await _apiClient.post(
      '/Timesheets',
      body: <String, dynamic>{
        'employeeId': employeeId,
        'periodStartDate': _dateOnly(periodStartDate),
        'periodEndDate': _dateOnly(periodEndDate),
        'remarks': remarks,
      },
    );

    return Timesheet.fromJson(response);
  }

  Future<Timesheet> submit({
    required String timesheetId,
    String? remarks,
  }) async {
    final response = await _apiClient.put(
      '/Timesheets/$timesheetId/submit',
      body: <String, dynamic>{
        'remarks': remarks,
      },
    );

    return Timesheet.fromJson(response);
  }

  Future<Timesheet> review({
    required String timesheetId,
    required TimesheetStatus status,
    String? remarks,
  }) async {
    final response = await _apiClient.put(
      '/Timesheets/$timesheetId/review',
      body: <String, dynamic>{
        'status': _statusName(status),
        'remarks': remarks,
      },
    );

    return Timesheet.fromJson(response);
  }

  Future<Timesheet> cancel({
    required String timesheetId,
    String? remarks,
  }) async {
    final response = await _apiClient.put(
      '/Timesheets/$timesheetId/cancel',
      body: <String, dynamic>{
        'remarks': remarks,
      },
    );

    return Timesheet.fromJson(response);
  }

  String _dateOnly(DateTime date) {
    return date.toIso8601String().split('T').first;
  }

  String _statusName(TimesheetStatus status) {
    switch (status) {
      case TimesheetStatus.draft:
        return 'Draft';
      case TimesheetStatus.submitted:
        return 'Submitted';
      case TimesheetStatus.approved:
        return 'Approved';
      case TimesheetStatus.rejected:
        return 'Rejected';
      case TimesheetStatus.cancelled:
        return 'Cancelled';
    }
  }
}

