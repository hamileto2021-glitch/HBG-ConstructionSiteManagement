import 'package:csm_app/core/network/api_client.dart';

import '../models/equipment_assignment.dart';

class EquipmentAssignmentRepository {
  EquipmentAssignmentRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<EquipmentAssignment>> getAll({
    String? equipmentId,
    String? constructionSiteId,
    String? projectId,
    bool? activeOnly,
  }) async {
    final queryParameters = <String, String>{};

    if (equipmentId != null && equipmentId.trim().isNotEmpty) {
      queryParameters['equipmentId'] = equipmentId;
    }

    if (constructionSiteId != null &&
        constructionSiteId.trim().isNotEmpty) {
      queryParameters['constructionSiteId'] =
          constructionSiteId;
    }

    if (projectId != null && projectId.trim().isNotEmpty) {
      queryParameters['projectId'] = projectId;
    }

    if (activeOnly != null) {
      queryParameters['activeOnly'] = activeOnly.toString();
    }

    final response = await _apiClient.getList(
      '/EquipmentAssignments',
      queryParameters: queryParameters,
    );

    return response
        .map(
          (item) => EquipmentAssignment.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<EquipmentAssignment> getById(
    String id,
  ) async {
    final response = await _apiClient.get(
      '/EquipmentAssignments/$id',
    );

    return EquipmentAssignment.fromJson(response);
  }

  Future<EquipmentAssignment> create({
    required String equipmentId,
    required String constructionSiteId,
    String? projectId,
    required DateTime assignedAtUtc,
    double? meterReadingAtAssignment,
    String? remarks,
  }) async {
    final response = await _apiClient.post(
      '/EquipmentAssignments',
      body: <String, dynamic>{
        'equipmentId': equipmentId,
        'constructionSiteId': constructionSiteId,
        'projectId': projectId,
        'assignedAtUtc':
            assignedAtUtc.toUtc().toIso8601String(),
        'meterReadingAtAssignment':
            meterReadingAtAssignment,
        'remarks': remarks,
      },
    );

    return EquipmentAssignment.fromJson(response);
  }

  Future<EquipmentAssignment> update({
    required String id,
    required DateTime assignedAtUtc,
    DateTime? releasedAtUtc,
    double? meterReadingAtAssignment,
    double? meterReadingAtRelease,
    String? remarks,
  }) async {
    final response = await _apiClient.put(
      '/EquipmentAssignments/$id',
      body: <String, dynamic>{
        'assignedAtUtc':
            assignedAtUtc.toUtc().toIso8601String(),
        'releasedAtUtc': releasedAtUtc?.toUtc().toIso8601String(),
        'meterReadingAtAssignment':
            meterReadingAtAssignment,
        'meterReadingAtRelease':
            meterReadingAtRelease,
        'remarks': remarks,
      },
    );

    return EquipmentAssignment.fromJson(response);
  }

  Future<EquipmentAssignment> release({
    required String id,
    required DateTime releasedAtUtc,
    double? meterReadingAtRelease,
  }) async {
    final response = await _apiClient.put(
      '/EquipmentAssignments/$id/release',
      body: <String, dynamic>{
        'releasedAtUtc':
            releasedAtUtc.toUtc().toIso8601String(),
        'meterReadingAtRelease':
            meterReadingAtRelease,
      },
    );

    return EquipmentAssignment.fromJson(response);
  }
}
