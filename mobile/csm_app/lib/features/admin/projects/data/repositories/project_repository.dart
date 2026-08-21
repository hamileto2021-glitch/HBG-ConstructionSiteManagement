import '../../../../../core/network/api_client.dart';
import '../models/project.dart';

class ProjectRepository {
  ProjectRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Project>> getAll({
    String? constructionSiteId,
  }) async {
    final query = <String, String>{};

    if (constructionSiteId != null &&
        constructionSiteId.isNotEmpty) {
      query['constructionSiteId'] = constructionSiteId;
    }

    final response = await _apiClient.getList(
      '/Projects',
      queryParameters: query,
    );

    final items = response;

    return items
        .map(
          (item) => Project.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<Project> getById(String projectId) async {
    final response = await _apiClient.get(
      '/Projects/$projectId',
    );

    return Project.fromJson(response);
  }

  Future<Project> create({
    required String constructionSiteId,
    required String projectCode,
    required String name,
    String? description,
    DateTime? plannedStartDate,
    DateTime? plannedEndDate,
    required double contractValue,
  }) async {
    final response = await _apiClient.post(
      '/Projects',
      body: <String, dynamic>{
        'constructionSiteId': constructionSiteId,
        'projectCode': projectCode,
        'name': name,
        'description': description,
        'plannedStartDate':
            plannedStartDate?.toIso8601String().split('T').first,
        'plannedEndDate':
            plannedEndDate?.toIso8601String().split('T').first,
        'contractValue': contractValue,
      },
    );

    return Project.fromJson(response);
  }

  Future<Project> update({
    required String projectId,
    required String name,
    String? description,
    DateTime? plannedStartDate,
    DateTime? plannedEndDate,
    required double contractValue,
  }) async {
    final response = await _apiClient.put(
      '/Projects/$projectId',
      body: <String, dynamic>{
        'name': name,
        'description': description,
        'plannedStartDate':
            plannedStartDate?.toIso8601String().split('T').first,
        'plannedEndDate':
            plannedEndDate?.toIso8601String().split('T').first,
        'contractValue': contractValue,
      },
    );

    return Project.fromJson(response);
  }

  Future<Project> changeStatus({
    required String projectId,
    required ProjectStatus status,
  }) async {
    final response = await _apiClient.put(
      '/Projects/$projectId/status',
      body: <String, dynamic>{
        'status': status.name,
      },
    );

    return Project.fromJson(response);
  }
}







