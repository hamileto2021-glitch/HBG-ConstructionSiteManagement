import 'package:csm_app/core/network/api_client.dart';

import '../models/dashboard_stats.dart';
import '../models/dashboard_analytics.dart';



class DashboardRepository {
  DashboardRepository({
    ApiClient? apiClient,
  }) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<DashboardStats> getStatistics() async {
    final json = await _api.get('/Dashboard/statistics');
    return DashboardStats.fromJson(json);
  }

  Future<DashboardAnalytics> getAnalytics() async {
    final json = await _api.get('/Dashboard/analytics');

    return DashboardAnalytics.fromJson(json);
  }
}