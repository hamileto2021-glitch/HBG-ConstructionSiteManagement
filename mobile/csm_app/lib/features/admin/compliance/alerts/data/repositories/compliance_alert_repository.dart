import 'package:csm_app/core/network/api_client.dart';
import '../models/compliance_alert.dart';

class ComplianceAlertRepository {
  final ApiClient _api = ApiClient();

  Future<List<ComplianceAlert>> getAll() async {
    final response = await _api.getList('/ComplianceAlerts');

    return response
        .map((e) => ComplianceAlert.fromJson(e))
        .toList();
  }
}