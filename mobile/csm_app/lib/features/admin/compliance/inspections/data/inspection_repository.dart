import 'package:csm_app/core/network/api_client.dart';

import 'inspection.dart';
import 'create_inspection_request.dart';
import 'update_inspection_request.dart';

class InspectionRepository {
  InspectionRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Inspection>> getAll() async {
    final response = await _apiClient.getList('Inspections');

    return response
        .map((e) => Inspection.fromJson(e))
        .toList();
  }

  Future<Inspection> getById(String id) async {
    final response = await _apiClient.get('Inspections/$id');
    return Inspection.fromJson(response);
  }

  Future<Inspection> create(
      CreateInspectionRequest request,
      ) async {
    final response = await _apiClient.post(
      'Inspections',
      body: request.toJson(),
    );

    return Inspection.fromJson(response);
  }

  Future<Inspection> update(
      String id,
      UpdateInspectionRequest request,
      ) async {
    final response = await _apiClient.put(
      'Inspections/$id',
      body: request.toJson(),
    );

    return Inspection.fromJson(response);
  }
}