import 'package:csm_app/core/network/api_client.dart';

import '../models/equipment_downtime.dart';

class EquipmentDowntimeRepository {
  EquipmentDowntimeRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<EquipmentDowntime>> getAll({
    String? equipmentId,
    String? constructionSiteId,
    bool? openOnly,
  }) async {
    final queryParameters = <String, String>{};

    if (equipmentId != null &&
        equipmentId.trim().isNotEmpty) {
      queryParameters['equipmentId'] = equipmentId;
    }

    if (constructionSiteId != null &&
        constructionSiteId.trim().isNotEmpty) {
      queryParameters['constructionSiteId'] =
          constructionSiteId;
    }

    if (openOnly != null) {
      queryParameters['openOnly'] =
          openOnly.toString();
    }

    final response = await _apiClient.getList(
      '/EquipmentDowntime',
      queryParameters: queryParameters,
    );

    return response
        .map(
          (item) => EquipmentDowntime.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<EquipmentDowntime> getById(
    String id,
  ) async {
    final response = await _apiClient.get(
      '/EquipmentDowntime/$id',
    );

    return EquipmentDowntime.fromJson(response);
  }

  Future<EquipmentDowntime> create({
    required String equipmentId,
    String? constructionSiteId,
    required DateTime startedAtUtc,
    required String downtimeNumber,
    required String reason,
    String? resolution,
  }) async {
    final response = await _apiClient.post(
      '/EquipmentDowntime',
      body: <String, dynamic>{
        'equipmentId': equipmentId,
        'constructionSiteId': constructionSiteId,
        'startedAtUtc':
            startedAtUtc.toUtc().toIso8601String(),
        'endedAtUtc': null,
        'downtimeNumber': downtimeNumber,
        'reason': reason,
        'resolution': resolution,
      },
    );

    return EquipmentDowntime.fromJson(response);
  }

  Future<EquipmentDowntime> close({
    required String id,
    required DateTime endedAtUtc,
    String? resolution,
  }) async {
    final response = await _apiClient.put(
      '/EquipmentDowntime/$id/close',
      body: <String, dynamic>{
        'endedAtUtc':
            endedAtUtc.toUtc().toIso8601String(),
        'resolution': resolution,
      },
    );

    return EquipmentDowntime.fromJson(response);
  }
}
