import 'package:csm_app/core/network/api_client.dart';

import '../models/cost_code.dart';

class CostCodeRepository {
  CostCodeRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<CostCode>> getAll() async {
    final response = await _apiClient.getList(
      '/CostCodes',
    );

    return response
        .map(
          (item) => CostCode.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<CostCode> getById(
    String costCodeId,
  ) async {
    final response = await _apiClient.get(
      '/CostCodes/$costCodeId',
    );

    return CostCode.fromJson(response);
  }

  Future<CostCode> create({
    required String code,
    required String name,
    String? description,
    String? parentCostCodeId,
  }) async {
    final response = await _apiClient.post(
      '/CostCodes',
      body: <String, dynamic>{
        'code': code,
        'name': name,
        'description': description,
        'parentCostCodeId': parentCostCodeId,
      },
    );

    return CostCode.fromJson(response);
  }

  Future<CostCode> update({
    required String costCodeId,
    required String name,
    String? description,
    String? parentCostCodeId,
  }) async {
    final response = await _apiClient.put(
      '/CostCodes/$costCodeId',
      body: <String, dynamic>{
        'name': name,
        'description': description,
        'parentCostCodeId': parentCostCodeId,
      },
    );

    return CostCode.fromJson(response);
  }

  Future<CostCode> changeActiveStatus({
    required String costCodeId,
    required bool isActive,
  }) async {
    final response = await _apiClient.put(
      '/CostCodes/$costCodeId/active-status',
      body: <String, dynamic>{
        'isActive': isActive,
      },
    );

    return CostCode.fromJson(response);
  }
}
