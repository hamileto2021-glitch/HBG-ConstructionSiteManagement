import 'package:csm_app/core/network/api_client.dart';

import '../models/budget.dart';

class BudgetRepository {
  BudgetRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Budget>> getAll() async {
    final response = await _apiClient.getList(
      '/Budgets',
    );

    return response
        .map(
          (item) => Budget.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<Budget> getById(
    String budgetId,
  ) async {
    final response = await _apiClient.get(
      '/Budgets/$budgetId',
    );

    return Budget.fromJson(response);
  }

  Future<Budget> create({
    required String constructionSiteId,
    String? projectId,
    required String budgetNumber,
    required String name,
    String? description,
    required double totalAmount,
    required String currencyCode,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
  }) async {
    final response = await _apiClient.post(
      '/Budgets',
      body: <String, dynamic>{
        'constructionSiteId': constructionSiteId,
        'projectId': projectId,
        'budgetNumber': budgetNumber,
        'name': name,
        'description': description,
        'totalAmount': totalAmount,
        'currencyCode': currencyCode,
        'effectiveFrom':
            effectiveFrom?.toIso8601String().split('T').first,
        'effectiveTo':
            effectiveTo?.toIso8601String().split('T').first,
      },
    );

    return Budget.fromJson(response);
  }

  Future<Budget> update({
    required String budgetId,
    required String name,
    String? description,
    required double totalAmount,
    required String currencyCode,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
  }) async {
    final response = await _apiClient.put(
      '/Budgets/$budgetId',
      body: <String, dynamic>{
        'name': name,
        'description': description,
        'totalAmount': totalAmount,
        'currencyCode': currencyCode,
        'effectiveFrom':
            effectiveFrom?.toIso8601String().split('T').first,
        'effectiveTo':
            effectiveTo?.toIso8601String().split('T').first,
      },
    );

    return Budget.fromJson(response);
  }

  Future<Budget> changeStatus({
    required String budgetId,
    required BudgetStatus status,
  }) async {
    final response = await _apiClient.put(
      '/Budgets/$budgetId/status',
      body: <String, dynamic>{
        'status': _statusToApiValue(status),
      },
    );

    return Budget.fromJson(response);
  }

  String _statusToApiValue(
    BudgetStatus status,
  ) {
    switch (status) {
      case BudgetStatus.draft:
        return 'Draft';
      case BudgetStatus.pendingApproval:
        return 'PendingApproval';
      case BudgetStatus.approved:
        return 'Approved';
      case BudgetStatus.active:
        return 'Active';
      case BudgetStatus.closed:
        return 'Closed';
      case BudgetStatus.cancelled:
        return 'Cancelled';
    }
  }
}
