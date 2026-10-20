import 'package:csm_app/core/network/api_client.dart';

import '../models/stock_issue.dart';

class StockIssueRepository {
  StockIssueRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<StockIssue>> getAll() async {
    final response = await _apiClient.getList('/StockIssues');

    return response
        .map(
          (e) => StockIssue.fromJson(
        e as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  Future<StockIssue> getById(String id) async {
    final response = await _apiClient.get('/StockIssues/$id');

    return StockIssue.fromJson(response);
  }

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