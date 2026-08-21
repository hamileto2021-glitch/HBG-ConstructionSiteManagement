import '../../../../../core/network/api_client.dart';
import '../models/payment.dart';

class PaymentRepository {
  PaymentRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Payment>> getAll() async {
    final response = await _apiClient.getList(
      '/Payments',
    );

    return response
        .map(
          (item) => Payment.fromJson(
        item as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  Future<Payment> getById(
      String paymentId,
      ) async {
    final response = await _apiClient.get(
      '/Payments/$paymentId',
    );

    return Payment.fromJson(response);
  }

  Future<Payment> create({
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
    final response = await _apiClient.post(
      '/Payments',
      body: <String, dynamic>{
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

    return Payment.fromJson(response);
  }

  Future<Payment> update({
    required String paymentId,
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
    final response = await _apiClient.put(
      '/Payments/$paymentId',
      body: <String, dynamic>{
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

    return Payment.fromJson(response);
  }

  Future<Payment> changeStatus({
    required String paymentId,
    required PaymentStatus status,
  }) async {
    final response = await _apiClient.put(
      '/Payments/$paymentId/status',
      body: <String, dynamic>{
        'status': status.apiValue,
      },
    );

    return Payment.fromJson(response);
  }
}