import '../../../../../core/network/api_client.dart';
import '../models/wbs_task.dart';

class WbsTaskRepository {
  WbsTaskRepository(this._apiClient);

  final ApiClient _apiClient;

  static const _endpoint = '/wbs-tasks';

  Future<List<WbsTask>> getAll() async {
    final response = await _apiClient.get(_endpoint);

    return (response as List)
        .map((e) => WbsTask.fromJson(e))
        .toList();
  }

  Future<List<WbsTask>> getByProject(String projectId) async {
    final all = await getAll();

    return all.where((e) => e.projectId == projectId).toList();
  }

  Future<WbsTask> getById(String id) async {
    final response = await _apiClient.get('$_endpoint/$id');

    return WbsTask.fromJson(response);
  }

  Future<WbsTask> create({
    required String projectId,
    required String projectMilestoneId,
    String? assignedEmployeeId,
    required String taskCode,
    required String name,
    String? description,
    required DateTime plannedStartDate,
    required DateTime plannedFinishDate,
    DateTime? actualStartDate,
    DateTime? actualFinishDate,
    required WbsTaskStatus status,
    required TaskPriority priority,
    required double progressPercentage,
    required double estimatedHours,
    required double actualHours,
  }) async {
    final response = await _apiClient.post(
      _endpoint,
      body: {
        'projectId': projectId,
        'projectMilestoneId': projectMilestoneId,
        'assignedEmployeeId': assignedEmployeeId,
        'taskCode': taskCode,
        'name': name,
        'description': description,
        'plannedStartDate':
        plannedStartDate.toIso8601String().split('T').first,
        'plannedFinishDate':
        plannedFinishDate.toIso8601String().split('T').first,
        'actualStartDate':
        actualStartDate?.toIso8601String().split('T').first,
        'actualFinishDate':
        actualFinishDate?.toIso8601String().split('T').first,
        'status': status.name,
        'priority': priority.name,
        'progressPercentage': progressPercentage,
        'estimatedHours': estimatedHours,
        'actualHours': actualHours,
      },
    );

    return WbsTask.fromJson(response);
  }

  Future<WbsTask> update({
    required String taskId,
    required String projectId,
    required String projectMilestoneId,
    String? assignedEmployeeId,
    required String taskCode,
    required String name,
    String? description,
    required DateTime plannedStartDate,
    required DateTime plannedFinishDate,
    DateTime? actualStartDate,
    DateTime? actualFinishDate,
    required WbsTaskStatus status,
    required TaskPriority priority,
    required double progressPercentage,
    required double estimatedHours,
    required double actualHours,
  }) async {
    final response = await _apiClient.put(
      '$_endpoint/$taskId',
      body: {
        'projectId': projectId,
        'projectMilestoneId': projectMilestoneId,
        'assignedEmployeeId': assignedEmployeeId,
        'taskCode': taskCode,
        'name': name,
        'description': description,
        'plannedStartDate':
        plannedStartDate.toIso8601String().split('T').first,
        'plannedFinishDate':
        plannedFinishDate.toIso8601String().split('T').first,
        'actualStartDate':
        actualStartDate?.toIso8601String().split('T').first,
        'actualFinishDate':
        actualFinishDate?.toIso8601String().split('T').first,
        'status': status.name,
        'priority': priority.name,
        'progressPercentage': progressPercentage,
        'estimatedHours': estimatedHours,
        'actualHours': actualHours,
      },
    );

    return WbsTask.fromJson(response);
  }

  Future<void> delete(String id) async {
    await _apiClient.delete('$_endpoint/$id');
  }
}