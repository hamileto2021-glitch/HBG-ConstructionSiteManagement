import '../../../../../core/network/api_client.dart';
import '../models/petty_cash_account.dart';

class PettyCashRepository {
  PettyCashRepository({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<PettyCashAccount>> getAll() async {
    final data = await _api.getList('/PettyCashAccounts');

    return data
        .map(
          (e) => PettyCashAccount.fromJson(
        e as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  Future<PettyCashAccount> getById(String id) async {
    final data = await _api.get('/PettyCashAccounts/$id');

    return PettyCashAccount.fromJson(data);
  }

  Future<PettyCashAccount> create({
    required String constructionSiteId,
    required String accountCode,
    required String accountName,
    required double openingBalance,
  }) async {
    final data = await _api.post(
      '/PettyCashAccounts',
      body: {
        'constructionSiteId': constructionSiteId,
        'accountCode': accountCode,
        'accountName': accountName,
        'openingBalance': openingBalance,
      },
    );

    return PettyCashAccount.fromJson(data);
  }

  Future<PettyCashAccount> update({
    required String id,
    required String accountName,
    required bool isActive,
  }) async {
    final data = await _api.put(
      '/PettyCashAccounts/$id',
      body: {
        'accountName': accountName,
        'isActive': isActive,
      },
    );

    return PettyCashAccount.fromJson(data);
  }
}