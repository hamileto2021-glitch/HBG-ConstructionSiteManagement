import '../../../../../core/network/api_client.dart';
import '../models/daily_progress_log.dart';

class DailyProgressLogRepository {
  DailyProgressLogRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<DailyProgressLog>> getAll({
    required String projectId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final query = <String, String>{
      'projectId': projectId,
    };

    if (fromDate != null) {
      query['fromDate'] =
          fromDate.toIso8601String().split('T').first;
    }

    if (toDate != null) {
      query['toDate'] =
          toDate.toIso8601String().split('T').first;
    }

    final response = await _apiClient.getList(
      '/DailyProgressLogs',
      queryParameters: query,
    );

    return response
        .map(
          (item) => DailyProgressLog.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<DailyProgressLog> getById(
    String logId,
  ) async {
    final response = await _apiClient.get(
      '/DailyProgressLogs/$logId',
    );

    return DailyProgressLog.fromJson(response);
  }
}
