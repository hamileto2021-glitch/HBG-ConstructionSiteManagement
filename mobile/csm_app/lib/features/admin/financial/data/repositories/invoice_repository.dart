import '../../../../../core/network/api_client.dart';
import '../models/invoice.dart';

class InvoiceRepository {
  InvoiceRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Invoice>> getAll() async {
    final response = await _apiClient.getList(
      '/Invoices',
    );

    return response
        .map(
          (item) => Invoice.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<Invoice> getById(
    String invoiceId,
  ) async {
    final response = await _apiClient.get(
      '/Invoices/$invoiceId',
    );

    return Invoice.fromJson(response);
  }

  Future<Invoice> create({
    required String constructionSiteId,
    String? projectId,
    String? vendorId,
    required String invoiceNumber,
    required InvoiceType type,
    required DateTime invoiceDate,
    DateTime? dueDate,
    required double subtotal,
    required double taxAmount,
    required double totalAmount,
    required String currencyCode,
    required double exchangeRate,
    String? description,
    String? externalReference,
  }) async {
    final response = await _apiClient.post(
      '/Invoices',
      body: <String, dynamic>{
        'constructionSiteId': constructionSiteId,
        'projectId': projectId,
        'vendorId': vendorId,
        'invoiceNumber': invoiceNumber,
        'type': type.apiValue,
        'invoiceDate':
            invoiceDate.toIso8601String().split('T').first,
        'dueDate':
            dueDate?.toIso8601String().split('T').first,
        'subtotal': subtotal,
        'taxAmount': taxAmount,
        'totalAmount': totalAmount,
        'currencyCode': currencyCode,
        'exchangeRate': exchangeRate,
        'description': description,
        'externalReference': externalReference,
      },
    );

    return Invoice.fromJson(response);
  }

  Future<Invoice> update({
    required String invoiceId,
    required String constructionSiteId,
    String? projectId,
    String? vendorId,
    required InvoiceType type,
    required DateTime invoiceDate,
    DateTime? dueDate,
    required double subtotal,
    required double taxAmount,
    required double totalAmount,
    required String currencyCode,
    required double exchangeRate,
    String? description,
    String? externalReference,
  }) async {
    final response = await _apiClient.put(
      '/Invoices/$invoiceId',
      body: <String, dynamic>{
        'constructionSiteId': constructionSiteId,
        'projectId': projectId,
        'vendorId': vendorId,
        'type': type.apiValue,
        'invoiceDate':
            invoiceDate.toIso8601String().split('T').first,
        'dueDate':
            dueDate?.toIso8601String().split('T').first,
        'subtotal': subtotal,
        'taxAmount': taxAmount,
        'totalAmount': totalAmount,
        'currencyCode': currencyCode,
        'exchangeRate': exchangeRate,
        'description': description,
        'externalReference': externalReference,
      },
    );

    return Invoice.fromJson(response);
  }

  Future<Invoice> changeStatus({
    required String invoiceId,
    required InvoiceStatus status,
  }) async {
    final response = await _apiClient.put(
      '/Invoices/$invoiceId/status',
      body: <String, dynamic>{
        'status': status.apiValue,
      },
    );

    return Invoice.fromJson(response);
  }
}