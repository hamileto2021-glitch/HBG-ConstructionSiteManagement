import 'package:csm_app/core/network/api_client.dart';

import 'create_quality_checklist_request.dart';
import 'quality_checklist.dart';
import 'update_quality_checklist_request.dart';



class QualityChecklistRepository {
  QualityChecklistRepository(this._api);

  final ApiClient _api;

  Future<List<QualityChecklist>> getAll() async {
    final response = await _api.getList('/qualitychecklist');

    return response
        .map((item) => QualityChecklist.fromJson(
      Map<String, dynamic>.from(item as Map),
    ))
        .toList();
  }

  Future<QualityChecklist> getById(String id) async {
    final dynamic response = await _api.get('/qualitychecklist/$id');

    return QualityChecklist.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<void> create(CreateQualityChecklistRequest request) async {
    await _api.post(
      '/qualitychecklist',
      body: request.toJson(),
    );
  }

  Future<void> update(
      String id,
      UpdateQualityChecklistRequest request,
      ) async {
    final body = request.toJson();

    await _api.put(
      '/qualitychecklist/$id',
      body: body,
    );
  }

  Future<void> delete(String id) async {
    await _api.delete('/qualitychecklist/$id');
  }
}