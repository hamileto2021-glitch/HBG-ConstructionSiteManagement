import '../../../../../core/network/api_client.dart';
import '../models/payment.dart';
import 'package:flutter/foundation.dart';

class PaymentRepository {
  final ApiClient _api = ApiClient();



  Future<List<Payment>> getAll() async {
    final dynamic response = await _api.getValue('/payments');

    debugPrint('===== PAYMENTS API =====');
    debugPrint('TYPE: ${response.runtimeType}');
    debugPrint(response.toString());
    debugPrint('========================');

    if (response is List) {
      return response
          .map((e) => Payment.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    if (response is Map<String, dynamic>) {
      final items = response['data'] ?? response['items'] ?? response['value'];

      if (items is List) {
        return items
            .map((e) => Payment.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    throw Exception(
      'The server returned an unexpected response format.',
    );
  }
  Future<Payment> getById(String id) async {
    final data = await _api.get('/payments/$id');

    return Payment.fromJson(data);
  }

  Future<void> create({
    required String constructionSiteId,
    String? projectId,
    String? invoiceId,
    String? vendorId,
    required String paymentNumber,
    required DateTime paymentDate,
    required PaymentDirection direction,
    required double amount,
    required String currencyCode,
    required double exchangeRate,
    String? paymentMethod,
    String? referenceNumber,
    String? notes,
  }) async {
    await _api.post(
      '/payments',
      body: {
        'constructionSiteId': constructionSiteId,
        'projectId': projectId,
        'invoiceId': invoiceId,
        'vendorId': vendorId,
        'paymentNumber': paymentNumber,
        'paymentDate':
        paymentDate.toIso8601String().split('T').first,
        'direction': direction.apiValue,
        'amount': amount,
        'currencyCode': currencyCode,
        'exchangeRate': exchangeRate,
        'paymentMethod': paymentMethod,
        'referenceNumber': referenceNumber,
        'notes': notes,
      },
    );
  }

  Future<void> update({
    required String paymentId,
    required String constructionSiteId,
    String? projectId,
    String? invoiceId,
    String? vendorId,
    required DateTime paymentDate,
    required PaymentDirection direction,
    required double amount,
    required String currencyCode,
    required double exchangeRate,
    String? paymentMethod,
    String? referenceNumber,
    String? notes,
  }) async {
    await _api.put(
      '/payments/$paymentId',
      body: {
        'constructionSiteId': constructionSiteId,
        'projectId': projectId,
        'invoiceId': invoiceId,
        'vendorId': vendorId,
        'paymentDate':
        paymentDate.toIso8601String().split('T').first,
        'direction': direction.apiValue,
        'amount': amount,
        'currencyCode': currencyCode,
        'exchangeRate': exchangeRate,
        'paymentMethod': paymentMethod,
        'referenceNumber': referenceNumber,
        'notes': notes,
      },
    );
  }

  Future<Payment> changeStatus({
    required String paymentId,
    required PaymentStatus status,
  }) async {
    final data = await _api.patch(
      '/payments/$paymentId/status',
      body: {
        'status': status.apiValue,
      },
    );

    return Payment.fromJson(data);
  }
}