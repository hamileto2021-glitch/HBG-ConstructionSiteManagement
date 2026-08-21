import 'package:csm_app/core/network/api_client.dart';

import '../models/daily_material_usage.dart';

class DailyMaterialUsageRepository {
  DailyMaterialUsageRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<DailyMaterialUsage> create(
    CreateDailyMaterialUsageRequest request,
  ) async {
    final response = await _apiClient.post(
      '/DailyMaterialUsages',
      body: request.toJson(),
    );

    return DailyMaterialUsage.fromJson(response);
  }
}
