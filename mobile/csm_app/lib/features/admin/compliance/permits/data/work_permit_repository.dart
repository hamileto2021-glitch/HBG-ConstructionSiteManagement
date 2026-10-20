import 'package:csm_app/core/network/api_client.dart';

import 'create_work_permit_request.dart';
import 'update_work_permit_request.dart';
import 'work_permit.dart';

class WorkPermitRepository {
  WorkPermitRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<WorkPermit>> getAll() async {
    final response = await _apiClient.getList('Permits');

    return response
        .map((e) => WorkPermit.fromJson(e))
        .toList();
  }

  Future<WorkPermit> getById(String id) async {
    final response = await _apiClient.get(
      'Permits/$id',
    );

    return WorkPermit.fromJson(response);
  }

  Future<WorkPermit> create(
      CreateWorkPermitRequest request,
      ) async {
    final response = await _apiClient.post(
      'Permits',
      body: request.toJson(),
    );

    return WorkPermit.fromJson(response);
  }

  Future<WorkPermit> update(
      String id,
      UpdateWorkPermitRequest request,
      ) async {
    final response = await _apiClient.put(
      'Permits/$id',
      body: request.toJson(),
    );

    return WorkPermit.fromJson(response);
  }
}