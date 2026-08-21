import '../../../../../core/network/api_client.dart';
import '../models/leave.dart';

class LeaveRepository {
  LeaveRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Leave>> getAll({
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
      '/Leaves',
      queryParameters: query,
    );

    return response
        .map(
          (item) => Leave.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<Leave> getById(String leaveId) async {
    final response = await _apiClient.get(
      '/Leaves/$leaveId',
    );

    return Leave.fromJson(response);
  }

  Future<Leave> create({
    required String employeeId,
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) async {
    final response = await _apiClient.post(
      '/Leaves',
      body: <String, dynamic>{
        'employeeId': employeeId,
        'leaveType': leaveType,
        'startDate': _dateOnly(startDate),
        'endDate': _dateOnly(endDate),
        'reason': reason,
      },
    );

    return Leave.fromJson(response);
  }

  Future<Leave> review({
    required String leaveId,
    required LeaveStatus status,
    String? remarks,
  }) async {
    final response = await _apiClient.put(
      '/Leaves/$leaveId/review',
      body: <String, dynamic>{
        'status': _statusName(status),
        'remarks': remarks,
      },
    );

    return Leave.fromJson(response);
  }

  Future<Leave> cancel({
    required String leaveId,
    String? remarks,
  }) async {
    final response = await _apiClient.put(
      '/Leaves/$leaveId/cancel',
      body: <String, dynamic>{
        'remarks': remarks,
      },
    );

    return Leave.fromJson(response);
  }

  String _dateOnly(DateTime date) {
    return date.toIso8601String().split('T').first;
  }

  String _statusName(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.pending:
        return 'Pending';
      case LeaveStatus.approved:
        return 'Approved';
      case LeaveStatus.rejected:
        return 'Rejected';
      case LeaveStatus.cancelled:
        return 'Cancelled';
    }
  }
}
