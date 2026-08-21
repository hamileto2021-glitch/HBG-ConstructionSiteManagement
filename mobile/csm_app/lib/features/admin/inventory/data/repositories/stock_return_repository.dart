import 'package:csm_app/core/network/api_client.dart';

import '../models/stock_return.dart';

class StockReturnRepository {
  StockReturnRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<StockReturn> create(
      CreateStockReturnRequest request,
      ) async {
    final response = await _apiClient.post(
      '/StockReturns',
      body: request.toJson(),
    );

    return StockReturn.fromJson(response);
  }
}