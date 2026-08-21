import 'package:csm_app/core/network/api_client.dart';

import '../models/equipment.dart';

class EquipmentRepository {
  EquipmentRepository({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Equipment>> getAll({
    bool? isActive,
    String? status,
    String? ownershipType,
  }) async {
    final queryParameters = <String, String>{};

    if (isActive != null) {
      queryParameters['isActive'] = isActive.toString();
    }

    if (status != null && status.trim().isNotEmpty) {
      queryParameters['status'] = status.trim();
    }

    if (ownershipType != null &&
        ownershipType.trim().isNotEmpty) {
      queryParameters['ownershipType'] =
          ownershipType.trim();
    }

    final response = await _apiClient.getList(
      '/Equipment',
      queryParameters: queryParameters,
    );

    return response
        .map(
          (item) => Equipment.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<Equipment> getById(String equipmentId) async {
    final response = await _apiClient.get(
      '/Equipment/$equipmentId',
    );

    return Equipment.fromJson(response);
  }

  Future<Equipment> create({
    required String equipmentCode,
    required String name,
    String? category,
    String? make,
    String? model,
    String? serialNumber,
    String? registrationNumber,
    required String ownershipType,
    required String status,
    String? vendorId,
    double? purchaseCost,
    double? rentalRate,
    String? rentalRateUnit,
    DateTime? rentalStartDate,
    DateTime? rentalEndDate,
    required double currentMeterReading,
    required String meterUnit,
    required bool isActive,
  }) async {
    final response = await _apiClient.post(
      '/Equipment',
      body: <String, dynamic>{
        'equipmentCode': equipmentCode,
        'name': name,
        'category': category,
        'make': make,
        'model': model,
        'serialNumber': serialNumber,
        'registrationNumber': registrationNumber,
        'ownershipType': ownershipType,
        'status': status,
        'vendorId': vendorId,
        'purchaseCost': purchaseCost,
        'rentalRate': rentalRate,
        'rentalRateUnit': rentalRateUnit,
        'rentalStartDate':
            rentalStartDate?.toIso8601String().split('T').first,
        'rentalEndDate':
            rentalEndDate?.toIso8601String().split('T').first,
        'currentMeterReading': currentMeterReading,
        'meterUnit': meterUnit,
        'isActive': isActive,
      },
    );

    return Equipment.fromJson(response);
  }

  Future<Equipment> update({
    required String equipmentId,
    required String equipmentCode,
    required String name,
    String? category,
    String? make,
    String? model,
    String? serialNumber,
    String? registrationNumber,
    required String ownershipType,
    required String status,
    String? vendorId,
    double? purchaseCost,
    double? rentalRate,
    String? rentalRateUnit,
    DateTime? rentalStartDate,
    DateTime? rentalEndDate,
    required double currentMeterReading,
    required String meterUnit,
    required bool isActive,
  }) async {
    final response = await _apiClient.put(
      '/Equipment/$equipmentId',
      body: <String, dynamic>{
        'equipmentCode': equipmentCode,
        'name': name,
        'category': category,
        'make': make,
        'model': model,
        'serialNumber': serialNumber,
        'registrationNumber': registrationNumber,
        'ownershipType': ownershipType,
        'status': status,
        'vendorId': vendorId,
        'purchaseCost': purchaseCost,
        'rentalRate': rentalRate,
        'rentalRateUnit': rentalRateUnit,
        'rentalStartDate':
            rentalStartDate?.toIso8601String().split('T').first,
        'rentalEndDate':
            rentalEndDate?.toIso8601String().split('T').first,
        'currentMeterReading': currentMeterReading,
        'meterUnit': meterUnit,
        'isActive': isActive,
      },
    );

    return Equipment.fromJson(response);
  }
}
