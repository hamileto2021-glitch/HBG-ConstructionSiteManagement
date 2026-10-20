import '../../../../../core/network/api_client.dart';
import '../models/task_resource_assignment.dart';

class TaskResourceAssignmentRepository {
  final ApiClient _api;

  TaskResourceAssignmentRepository(this._api);

  Future<List<TaskResourceAssignment>> getByTask(
      String taskId) async {
    final response = await _api.get(
      '/task-resource-assignments/task/$taskId',
    );

    return (response as List)
        .map((e) => TaskResourceAssignment.fromJson(e))
        .toList();
  }

  Future<void> create(TaskResourceAssignment assignment) async {
    await _api.post(
      '/task-resource-assignments',
      body: assignment.toCreateJson(),
    );
  }

  Future<void> delete(String id) async {
    await _api.delete(
      '/task-resource-assignments/$id',
    );
  }
}