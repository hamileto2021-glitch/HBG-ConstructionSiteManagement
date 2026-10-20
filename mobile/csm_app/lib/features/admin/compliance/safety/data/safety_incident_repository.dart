import 'package:csm_app/core/network/api_client.dart';

import 'safety_incident.dart';
import 'create_safety_incident_request.dart';
import 'update_safety_incident_request.dart';

class SafetyIncidentRepository {
  SafetyIncidentRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<SafetyIncident>> getAll() async {
    final data =
    await _apiClient.getList('SafetyIncidents');

    return data
        .map(
          (e) => SafetyIncident.fromJson(
        e as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  Future<SafetyIncident> getById(
      String id,
      ) async {
    final data =
    await _apiClient.get(
      'SafetyIncidents/$id',
    );

    return SafetyIncident.fromJson(data);
  }

  Future<SafetyIncident> create(
      CreateSafetyIncidentRequest request,
      ) async {
    final data =
    await _apiClient.post(
      'SafetyIncidents',
      body: request.toJson(),
    );

    return SafetyIncident.fromJson(data);
  }

  Future<SafetyIncident> update(
      String id,
      UpdateSafetyIncidentRequest request,
      ) async {
    final data =
    await _apiClient.put(
      'SafetyIncidents/$id',
      body: request.toJson(),
    );

    return SafetyIncident.fromJson(data);
  }
}