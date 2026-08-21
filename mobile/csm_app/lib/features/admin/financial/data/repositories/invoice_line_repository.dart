import '../../../../../core/network/api_client.dart';
import '../models/invoice_line.dart';

class InvoiceLineRepository {
  InvoiceLineRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<InvoiceLine>> getByInvoice(
    String invoiceId,
  ) async {
    final response = await _apiClient.getList(
      '/InvoiceLines/invoice/$invoiceId',
    );

    return response
        .map(
          (item) => InvoiceLine.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<InvoiceLine> getById(
    String invoiceLineId,
  ) async {
    final response = await _apiClient.get(
      '/InvoiceLines/$invoiceLineId',
    );

    return InvoiceLine.fromJson(response);
  }

  Future<InvoiceLine> create({
    required String invoiceId,
    required String description,
    required double quantity,
    required double unitPrice,
  }) async {
    final response = await _apiClient.post(
      '/InvoiceLines/invoice/$invoiceId',
      body: <String, dynamic>{
        'description': description,
        'quantity': quantity,
        'unitPrice': unitPrice,
      },
    );

    return InvoiceLine.fromJson(response);
  }

  Future<InvoiceLine> update({
    required String invoiceLineId,
    required String description,
    required double quantity,
    required double unitPrice,
  }) async {
    final response = await _apiClient.put(
      '/InvoiceLines/$invoiceLineId',
      body: <String, dynamic>{
        'description': description,
        'quantity': quantity,
        'unitPrice': unitPrice,
      },
    );

    return InvoiceLine.fromJson(response);
  }
}