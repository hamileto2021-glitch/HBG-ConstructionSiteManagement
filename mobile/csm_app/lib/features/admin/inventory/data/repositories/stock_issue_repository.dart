import 'package:csm_app/core/network/api_client.dart';

import '../models/stock_issue.dart';

class StockIssueRepository {
  StockIssueRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<StockIssue> create(
      CreateStockIssueRequest request,
      ) async {
    final response = await _apiClient.post(
      '/StockIssues',
      body: request.toJson(),
    );

    return StockIssue.fromJson(response);
  }
}