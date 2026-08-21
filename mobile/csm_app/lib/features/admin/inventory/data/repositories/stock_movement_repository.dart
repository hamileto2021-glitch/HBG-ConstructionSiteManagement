import 'package:csm_app/core/network/api_client.dart';

import '../models/stock_movement.dart';

class StockMovementRepository {
  StockMovementRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<StockMovement>> getAll({
    String? constructionSiteId,
    String? materialId,
    StockMovementType? movementType,
    DateTime? fromUtc,
    DateTime? toUtc,
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

    if (movementType != null) {
      queryParameters['movementType'] =
          _movementTypeValue(movementType).toString();
    }

    if (fromUtc != null) {
      queryParameters['fromUtc'] =
          fromUtc.toUtc().toIso8601String();
    }

    if (toUtc != null) {
      queryParameters['toUtc'] =
          toUtc.toUtc().toIso8601String();
    }

    final response = await _apiClient.getList(
      '/StockMovements',
      queryParameters: queryParameters,
    );

    return response
        .map(
          (item) => StockMovement.fromJson(
        item as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  Future<StockMovement> getById(
      String stockMovementId,
      ) async {
    final response = await _apiClient.get(
      '/StockMovements/$stockMovementId',
    );

    return StockMovement.fromJson(response);
  }

  int _movementTypeValue(
      StockMovementType type,
      ) {
    switch (type) {
      case StockMovementType.openingBalance:
        return 1;
      case StockMovementType.goodsReceipt:
        return 2;
      case StockMovementType.issue:
        return 3;
      case StockMovementType.returnMovement:
        return 4;
      case StockMovementType.transferIn:
        return 5;
      case StockMovementType.transferOut:
        return 6;
      case StockMovementType.adjustmentIncrease:
        return 7;
      case StockMovementType.adjustmentDecrease:
        return 8;
    }
  }
}