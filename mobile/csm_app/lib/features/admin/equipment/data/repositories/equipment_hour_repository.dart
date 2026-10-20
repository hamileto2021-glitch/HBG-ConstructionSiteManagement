import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../../core/database/app_database.dart';
import '../../../../../core/sync/connectivity_service.dart';
import '../models/equipment_hour.dart';

class EquipmentHourRepository {
  EquipmentHourRepository({
    ApiClient? apiClient,
    AppDatabase? database,
    ConnectivityService? connectivity,
  })  : _api = apiClient ?? ApiClient(),
        _db = database ?? AppDatabase(),
        _connectivity = connectivity ?? ConnectivityService();

  final ApiClient _api;
  final AppDatabase _db;
  final ConnectivityService _connectivity;
  final Uuid _uuid = const Uuid();

  Future<EquipmentHour> create({
    required String equipmentId,
    required String projectId,
    required DateTime workDate,
    required double startHour,
    required double endHour,
    required String operatorName,
    String? remarks,
  }) async {
    final totalHours = endHour - startHour;

    final payload = {
      'equipmentId': equipmentId,
      'siteId': projectId,
      'workDate': workDate.toIso8601String().split('T').first,
      'startHour': startHour,
      'endHour': endHour,
      'totalHours': totalHours,
      'operatorName':
      operatorName.trim().isEmpty ? 'Unknown Operator' : operatorName,
      'activity': 'Equipment Operation',
      'remarks': remarks,
    };

    final online = await _connectivity.isOnline();
    debugPrint('EQUIPMENT HOURS ONLINE: $online');

    if (online) {
      final response = await _api.post(
        '/EquipmentHourLogs',
        body: payload,
      );

      return EquipmentHour.fromJson(response);
    }

    final id = _uuid.v4();

    await _db.syncQueueDao.enqueue(
      id: id,
      entity: 'EquipmentHour',
      action: 'POST',
      payload: jsonEncode(payload),
    );

    debugPrint('EQUIPMENT HOURS QUEUED: $id');

    return EquipmentHour(
      id: id,
      equipmentId: equipmentId,
      projectId: projectId,
      workDate: workDate,
      startHour: startHour,
      endHour: endHour,
      totalHours: totalHours,
      operatorName: operatorName,
      remarks: remarks,
      createdAtUtc: DateTime.now().toUtc(),
      status: EquipmentHourStatus.draft,
    );
  }

  Future<void> syncCreate(
      Map<String, dynamic> payload,
      ) async {
    await _api.post(
      '/EquipmentHourLogs',
      body: payload,
    );
  }

  Future<void> syncUpdate(
      String id,
      Map<String, dynamic> payload,
      ) async {
    await _api.put(
      '/EquipmentHourLogs/$id',
      body: payload,
    );
  }

  Future<void> syncDelete(String id) async {
    await _api.delete('/EquipmentHourLogs/$id');
  }
}