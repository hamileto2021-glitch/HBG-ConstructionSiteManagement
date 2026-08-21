import '../../../../../core/network/api_client.dart';
import '../models/site_assignment/site_assignment.dart';

class SiteAssignmentRepository {
  SiteAssignmentRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<SiteAssignment>> getAll({
    String? employeeId,
    String? constructionSiteId,
  }) async {
    final queryParameters = <String, String>{};

    if (employeeId != null) {
      queryParameters['employeeId'] = employeeId;
    }

    if (constructionSiteId != null) {
      queryParameters['constructionSiteId'] =
          constructionSiteId;
    }

    final response = await _apiClient.getList(
      '/SiteAssignments',
      queryParameters: queryParameters,
    );

    return response
        .map(
          (item) => SiteAssignment.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<SiteAssignment> getById(
    String assignmentId,
  ) async {
    final response = await _apiClient.get(
      '/SiteAssignments/$assignmentId',
    );

    return SiteAssignment.fromJson(response);
  }

  Future<SiteAssignment> create({
    required String employeeId,
    required String constructionSiteId,
    required DateTime startDate,
    DateTime? endDate,
    String? roleAtSite,
    required bool isPrimaryAssignment,
    String? remarks,
  }) async {
    final response = await _apiClient.post(
      '/SiteAssignments',
      body: <String, dynamic>{
        'employeeId': employeeId,
        'constructionSiteId': constructionSiteId,
        'startDate': _formatDate(startDate),
        'endDate': endDate == null
            ? null
            : _formatDate(endDate),
        'roleAtSite': roleAtSite,
        'isPrimaryAssignment': isPrimaryAssignment,
        'remarks': remarks,
      },
    );

    return SiteAssignment.fromJson(response);
  }

  Future<SiteAssignment> update({
    required String assignmentId,
    required DateTime startDate,
    DateTime? endDate,
    String? roleAtSite,
    required bool isPrimaryAssignment,
    String? remarks,
  }) async {
    final response = await _apiClient.put(
      '/SiteAssignments/$assignmentId',
      body: <String, dynamic>{
        'startDate': _formatDate(startDate),
        'endDate': endDate == null
            ? null
            : _formatDate(endDate),
        'roleAtSite': roleAtSite,
        'isPrimaryAssignment': isPrimaryAssignment,
        'remarks': remarks,
      },
    );

    return SiteAssignment.fromJson(response);
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();

    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
}
