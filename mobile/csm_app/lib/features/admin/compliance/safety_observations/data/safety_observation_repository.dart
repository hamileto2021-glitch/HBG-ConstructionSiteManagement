import 'package:csm_app/core/network/api_client.dart';

import 'safety_observation.dart';
import 'create_safety_observation_request.dart';
import 'update_safety_observation_request.dart';

class SafetyObservationRepository {
  SafetyObservationRepository(this._api);

  final ApiClient _api;

  Future<List<SafetyObservation>> getAll() async {
    final response = await _api.getList(
      'SafetyObservation',
    );

    return response
        .map(
          (e) => SafetyObservation.fromJson(
        e,
      ),
    )
        .toList();
  }

  Future<SafetyObservation> getById(
      String id,
      ) async {
    final response = await _api.get(
      'SafetyObservation/$id',
    );

    return SafetyObservation.fromJson(
      response,
    );
  }

  Future<SafetyObservation> create(
      CreateSafetyObservationRequest request,
      ) async {
    final response = await _api.post(
      'SafetyObservation',
      body: request.toJson(),
    );

    return SafetyObservation.fromJson(
      response,
    );
  }

  Future<SafetyObservation> update(
      String id,
      UpdateSafetyObservationRequest request,
      ) async {
    final response = await _api.put(
      'SafetyObservation/$id',
      body: request.toJson(),
    );

    return SafetyObservation.fromJson(
      response,
    );
  }
}