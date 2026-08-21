import 'package:csm_app/core/network/api_client.dart';

import '../models/goods_receipt.dart';

class GoodsReceiptRepository {
  GoodsReceiptRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<GoodsReceipt>> getAll({
    String? constructionSiteId,
    String? purchaseOrderId,
  }) async {
    final queryParameters = <String, String>{};

    if (constructionSiteId != null &&
        constructionSiteId.trim().isNotEmpty) {
      queryParameters['constructionSiteId'] =
          constructionSiteId.trim();
    }

    if (purchaseOrderId != null &&
        purchaseOrderId.trim().isNotEmpty) {
      queryParameters['purchaseOrderId'] =
          purchaseOrderId.trim();
    }

    final response = await _apiClient.getList(
      '/GoodsReceipts',
      queryParameters: queryParameters,
    );

    return response
        .map(
          (item) => GoodsReceipt.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<GoodsReceipt> getById(
    String goodsReceiptId,
  ) async {
    final response = await _apiClient.get(
      '/GoodsReceipts/$goodsReceiptId',
    );

    return GoodsReceipt.fromJson(response);
  }

  Future<GoodsReceipt> create({
    required String purchaseOrderId,
    required String constructionSiteId,
    required String receiptNumber,
    required DateTime receivedAtUtc,
    String? deliveryNoteNumber,
    String? vehiclePlateNumber,
    String? remarks,
    required List<GoodsReceiptLineInput> lines,
  }) async {
    final response = await _apiClient.post(
      '/GoodsReceipts',
      body: <String, dynamic>{
        'purchaseOrderId': purchaseOrderId,
        'constructionSiteId': constructionSiteId,
        'receiptNumber': receiptNumber,
        'receivedAtUtc': receivedAtUtc.toUtc().toIso8601String(),
        'deliveryNoteNumber': deliveryNoteNumber,
        'vehiclePlateNumber': vehiclePlateNumber,
        'remarks': remarks,
        'lines': lines
            .map((line) => line.toJson())
            .toList(),
      },
    );

    return GoodsReceipt.fromJson(response);
  }
}
