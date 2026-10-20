import '../../../../../core/network/api_client.dart';
import '../models/project_progress.dart';
import '../models/project_progress_dashboard.dart';

class ProjectProgressRepository {
  ProjectProgressRepository(this._api);

  final ApiClient _api;

  Future<ProjectProgress> getByProject(String projectId) async {
    final response = await _api.get(
      '/projects/$projectId/progress',
    );

    return ProjectProgress.fromJson(response);
  }

  Future<ProjectProgressDashboard> getDashboard(
      String projectId,
      ) async {
    final response = await _api.get(
      '/projects/$projectId/progress',
    );

    return ProjectProgressDashboard.fromJson(response);
  }
}