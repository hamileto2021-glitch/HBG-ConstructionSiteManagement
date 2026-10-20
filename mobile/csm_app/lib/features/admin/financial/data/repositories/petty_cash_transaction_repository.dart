import '../../../../../core/network/api_client.dart';
import '../models/petty_cash_transaction.dart';

class PettyCashTransactionRepository {
  PettyCashTransactionRepository({
    ApiClient? apiClient,
  }) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<PettyCashTransaction>> getByAccount(
      String accountId) async {
    final data = await _api.getList(
      '/PettyCashTransactions',
      queryParameters: {
        'pettyCashAccountId': accountId,
      },
    );

    return data
        .map(
          (e) => PettyCashTransaction.fromJson(
        e as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  Future<void> create({
    required String pettyCashAccountId,
    required String transactionType,
    required String referenceNumber,
    required double amount,
    required String description,
    String? remarks,
    String? costCodeId,
  }) async {
    await _api.post(
      '/PettyCashTransactions',
      body: {
        'pettyCashAccountId': pettyCashAccountId,
        'transactionType': transactionType,
        'referenceNumber': referenceNumber,
        'amount': amount,
        'description': description,
        'remarks': remarks,
        'costCodeId': costCodeId,
      },
    );
  }
}