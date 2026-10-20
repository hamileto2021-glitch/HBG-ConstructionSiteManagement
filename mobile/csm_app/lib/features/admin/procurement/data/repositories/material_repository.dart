import 'package:csm_app/core/network/api_client.dart';

import '../models/material.dart';
import '../models/material_lookup.dart';

class MaterialRepository {
  MaterialRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Material>> getAll({
    bool? isActive,
    String? category,
  }) async {
    final queryParameters = <String, String>{};

    if (isActive != null) {
      queryParameters['isActive'] = isActive.toString();
    }

    if (category != null && category.trim().isNotEmpty) {
      queryParameters['category'] = category.trim();
    }

    final response = await _apiClient.getList(
      '/Materials',
      queryParameters: queryParameters,
    );

    return response
        .map(
          (item) => Material.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }
  Future<List<MaterialLookup>> getCategories() async {
    final response = await _apiClient.getList(
      '/Materials/lookup/categories',
    );

    return response
        .map(
          (item) => MaterialLookup.fromJson(
        item as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  Future<List<MaterialLookup>> getUnits() async {
    final response = await _apiClient.getList(
      '/Materials/lookup/units',
    );

    return response
        .map(
          (item) => MaterialLookup.fromJson(
        item as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  Future<List<MaterialLookup>> getMaterialTypes() async {
    final response = await _apiClient.getList(
      '/Materials/lookup/material-types',
    );

    return response
        .map(
          (item) => MaterialLookup.fromJson(
        item as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  Future<Material> getById(String materialId) async {
    final response = await _apiClient.get(
      '/Materials/$materialId',
    );

    return Material.fromJson(response);
  }

  Future<Material> create({
    required String materialCode,
    required String name,
    String? description,
    required String category,
    required String unitOfMeasure,
    required MaterialType materialType,
    String? defaultCostCodeId,
    double? standardUnitCost,
    required bool isActive,
  }) async {
    final response = await _apiClient.post(
      '/Materials',
      body: <String, dynamic>{
        'materialCode': materialCode,
        'name': name,
        'description': description,
        'category': category,
        'unitOfMeasure': unitOfMeasure,
        'materialType': _materialTypeToValue(materialType),
        'defaultCostCodeId': defaultCostCodeId,
        'standardUnitCost': standardUnitCost,
        'isActive': isActive,
      },
    );

    return Material.fromJson(response);
  }

  Future<Material> update({
    required String materialId,
    required String materialCode,
    required String name,
    String? description,
    required String category,
    required String unitOfMeasure,
    required MaterialType materialType,
    String? defaultCostCodeId,
    double? standardUnitCost,
    required bool isActive,
  }) async {
    final response = await _apiClient.put(
      '/Materials/$materialId',
      body: <String, dynamic>{
        'materialCode': materialCode,
        'name': name,
        'description': description,
        'category': category,
        'unitOfMeasure': unitOfMeasure,
        'materialType': _materialTypeToValue(materialType),
        'defaultCostCodeId': defaultCostCodeId,
        'standardUnitCost': standardUnitCost,
        'isActive': isActive,
      },
    );

    return Material.fromJson(response);
  }

  int _materialTypeToValue(MaterialType type) {
    switch (type) {
      case MaterialType.bulk:
        return 1;
      case MaterialType.rebarLinear:
        return 2;
    }
  }
}
