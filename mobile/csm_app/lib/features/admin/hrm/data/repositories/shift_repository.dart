import '../../../../../core/network/api_client.dart';
import '../models/shift.dart';

class ShiftRepository {
  ShiftRepository({
    ApiClient? apiClient,
  }) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<Shift>> getAll() async {
    final response = await _api.getList('/Shifts');

    return response
        .map(
          (e) => Shift.fromJson(
        e as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  Future<Shift> getById(String id) async {
    final response = await _api.get('/Shifts/$id');

    return Shift.fromJson(response);
  }
}