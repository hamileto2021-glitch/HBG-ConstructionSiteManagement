import 'package:csm_app/core/network/api_client.dart';
import '../models/compliance_dashboard.dart';

class ComplianceDashboardRepository {
  final ApiClient _api = ApiClient();

  Future<ComplianceDashboard> getDashboard() async {
    final json = await _api.get('/ComplianceDashboard');
    return ComplianceDashboard.fromJson(json);
  }
}