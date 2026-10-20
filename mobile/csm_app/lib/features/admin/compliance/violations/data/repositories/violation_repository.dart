import 'package:csm_app/core/network/api_client.dart';
import '../models/violation.dart';

class ViolationRepository {
  final ApiClient _api = ApiClient();

  Future<List<Violation>> getAll() async {
    final response = await _api.getList('/ComplianceViolations');

    return response
        .map((e) => Violation.fromJson(e))
        .toList();
  }
}