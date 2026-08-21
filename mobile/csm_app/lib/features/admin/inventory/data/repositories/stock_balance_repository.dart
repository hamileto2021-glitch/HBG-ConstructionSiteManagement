import 'package:csm_app/core/network/api_client.dart';

import '../models/stock_balance.dart';

class StockBalanceRepository {
  StockBalanceRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<StockBalance>> getAll({
    String? constructionSiteId,
    String? materialId,
  }) async {
    final queryParameters = <String, String>{};

    if (constructionSiteId != null &&
        constructionSiteId.trim().isNotEmpty) {
      queryParameters['constructionSiteId'] =
          constructionSiteId.trim();
    }

    if (materialId != null &&
        materialId.trim().isNotEmpty) {
      queryParameters['materialId'] =
          materialId.trim();
    }

    final response = await _apiClient.getList(
      '/StockBalances',
      queryParameters: queryParameters,
    );

    return response
        .map(
          (item) => StockBalance.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<StockBalance> getById(
    String stockItemId,
  ) async {
    final response = await _apiClient.get(
      '/StockBalances/$stockItemId',
    );

    return StockBalance.fromJson(response);
  }
}
