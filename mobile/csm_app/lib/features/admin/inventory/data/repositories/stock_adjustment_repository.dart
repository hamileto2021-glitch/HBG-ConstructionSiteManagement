import 'package:csm_app/core/network/api_client.dart';

import '../models/stock_adjustment.dart';

class StockAdjustmentRepository {
  StockAdjustmentRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<StockAdjustment> create(
      CreateStockAdjustmentRequest request,
      ) async {
    final response = await _apiClient.post(
      '/StockAdjustments',
      body: request.toJson(),
    );

    return StockAdjustment.fromJson(response);
  }
}