import '../../../../../core/network/api_client.dart';
import '../models/milestones/milestone.dart';

class MilestoneRepository {
  MilestoneRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Milestone>> getAll({
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
      '/Milestones',
      queryParameters: query,
    );

    return response
        .map(
          (item) => Milestone.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<Milestone> getById(String milestoneId) async {
    final response = await _apiClient.get(
      '/Milestones/$milestoneId',
    );

    return Milestone.fromJson(response);
  }

  Future<Milestone> create({
    required String projectId,
    String? projectPhaseId,
    required String name,
    String? description,
    required DateTime plannedDate,
  }) async {
    final response = await _apiClient.post(
      '/Milestones',
      body: <String, dynamic>{
        'projectId': projectId,
        'projectPhaseId': projectPhaseId,
        'name': name,
        'description': description,
        'plannedDate':
            plannedDate.toIso8601String().split('T').first,
      },
    );

    return Milestone.fromJson(response);
  }

  Future<Milestone> update({
    required String milestoneId,
    String? projectPhaseId,
    required String name,
    String? description,
    required DateTime plannedDate,
  }) async {
    final response = await _apiClient.put(
      '/Milestones/$milestoneId',
      body: <String, dynamic>{
        'projectPhaseId': projectPhaseId,
        'name': name,
        'description': description,
        'plannedDate':
            plannedDate.toIso8601String().split('T').first,
      },
    );

    return Milestone.fromJson(response);
  }

  Future<Milestone> complete(String milestoneId) async {
    final response = await _apiClient.put(
      '/Milestones/$milestoneId/complete',
    );

    return Milestone.fromJson(response);
  }

  Future<Milestone> reopen(String milestoneId) async {
    final response = await _apiClient.put(
      '/Milestones/$milestoneId/reopen',
    );

    return Milestone.fromJson(response);
  }
}
