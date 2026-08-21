import '../../../../../core/network/api_client.dart';
import '../models/phases/project_phase.dart';

class ProjectPhaseRepository {
  ProjectPhaseRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<ProjectPhase>> getAll({
    required String projectId,
  }) async {
    final response = await _apiClient.getList(
      '/ProjectPhases',
      queryParameters: <String, String>{
        'projectId': projectId,
      },
    );

    return response
        .map(
          (item) => ProjectPhase.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<ProjectPhase> getById(String phaseId) async {
    final response = await _apiClient.get(
      '/ProjectPhases/$phaseId',
    );

    return ProjectPhase.fromJson(response);
  }

  Future<ProjectPhase> create({
    required String projectId,
    required String name,
    String? description,
    required int sequence,
    DateTime? plannedStartDate,
    DateTime? plannedEndDate,
  }) async {
    final response = await _apiClient.post(
      '/ProjectPhases',
      body: <String, dynamic>{
        'projectId': projectId,
        'name': name,
        'description': description,
        'sequence': sequence,
        'plannedStartDate':
            plannedStartDate?.toIso8601String().split('T').first,
        'plannedEndDate':
            plannedEndDate?.toIso8601String().split('T').first,
      },
    );

    return ProjectPhase.fromJson(response);
  }

  Future<ProjectPhase> update({
    required String phaseId,
    required String name,
    String? description,
    required int sequence,
    DateTime? plannedStartDate,
    DateTime? plannedEndDate,
  }) async {
    final response = await _apiClient.put(
      '/ProjectPhases/$phaseId',
      body: <String, dynamic>{
        'name': name,
        'description': description,
        'sequence': sequence,
        'plannedStartDate':
            plannedStartDate?.toIso8601String().split('T').first,
        'plannedEndDate':
            plannedEndDate?.toIso8601String().split('T').first,
      },
    );

    return ProjectPhase.fromJson(response);
  }

  Future<ProjectPhase> changeStatus({
    required String phaseId,
    required ProjectPhaseStatus status,
  }) async {
    final response = await _apiClient.put(
      '/ProjectPhases/$phaseId/status',
      body: <String, dynamic>{
        'status': status.name,
      },
    );

    return ProjectPhase.fromJson(response);
  }
}
