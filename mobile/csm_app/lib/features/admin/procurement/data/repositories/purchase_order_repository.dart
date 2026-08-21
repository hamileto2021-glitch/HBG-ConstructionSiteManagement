import 'package:csm_app/core/network/api_client.dart';

import '../models/purchase_order.dart';

class PurchaseOrderRepository {
  PurchaseOrderRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<PurchaseOrder>> getAll({
    String? constructionSiteId,
    String? vendorId,
    PurchaseOrderStatus? status,
  }) async {
    final queryParameters = <String, String>{};

    if (constructionSiteId != null &&
        constructionSiteId.trim().isNotEmpty) {
      queryParameters['constructionSiteId'] =
          constructionSiteId.trim();
    }

    if (vendorId != null &&
        vendorId.trim().isNotEmpty) {
      queryParameters['vendorId'] = vendorId.trim();
    }

    if (status != null) {
      queryParameters['status'] =
          _statusValue(status).toString();
    }

    final response = await _apiClient.getList(
      '/PurchaseOrders',
      queryParameters: queryParameters,
    );

    return response
        .map(
          (item) => PurchaseOrder.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<PurchaseOrder> getById(
    String purchaseOrderId,
  ) async {
    final response = await _apiClient.get(
      '/PurchaseOrders/$purchaseOrderId',
    );

    return PurchaseOrder.fromJson(response);
  }

  Future<PurchaseOrder> create({
    required String constructionSiteId,
    String? projectId,
    required String vendorId,
    String? materialRequestId,
    required String purchaseOrderNumber,
    required DateTime orderDate,
    DateTime? expectedDeliveryDate,
    required String currencyCode,
    required double exchangeRate,
    required double discountAmount,
    String? deliveryAddress,
    String? paymentTerms,
    String? notes,
    required List<PurchaseOrderLineInput> lines,
  }) async {
    final response = await _apiClient.post(
      '/PurchaseOrders',
      body: <String, dynamic>{
        'constructionSiteId': constructionSiteId,
        'projectId': projectId,
        'vendorId': vendorId,
        'materialRequestId': materialRequestId,
        'purchaseOrderNumber': purchaseOrderNumber,
        'orderDate': _formatDate(orderDate),
        'expectedDeliveryDate':
            expectedDeliveryDate == null
                ? null
                : _formatDate(expectedDeliveryDate),
        'currencyCode': currencyCode,
        'exchangeRate': exchangeRate,
        'discountAmount': discountAmount,
        'deliveryAddress': deliveryAddress,
        'paymentTerms': paymentTerms,
        'notes': notes,
        'lines': lines
            .map((line) => line.toJson())
            .toList(),
      },
    );

    return PurchaseOrder.fromJson(response);
  }

  Future<PurchaseOrder> update({
    required String purchaseOrderId,
    required String constructionSiteId,
    String? projectId,
    required String vendorId,
    String? materialRequestId,
    required String purchaseOrderNumber,
    required DateTime orderDate,
    DateTime? expectedDeliveryDate,
    required String currencyCode,
    required double exchangeRate,
    required double discountAmount,
    String? deliveryAddress,
    String? paymentTerms,
    String? notes,
    required List<PurchaseOrderLineInput> lines,
  }) async {
    final response = await _apiClient.put(
      '/PurchaseOrders/$purchaseOrderId',
      body: <String, dynamic>{
        'constructionSiteId': constructionSiteId,
        'projectId': projectId,
        'vendorId': vendorId,
        'materialRequestId': materialRequestId,
        'purchaseOrderNumber': purchaseOrderNumber,
        'orderDate': _formatDate(orderDate),
        'expectedDeliveryDate':
            expectedDeliveryDate == null
                ? null
                : _formatDate(expectedDeliveryDate),
        'currencyCode': currencyCode,
        'exchangeRate': exchangeRate,
        'discountAmount': discountAmount,
        'deliveryAddress': deliveryAddress,
        'paymentTerms': paymentTerms,
        'notes': notes,
        'lines': lines
            .map((line) => line.toJson())
            .toList(),
      },
    );

    return PurchaseOrder.fromJson(response);
  }

  Future<PurchaseOrder> submit(
    String purchaseOrderId,
  ) async {
    final response = await _apiClient.post(
      '/PurchaseOrders/$purchaseOrderId/submit',
    );

    return PurchaseOrder.fromJson(response);
  }

  Future<PurchaseOrder> approve(
    String purchaseOrderId,
  ) async {
    final response = await _apiClient.post(
      '/PurchaseOrders/$purchaseOrderId/approve',
    );

    return PurchaseOrder.fromJson(response);
  }

  Future<PurchaseOrder> sendToVendor(
    String purchaseOrderId,
  ) async {
    final response = await _apiClient.post(
      '/PurchaseOrders/$purchaseOrderId/send-to-vendor',
    );

    return PurchaseOrder.fromJson(response);
  }

  Future<PurchaseOrder> cancel(
    String purchaseOrderId,
  ) async {
    final response = await _apiClient.post(
      '/PurchaseOrders/$purchaseOrderId/cancel',
    );

    return PurchaseOrder.fromJson(response);
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();

    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  int _statusValue(PurchaseOrderStatus status) {
    switch (status) {
      case PurchaseOrderStatus.draft:
        return 1;
      case PurchaseOrderStatus.pendingApproval:
        return 2;
      case PurchaseOrderStatus.approved:
        return 3;
      case PurchaseOrderStatus.sentToVendor:
        return 4;
      case PurchaseOrderStatus.partiallyDelivered:
        return 5;
      case PurchaseOrderStatus.delivered:
        return 6;
      case PurchaseOrderStatus.closed:
        return 7;
      case PurchaseOrderStatus.cancelled:
        return 8;
    }
  }
}
