import '../../../../../core/network/api_client.dart';
import '../models/work_task.dart';

class WorkTaskRepository {
  WorkTaskRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<WorkTask>> getAll({
    required String projectId,
    String? projectPhaseId,
  }) async {
    final query = <String, String>{
      'projectId': projectId,
    };

    if (projectPhaseId != null && projectPhaseId.isNotEmpty) {
      query['projectPhaseId'] = projectPhaseId;
    }

    final response = await _apiClient.getList(
      '/WorkTasks',
      queryParameters: query,
    );

    return response
        .map(
          (item) => WorkTask.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<WorkTask> getById(String taskId) async {
    final response = await _apiClient.get(
      '/WorkTasks/$taskId',
    );

    return WorkTask.fromJson(response);
  }

  Future<WorkTask> create({
    required String projectId,
    String? projectPhaseId,
    String? milestoneId,
    required String taskNumber,
    required String title,
    String? description,
    DateTime? plannedStartDate,
    DateTime? plannedEndDate,
    required TaskPriority priority,
  }) async {
    final response = await _apiClient.post(
      '/WorkTasks',
      body: <String, dynamic>{
        'projectId': projectId,
        'projectPhaseId': projectPhaseId,
        'milestoneId': milestoneId,
        'taskNumber': taskNumber,
        'title': title,
        'description': description,
        'plannedStartDate':
            plannedStartDate?.toIso8601String().split('T').first,
        'plannedEndDate':
            plannedEndDate?.toIso8601String().split('T').first,
        'priority': _priorityName(priority),
      },
    );

    return WorkTask.fromJson(response);
  }

  Future<WorkTask> update({
    required String taskId,
    String? projectPhaseId,
    String? milestoneId,
    required String taskNumber,
    required String title,
    String? description,
    DateTime? plannedStartDate,
    DateTime? plannedEndDate,
    required TaskPriority priority,
  }) async {
    final response = await _apiClient.put(
      '/WorkTasks/$taskId',
      body: <String, dynamic>{
        'projectPhaseId': projectPhaseId,
        'milestoneId': milestoneId,
        'taskNumber': taskNumber,
        'title': title,
        'description': description,
        'plannedStartDate':
            plannedStartDate?.toIso8601String().split('T').first,
        'plannedEndDate':
            plannedEndDate?.toIso8601String().split('T').first,
        'priority': _priorityName(priority),
      },
    );

    return WorkTask.fromJson(response);
  }

  Future<WorkTask> changeStatus({
    required String taskId,
    required WorkTaskStatus status,
  }) async {
    final response = await _apiClient.put(
      '/WorkTasks/$taskId/status',
      body: <String, dynamic>{
        'status': _statusName(status),
      },
    );

    return WorkTask.fromJson(response);
  }

  Future<WorkTask> updateProgress({
    required String taskId,
    required double progressPercentage,
  }) async {
    final response = await _apiClient.put(
      '/WorkTasks/$taskId/progress',
      body: <String, dynamic>{
        'progressPercentage': progressPercentage,
      },
    );

    return WorkTask.fromJson(response);
  }

  String _priorityName(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.normal:
        return 'Normal';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.critical:
        return 'Critical';
    }
  }

  String _statusName(WorkTaskStatus status) {
    switch (status) {
      case WorkTaskStatus.notStarted:
        return 'NotStarted';
      case WorkTaskStatus.inProgress:
        return 'InProgress';
      case WorkTaskStatus.blocked:
        return 'Blocked';
      case WorkTaskStatus.onHold:
        return 'OnHold';
      case WorkTaskStatus.completed:
        return 'Completed';
      case WorkTaskStatus.cancelled:
        return 'Cancelled';
    }
  }
}
