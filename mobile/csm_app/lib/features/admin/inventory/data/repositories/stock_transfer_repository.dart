import 'package:csm_app/core/network/api_client.dart';

import '../models/stock_transfer.dart';

class StockTransferRepository {
  StockTransferRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<StockTransfer> create(
      CreateStockTransferRequest request,
      ) async {
    final response = await _apiClient.post(
      '/StockTransfers',
      body: request.toJson(),
    );

    return StockTransfer.fromJson(response);
  }
}