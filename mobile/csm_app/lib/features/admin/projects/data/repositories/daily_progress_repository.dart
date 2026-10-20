import 'package:csm_app/core/network/api_client.dart';

import '../models/daily_progress.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/database/app_database.dart';
import '../../../../../core/sync/connectivity_service.dart';



class DailyProgressRepository {
  DailyProgressRepository({
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

  Future<List<DailyProgressLog>> getAll({
    required String projectId,
  }) async {
    final response = await _api.getList(
      '/DailyProgressLogs',
      queryParameters: {
        'projectId': projectId,
      },
    );

    return response
        .map((e) => DailyProgressLog.fromJson(
      e as Map<String, dynamic>,
    ))
        .toList();
  }

  Future<DailyProgressLog> getById(String id) async {
    final response = await _api.get(
      '/DailyProgressLogs/$id',
    );

    return DailyProgressLog.fromJson(response);
  }

  Future<DailyProgressLog> create({
    required String projectId,
    required DateTime logDate,
    String? weatherCondition,
    double? temperatureCelsius,
    required int laborCount,
    required int contractorLaborCount,
    required double progressPercentage,
    String? workCompleted,
    String? workPlannedNext,
    String? materialsUsedSummary,
    String? equipmentUsedSummary,
    String? issues,
    String? safetyNotes,
    String? remarks,
  }) async {

    final payload = {
      'projectId': projectId,
      'logDate': _dateOnly(logDate),
      'weatherCondition': weatherCondition,
      'temperatureCelsius': temperatureCelsius,
      'laborCount': laborCount,
      'contractorLaborCount': contractorLaborCount,
      'progressPercentage': progressPercentage,
      'workCompleted': workCompleted,
      'workPlannedNext': workPlannedNext,
      'materialsUsedSummary': materialsUsedSummary,
      'equipmentUsedSummary': equipmentUsedSummary,
      'issues': issues,
      'safetyNotes': safetyNotes,
      'remarks': remarks,
    };

    final online = await _connectivity.isOnline();

    if (online) {
      final response = await _api.post(
        '/DailyProgressLogs',
        body: payload,
      );
      return DailyProgressLog.fromJson(response);
    }

// OFFLINE
    final id = _uuid.v4();

    await _db.syncQueueDao.enqueue(
      id: id,
      entity: 'DailyProgress',
      action: 'POST',
      payload: jsonEncode(payload),
    );

    debugPrint('DAILY PROGRESS QUEUED: $id');

    return DailyProgressLog(
      id: id,
      logNumber: 'OFFLINE',
      companyId: '',
      projectId: projectId,
      logDate: logDate,
      weatherCondition: weatherCondition,
      temperatureCelsius: temperatureCelsius,
      laborCount: laborCount,
      contractorLaborCount: contractorLaborCount,
      progressPercentage: progressPercentage,
      workCompleted: workCompleted,
      workPlannedNext: workPlannedNext,
      materialsUsedSummary: materialsUsedSummary,
      equipmentUsedSummary: equipmentUsedSummary,
      delays: null,
      issues: issues,
      safetyNotes: safetyNotes,
      remarks: remarks,
      createdAtUtc: DateTime.now().toUtc(),
    );
  }

  Future<DailyProgressLog> update({
    required String logId,
    required DateTime logDate,
    String? weatherCondition,
    double? temperatureCelsius,
    required int laborCount,
    required int contractorLaborCount,
    required double progressPercentage,
    String? workCompleted,
    String? workPlannedNext,
    String? materialsUsedSummary,
    String? equipmentUsedSummary,
    String? issues,
    String? safetyNotes,
    String? remarks,
  }) async {
    final response = await _api.put(
      '/DailyProgressLogs/$logId',
      body: {
        'logDate': _dateOnly(logDate),
        'weatherCondition': weatherCondition,
        'temperatureCelsius': temperatureCelsius,
        'laborCount': laborCount,
        'contractorLaborCount': contractorLaborCount,
        'progressPercentage': progressPercentage,
        'workCompleted': workCompleted,
        'workPlannedNext': workPlannedNext,
        'materialsUsedSummary': materialsUsedSummary,
        'equipmentUsedSummary': equipmentUsedSummary,
        'issues': issues,
        'safetyNotes': safetyNotes,
        'remarks': remarks,
      },
    );

    return DailyProgressLog.fromJson(response);
  }
  Future<void> syncCreate(
      Map<String, dynamic> payload,
      ) async {
    await _api.post(
      '/DailyProgressLogs',
      body: payload,
    );
  }

  Future<void> syncUpdate(
      String id,
      Map<String, dynamic> payload,
      ) async {
    await _api.put(
      '/DailyProgressLogs/$id',
      body: payload,
    );
  }

  Future<void> syncDelete(String id) async {
    await _api.delete('/DailyProgressLogs/$id');
  }

  String _dateOnly(DateTime date) =>
      date.toIso8601String().split('T').first;
}