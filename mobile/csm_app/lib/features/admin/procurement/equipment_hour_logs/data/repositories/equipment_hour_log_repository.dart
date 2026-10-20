import 'package:csm_app/core/network/api_client.dart';

import '../models/equipment_hour_log.dart';

class EquipmentHourLogRepository {
  EquipmentHourLogRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<EquipmentHourLog>> getAll({
    String? equipmentId,
  }) async {
    final queryParameters = <String, String>{};

    if (equipmentId != null) {
      queryParameters['equipmentId'] = equipmentId;
    }

    final response = await _apiClient.getList(
      '/EquipmentHourLogs',
      queryParameters: queryParameters,
    );

    return response
        .map(
          (item) => EquipmentHourLog.fromJson(
        item as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  Future<EquipmentHourLog> create({
    required String equipmentId,
    required String siteId,
    required DateTime loggedAtUtc,
    required double previousMeterReading,
    required double currentMeterReading,
    String? operatorName,
    String? activity,
    String? remarks,
  }) async {
    final response = await _apiClient.post(
      '/EquipmentHourLogs',
      body: {
        'equipmentId': equipmentId,
        'siteId': siteId,
        'logDateUtc': loggedAtUtc.toUtc().toIso8601String(),
        'previousMeter': previousMeterReading,
        'currentMeter': currentMeterReading,
        'operatorName': operatorName,
        'activity': activity,
        'remarks': remarks,
      },
    );

    return EquipmentHourLog.fromJson(response);
  }
}