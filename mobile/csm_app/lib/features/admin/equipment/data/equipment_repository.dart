import '../../../../core/network/api_client.dart';
import 'models/equipment_model.dart';

class EquipmentRepository {
  final ApiClient _api = ApiClient();

  Future<List<EquipmentModel>> getAll() async {
    final data = await _api.getList('/ProjectEquipment');

    return data
        .map((e) => EquipmentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<EquipmentModel> create(EquipmentModel equipment) async {
    final data = await _api.post(
      '/ProjectEquipment',
      body: equipment.toJson(),
    );

    return EquipmentModel.fromJson(data);
  }

  Future<void> delete(String id) async {
    await _api.delete('/ProjectEquipment/$id');
  }
}