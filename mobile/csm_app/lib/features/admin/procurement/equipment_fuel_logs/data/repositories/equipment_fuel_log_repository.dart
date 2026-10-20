import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:csm_app/core/database/app_database.dart';
import 'package:csm_app/core/network/api_client.dart';
import 'package:csm_app/core/sync/connectivity_service.dart';

import '../models/equipment_fuel_log.dart';



class EquipmentFuelLogRepository {
  EquipmentFuelLogRepository({
    ApiClient? apiClient,
    AppDatabase? database,
    ConnectivityService? connectivity,
  })  : _apiClient = apiClient ?? ApiClient(),
        _db = database ?? AppDatabase(),
        _connectivity = connectivity ?? ConnectivityService();

  final ApiClient _apiClient;
  final AppDatabase _db;
  final ConnectivityService _connectivity;
  final Uuid _uuid = const Uuid();

  Future<List<EquipmentFuelLog>> getAll({
    String? equipmentId,
  }) async {
    final queryParameters = <String, String>{};

    if (equipmentId != null) {
      queryParameters['equipmentId'] = equipmentId;
    }

    final response = await _apiClient.getList(
      '/EquipmentFuelLogs',
      queryParameters: queryParameters,
    );

    return response
        .map(
          (item) => EquipmentFuelLog.fromJson(
        item as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  Future<EquipmentFuelLog> create({
    required String equipmentId,
    required String siteId,
    required DateTime refueledAtUtc,
    required double liters,
    required double unitPrice,
    required double meterReading,
    required String fuelType,
    String? supplierName,
    String? invoiceNumber,
    String? remarks,
  }) async {
    final payload = {
      'equipmentId': equipmentId,
      'siteId': siteId,
      'refueledAtUtc': refueledAtUtc.toUtc().toIso8601String(),
      'liters': liters,
      'unitPrice': unitPrice,
      'meterReading': meterReading,
      'fuelType': fuelType,
      'supplierName': supplierName,
      'invoiceNumber': invoiceNumber,
      'remarks': remarks,
    };

    final online = await _connectivity.isOnline();
    debugPrint('FUEL ONLINE: $online');

    if (online) {
      final response = await _apiClient.post(
        '/EquipmentFuelLogs',
        body: payload,
      );

      return EquipmentFuelLog.fromJson(response);
    }

    final id = _uuid.v4();

    await _db.syncQueueDao.enqueue(
      id: id,
      entity: 'EquipmentFuel',
      action: 'POST',
      payload: jsonEncode(payload),
    );

    debugPrint('FUEL QUEUED: $id');

    return EquipmentFuelLog.fromJson({
      'id': id,
      'equipmentId': equipmentId,
      'equipmentCode': 'OFFLINE',
      'equipmentName': 'Offline Equipment',
      'siteId': siteId,
      'siteName': 'Offline Site',
      'refueledAtUtc': refueledAtUtc.toUtc().toIso8601String(),
      'liters': liters,
      'unitPrice': unitPrice,
      'totalCost': liters * unitPrice,
      'meterReading': meterReading,
      'fuelType': fuelType,
      'supplierName': supplierName,
      'invoiceNumber': invoiceNumber,
      'remarks': remarks,
    });
  }
  Future<void> syncCreate(Map<String, dynamic> payload) async {
    await _apiClient.post(
      '/EquipmentFuelLogs',
      body: payload,
    );
  }
}