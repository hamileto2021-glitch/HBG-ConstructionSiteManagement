import '../../../../../core/network/api_client.dart';
import '../models/project_milestone.dart';

class ProjectMilestoneRepository {
  ProjectMilestoneRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<ProjectMilestone>> getAll() async {
    final response = await _apiClient.getList(
      '/project-milestones',
    );

    return response
        .map((e) => ProjectMilestone.fromJson(e))
        .toList();
  }

  Future<ProjectMilestone> create({
    required String projectId,
    required String name,
    String? description,
    required DateTime plannedDate,
    DateTime? actualDate,
    required MilestoneStatus status,
    required double progressPercentage,
    String? notes,
  }) async {
    final response = await _apiClient.post(
      '/project-milestones',
      body: {
        'projectId': projectId,
        'name': name,
        'description': description,
        'plannedDate':
        plannedDate.toIso8601String().split('T').first,
        'actualDate': actualDate
            ?.toIso8601String()
            .split('T')
            .first,
        'status': status.name,
        'progressPercentage': progressPercentage,
        'notes': notes,
      },
    );

    return ProjectMilestone.fromJson(response);
  }

  Future<ProjectMilestone> update({
    required String milestoneId,
    required String name,
    String? description,
    required DateTime plannedDate,
    DateTime? actualDate,
    required MilestoneStatus status,
    required double progressPercentage,
    String? notes,
  }) async {
    final response = await _apiClient.put(
      '/project-milestones/$milestoneId',
      body: {
        'name': name,
        'description': description,
        'plannedDate': plannedDate.toIso8601String().split('T').first,
        'actualDate': actualDate?.toIso8601String().split('T').first,
        'status': status.name,
        'progressPercentage': progressPercentage,
        'notes': notes,
      },
    );

    return ProjectMilestone.fromJson(response);
  }
  Future<ProjectMilestone> getById(String id) async {
    final response =
    await _apiClient.get('/project-milestones/$id');

    return ProjectMilestone.fromJson(response);
  }
}