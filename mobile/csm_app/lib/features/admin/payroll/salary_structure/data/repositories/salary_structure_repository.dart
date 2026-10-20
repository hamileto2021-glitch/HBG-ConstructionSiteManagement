import '../../../../../../core/network/api_client.dart';
import '../models/salary_structure.dart';

class SalaryStructureRepository {
  final _api = ApiClient();

  Future<SalaryStructure?> getByEmployee(
      String employeeId) async {
    try {
      final json = await _api.get(
        '/SalaryStructures/$employeeId',
      );

      return SalaryStructure.fromJson(json);
    } catch (e) {
      throw Exception('Failed to load salary structure: $e');
    }
  }

  Future<SalaryStructure> save(
      SalaryStructure salary) async {
    final json = await _api.post(
      '/SalaryStructures',
      body: salary.toJson(),
    );

    return SalaryStructure.fromJson(json);
  }
}