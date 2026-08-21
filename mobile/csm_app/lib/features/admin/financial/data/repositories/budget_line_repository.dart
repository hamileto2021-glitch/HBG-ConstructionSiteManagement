import '../../../../../core/network/api_client.dart';
import '../models/budget_line.dart';

class BudgetLineRepository {
  BudgetLineRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<BudgetLine>> getByBudget(
    String budgetId,
  ) async {
    final response = await _apiClient.getList(
      '/BudgetLines/budget/$budgetId',
    );

    return response
        .map(
          (item) => BudgetLine.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<BudgetLine> getById(
    String budgetLineId,
  ) async {
    final response = await _apiClient.get(
      '/BudgetLines/$budgetLineId',
    );

    return BudgetLine.fromJson(response);
  }

  Future<BudgetLine> create({
    required String budgetId,
    required String costCodeId,
    String? description,
    required double budgetedAmount,
    required double revisedAmount,
  }) async {
    final response = await _apiClient.post(
      '/BudgetLines',
      body: <String, dynamic>{
        'budgetId': budgetId,
        'costCodeId': costCodeId,
        'description': description,
        'budgetedAmount': budgetedAmount,
        'revisedAmount': revisedAmount,
      },
    );

    return BudgetLine.fromJson(response);
  }

  Future<BudgetLine> update({
    required String budgetLineId,
    required String costCodeId,
    String? description,
    required double budgetedAmount,
    required double revisedAmount,
  }) async {
    final response = await _apiClient.put(
      '/BudgetLines/$budgetLineId',
      body: <String, dynamic>{
        'costCodeId': costCodeId,
        'description': description,
        'budgetedAmount': budgetedAmount,
        'revisedAmount': revisedAmount,
      },
    );

    return BudgetLine.fromJson(response);
  }
}
