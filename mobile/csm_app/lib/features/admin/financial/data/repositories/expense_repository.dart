import '../../../../../core/network/api_client.dart';
import '../models/expense.dart';

class ExpenseRepository {
  ExpenseRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Expense>> getAll() async {
    final response = await _apiClient.getList(
      '/Expenses',
    );

    return response
        .map(
          (item) => Expense.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<Expense> getById(
    String expenseId,
  ) async {
    final response = await _apiClient.get(
      '/Expenses/$expenseId',
    );

    return Expense.fromJson(response);
  }

  Future<Expense> create({
    required String constructionSiteId,
    String? projectId,
    required String costCodeId,
    String? vendorId,
    required String expenseNumber,
    required DateTime expenseDate,
    required String description,
    required double amount,
    required double taxAmount,
    required String currencyCode,
    required double exchangeRate,
    String? referenceNumber,
    String? receiptDocumentUrl,
  }) async {
    final response = await _apiClient.post(
      '/Expenses',
      body: <String, dynamic>{
        'constructionSiteId': constructionSiteId,
        'projectId': projectId,
        'costCodeId': costCodeId,
        'vendorId': vendorId,
        'expenseNumber': expenseNumber,
        'expenseDate':
            expenseDate.toIso8601String().split('T').first,
        'description': description,
        'amount': amount,
        'taxAmount': taxAmount,
        'currencyCode': currencyCode,
        'exchangeRate': exchangeRate,
        'referenceNumber': referenceNumber,
        'receiptDocumentUrl': receiptDocumentUrl,
      },
    );

    return Expense.fromJson(response);
  }

  Future<Expense> update({
    required String expenseId,
    required String constructionSiteId,
    String? projectId,
    required String costCodeId,
    String? vendorId,
    required DateTime expenseDate,
    required String description,
    required double amount,
    required double taxAmount,
    required String currencyCode,
    required double exchangeRate,
    String? referenceNumber,
    String? receiptDocumentUrl,
  }) async {
    final response = await _apiClient.put(
      '/Expenses/$expenseId',
      body: <String, dynamic>{
        'constructionSiteId': constructionSiteId,
        'projectId': projectId,
        'costCodeId': costCodeId,
        'vendorId': vendorId,
        'expenseDate':
            expenseDate.toIso8601String().split('T').first,
        'description': description,
        'amount': amount,
        'taxAmount': taxAmount,
        'currencyCode': currencyCode,
        'exchangeRate': exchangeRate,
        'referenceNumber': referenceNumber,
        'receiptDocumentUrl': receiptDocumentUrl,
      },
    );

    return Expense.fromJson(response);
  }

  Future<Expense> changeStatus({
    required String expenseId,
    required ExpenseStatus status,
  }) async {
    final response = await _apiClient.put(
      '/Expenses/$expenseId/status',
      body: <String, dynamic>{
        'status': status.apiValue,
      },
    );

    return Expense.fromJson(response);
  }
}
