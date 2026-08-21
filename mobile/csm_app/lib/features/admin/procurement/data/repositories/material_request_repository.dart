import 'package:csm_app/core/network/api_client.dart';

import '../models/material_request.dart';

class MaterialRequestRepository {
  MaterialRequestRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<MaterialRequest>> getAll({
    String? constructionSiteId,
    String? projectId,
    MaterialRequestStatus? status,
  }) async {
    final queryParameters = <String, String>{};

    if (constructionSiteId != null) {
      queryParameters['constructionSiteId'] =
          constructionSiteId;
    }

    if (projectId != null) {
      queryParameters['projectId'] = projectId;
    }

    if (status != null) {
      queryParameters['status'] =
          _statusValue(status).toString();
    }

    final response = await _apiClient.getList(
      '/MaterialRequests',
      queryParameters: queryParameters,
    );

    return response
        .map(
          (item) => MaterialRequest.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<MaterialRequest> getById(
    String materialRequestId,
  ) async {
    final response = await _apiClient.get(
      '/MaterialRequests/$materialRequestId',
    );

    return MaterialRequest.fromJson(response);
  }

  Future<MaterialRequest> create({
    required String constructionSiteId,
    String? projectId,
    required String requestNumber,
    required DateTime requestDate,
    DateTime? requiredByDate,
    String? purpose,
    required Priority priority,
    required List<MaterialRequestLineInput> lines,
  }) async {
    final response = await _apiClient.post(
      '/MaterialRequests',
      body: <String, dynamic>{
        'constructionSiteId': constructionSiteId,
        'projectId': projectId,
        'requestNumber': requestNumber,
        'requestDate': _formatDate(requestDate),
        'requiredByDate': requiredByDate == null
            ? null
            : _formatDate(requiredByDate),
        'purpose': purpose,
        'priority': _priorityValue(priority),
        'lines': lines
            .map((line) => line.toJson())
            .toList(),
      },
    );

    return MaterialRequest.fromJson(response);
  }

  Future<MaterialRequest> update({
    required String materialRequestId,
    required String constructionSiteId,
    String? projectId,
    required String requestNumber,
    required DateTime requestDate,
    DateTime? requiredByDate,
    String? purpose,
    required Priority priority,
    required List<MaterialRequestLineInput> lines,
  }) async {
    final response = await _apiClient.put(
      '/MaterialRequests/$materialRequestId',
      body: <String, dynamic>{
        'constructionSiteId': constructionSiteId,
        'projectId': projectId,
        'requestNumber': requestNumber,
        'requestDate': _formatDate(requestDate),
        'requiredByDate': requiredByDate == null
            ? null
            : _formatDate(requiredByDate),
        'purpose': purpose,
        'priority': _priorityValue(priority),
        'lines': lines
            .map((line) => line.toJson())
            .toList(),
      },
    );

    return MaterialRequest.fromJson(response);
  }

  Future<MaterialRequest> submit(
    String materialRequestId,
  ) async {
    final response = await _apiClient.put(
      '/MaterialRequests/$materialRequestId/submit',
    );

    return MaterialRequest.fromJson(response);
  }

  Future<MaterialRequest> approve({
    required String materialRequestId,
    String? remarks,
    required List<MaterialRequestApprovalLine> lines,
  }) async {
    final response = await _apiClient.put(
      '/MaterialRequests/$materialRequestId/approve',
      body: <String, dynamic>{
        'remarks': remarks,
        'lines': lines
            .map((line) => line.toJson())
            .toList(),
      },
    );

    return MaterialRequest.fromJson(response);
  }

  Future<MaterialRequest> reject({
    required String materialRequestId,
    String? remarks,
  }) async {
    final response = await _apiClient.put(
      '/MaterialRequests/$materialRequestId/reject',
      body: <String, dynamic>{
        'remarks': remarks,
      },
    );

    return MaterialRequest.fromJson(response);
  }

  Future<MaterialRequest> cancel({
    required String materialRequestId,
    String? remarks,
  }) async {
    final response = await _apiClient.put(
      '/MaterialRequests/$materialRequestId/cancel',
      body: <String, dynamic>{
        'remarks': remarks,
      },
    );

    return MaterialRequest.fromJson(response);
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();

    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  int _priorityValue(Priority priority) {
    switch (priority) {
      case Priority.low:
        return 1;
      case Priority.normal:
        return 2;
      case Priority.high:
        return 3;
      case Priority.critical:
        return 4;
    }
  }

  int _statusValue(MaterialRequestStatus status) {
    switch (status) {
      case MaterialRequestStatus.draft:
        return 1;
      case MaterialRequestStatus.submitted:
        return 2;
      case MaterialRequestStatus.approved:
        return 3;
      case MaterialRequestStatus.partiallyApproved:
        return 4;
      case MaterialRequestStatus.rejected:
        return 5;
      case MaterialRequestStatus.ordered:
        return 6;
      case MaterialRequestStatus.partiallyDelivered:
        return 7;
      case MaterialRequestStatus.delivered:
        return 8;
      case MaterialRequestStatus.cancelled:
        return 9;
    }
  }
}
