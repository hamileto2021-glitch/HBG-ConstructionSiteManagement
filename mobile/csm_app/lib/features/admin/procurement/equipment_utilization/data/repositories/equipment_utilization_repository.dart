import 'package:csm_app/core/network/api_client.dart';

import '../models/equipment_utilization.dart';

class EquipmentUtilizationRepository {
  EquipmentUtilizationRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<EquipmentUtilization>> getAll() async {
    final response = await _apiClient.getList(
      '/EquipmentUtilization',
    );

    return response
        .map(
          (item) => EquipmentUtilization.fromJson(
        item as Map<String, dynamic>,
      ),
    )
        .toList();
  }
}