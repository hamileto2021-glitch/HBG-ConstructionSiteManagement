import '../../../../../core/network/api_client.dart';
import '../models/project_delay.dart';

class ProjectDelayRepository {
  ProjectDelayRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<ProjectDelay>> getAll({
    String? projectId,
  }) async {
    final path = projectId == null
        ? '/project-delays'
        : '/project-delays?projectId=$projectId';

    final response = await _apiClient.getList(path);

    return response
        .map((e) => ProjectDelay.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProjectDelay> getById(String id) async {
    final response = await _apiClient.get('/project-delays/$id');
    return ProjectDelay.fromJson(response);
  }

  Future<ProjectDelay> create(ProjectDelay delay) async {
    final response = await _apiClient.post(
      '/project-delays',
      body: delay.toCreateJson(),
    );

    return ProjectDelay.fromJson(response);
  }

  Future<ProjectDelay> update(ProjectDelay delay) async {
    final response = await _apiClient.put(
      '/project-delays/${delay.id}',
      body: {
        'delayDate': delay.delayDate.toIso8601String().split('T').first,
        'category': delay.category.name,
        'title': delay.title,
        'description': delay.description,
        'timeImpactDays': delay.timeImpactDays,
        'costImpact': delay.costImpact,
        'mitigationAction': delay.mitigationAction,
        'isResolved': delay.isResolved,
      },
    );

    return ProjectDelay.fromJson(response);
  }

  Future<void> delete(String id) async {
    await _apiClient.delete('/project-delays/$id');
  }

  Future<void> syncCreate(Map<String, dynamic> json) async {
    final delay = ProjectDelay.fromJson(json);
    await create(delay);
  }
}