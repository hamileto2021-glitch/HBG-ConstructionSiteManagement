import 'package:csm_app/core/network/api_client.dart';

import '../models/stock_return.dart';

class StockReturnRepository {
  StockReturnRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<StockReturn>> getAll() async {
    final response = await _apiClient.getList('/StockReturns');

    return response
        .map(
          (e) => StockReturn.fromJson(
        e as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  Future<StockReturn> getById(String id) async {
    final response = await _apiClient.get('/StockReturns/$id');

    return StockReturn.fromJson(response);
  }

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