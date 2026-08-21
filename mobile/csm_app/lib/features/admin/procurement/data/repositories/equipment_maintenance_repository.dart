import 'package:csm_app/core/network/api_client.dart';

import '../models/equipment_maintenance.dart';

class EquipmentMaintenanceRepository {
  EquipmentMaintenanceRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<EquipmentMaintenance>> getAll({
    String? equipmentId,
    bool? completedOnly,
  }) async {
    final queryParameters = <String, String>{};

    if (equipmentId != null &&
        equipmentId.trim().isNotEmpty) {
      queryParameters['equipmentId'] =
          equipmentId.trim();
    }

    if (completedOnly != null) {
      queryParameters['completedOnly'] =
          completedOnly.toString();
    }

    final response = await _apiClient.getList(
      '/EquipmentMaintenance',
      queryParameters: queryParameters,
    );

    return response
        .map(
          (item) => EquipmentMaintenance.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<EquipmentMaintenance> getById(
    String maintenanceId,
  ) async {
    final response = await _apiClient.get(
      '/EquipmentMaintenance/$maintenanceId',
    );

    return EquipmentMaintenance.fromJson(response);
  }

  Future<EquipmentMaintenance> create({
    required String equipmentId,
    required String maintenanceType,
    required DateTime scheduledAtUtc,
    double? meterReading,
    double? cost,
    required String currencyCode,
    String? serviceProvider,
    String? description,
    String? partsReplaced,
    DateTime? nextMaintenanceAtUtc,
    double? nextMaintenanceMeterReading,
  }) async {
    final response = await _apiClient.post(
      '/EquipmentMaintenance',
      body: <String, dynamic>{
        'equipmentId': equipmentId,
        'maintenanceType': maintenanceType,
        'scheduledAtUtc':
            scheduledAtUtc.toUtc().toIso8601String(),
        'meterReading': meterReading,
        'cost': cost,
        'currencyCode': currencyCode,
        'serviceProvider': serviceProvider,
        'description': description,
        'partsReplaced': partsReplaced,
        'nextMaintenanceAtUtc':
            nextMaintenanceAtUtc
                ?.toUtc()
                .toIso8601String(),
        'nextMaintenanceMeterReading':
            nextMaintenanceMeterReading,
      },
    );

    return EquipmentMaintenance.fromJson(response);
  }

  Future<EquipmentMaintenance> update({
    required String maintenanceId,
    required String maintenanceType,
    required DateTime scheduledAtUtc,
    DateTime? startedAtUtc,
    DateTime? completedAtUtc,
    double? meterReading,
    double? cost,
    required String currencyCode,
    String? serviceProvider,
    String? description,
    String? partsReplaced,
    DateTime? nextMaintenanceAtUtc,
    double? nextMaintenanceMeterReading,
  }) async {
    final response = await _apiClient.put(
      '/EquipmentMaintenance/$maintenanceId',
      body: <String, dynamic>{
        'maintenanceType': maintenanceType,
        'scheduledAtUtc':
            scheduledAtUtc.toUtc().toIso8601String(),
        'startedAtUtc':
            startedAtUtc?.toUtc().toIso8601String(),
        'completedAtUtc':
            completedAtUtc?.toUtc().toIso8601String(),
        'meterReading': meterReading,
        'cost': cost,
        'currencyCode': currencyCode,
        'serviceProvider': serviceProvider,
        'description': description,
        'partsReplaced': partsReplaced,
        'nextMaintenanceAtUtc':
            nextMaintenanceAtUtc
                ?.toUtc()
                .toIso8601String(),
        'nextMaintenanceMeterReading':
            nextMaintenanceMeterReading,
      },
    );

    return EquipmentMaintenance.fromJson(response);
  }
}
