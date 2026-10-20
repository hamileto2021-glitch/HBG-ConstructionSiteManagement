import 'package:csm_app/core/network/api_client.dart';

import 'create_non_conformance_report_request.dart';
import 'non_conformance_report.dart';
import 'update_non_conformance_report_request.dart';

class NonConformanceReportRepository {
  NonConformanceReportRepository(this._api);

  final ApiClient _api;

  Future<List<NonConformanceReport>> getAll() async {
    final response = await _api.getList(
      'NonConformanceReport',
    );

    return response
        .map(
          (e) => NonConformanceReport.fromJson(e),
    )
        .toList();
  }

  Future<NonConformanceReport> getById(
      String id,
      ) async {
    final response = await _api.get(
      'NonConformanceReport/$id',
    );

    return NonConformanceReport.fromJson(response);
  }

  Future<NonConformanceReport> create(
      CreateNonConformanceReportRequest request,
      ) async {
    final response = await _api.post(
      'NonConformanceReport',
      body: request.toJson(),
    );

    return NonConformanceReport.fromJson(response);
  }

  Future<NonConformanceReport> update(
      String id,
      UpdateNonConformanceReportRequest request,
      ) async {
    final response = await _api.put(
      'NonConformanceReport/$id',
      body: request.toJson(),
    );

    return NonConformanceReport.fromJson(response);
  }
}