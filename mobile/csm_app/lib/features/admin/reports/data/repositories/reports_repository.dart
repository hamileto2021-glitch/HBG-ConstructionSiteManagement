import '../../../../../core/network/api_client.dart';
import '../models/executive_dashboard.dart';
import '../models/financial_summary.dart';

class ReportsRepository {
  ReportsRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<ExecutiveDashboard> getExecutiveDashboard() async {
    final response =
    await _apiClient.get('/Reports/executive-dashboard');

    return ExecutiveDashboard.fromJson(response);
  }

  Future<FinancialSummary> getFinancialSummary() async {
    final response =
    await _apiClient.get('/Reports/financial-summary');

    return FinancialSummary.fromJson(response);
  }
}