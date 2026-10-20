import 'package:csm_app/core/network/api_client.dart';
import '../models/compliance_summary_report.dart';

class ComplianceReportRepository {
  final ApiClient _api = ApiClient();

  Future<ComplianceSummaryReport> getSummary() async {
    final json = await _api.get('/ComplianceReports/summary');
    return ComplianceSummaryReport.fromJson(json);
  }
}