import 'package:flutter/foundation.dart';

import '../../../../../core/network/api_client.dart';
import '../models/daily_site_diary.dart';

class DailySiteDiaryRepository {
  DailySiteDiaryRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<DailySiteDiary>> getAll({
    String? projectId,
    String? siteId,
  }) async {
    final query = <String, String>{};

    if (projectId != null) {
      query['projectId'] = projectId;
    }

    if (siteId != null) {
      query['siteId'] = siteId;
    }

    final response = await _apiClient.getList(
      '/daily-site-diaries',
      queryParameters: query.isEmpty ? null : query,
    );

    return response
        .map((e) => DailySiteDiary.fromJson(
      e as Map<String, dynamic>,
    ))
        .toList();
  }

  Future<DailySiteDiary> getById(String id) async {
    final response =
    await _apiClient.get('/daily-site-diaries/$id');

    return DailySiteDiary.fromJson(response);
  }

  Future<DailySiteDiary> create({
    required String siteId,
    String? projectId,
    required DateTime diaryDate,
    required WeatherType weather,
    required double temperature,
    required int workforceCount,
    required int equipmentInUse,
    required String workPerformed,
    String? delayReason,
    String? safetyObservation,
  }) async {
    try {
      final response = await _apiClient.post(
        '/daily-site-diaries',
        body: {
          'siteId': siteId,
          'projectId': projectId,
          'diaryDate':
          diaryDate.toIso8601String().split('T').first,
          'weather': weather.name,
          'temperature': temperature,
          'workforceCount': workforceCount,
          'equipmentInUse': equipmentInUse,
          'workPerformed': workPerformed,
          'delayReason': delayReason,
          'safetyObservation': safetyObservation,
        },
      );

      return DailySiteDiary.fromJson(response);
    } catch (e) {
      debugPrint(
          '========== DAILY SITE DIARY ERROR ==========');
      debugPrint(e.toString());
      debugPrint(
          '==========================================');
      rethrow;
    }
  }

  Future<DailySiteDiary> update({
    required String diaryId,
    required String siteId,
    String? projectId,
    required DateTime diaryDate,
    required WeatherType weather,
    required double temperature,
    required int workforceCount,
    required int equipmentInUse,
    required String workPerformed,
    String? delayReason,
    String? safetyObservation,
  }) async {
    final response = await _apiClient.put(
      '/daily-site-diaries/$diaryId',
      body: {
        'siteId': siteId,
        'projectId': projectId,
        'diaryDate':
        diaryDate.toIso8601String().split('T').first,
        'weather': weather.name,
        'temperature': temperature,
        'workforceCount': workforceCount,
        'equipmentInUse': equipmentInUse,
        'workPerformed': workPerformed,
        'delayReason': delayReason,
        'safetyObservation': safetyObservation,
      },
    );

    return DailySiteDiary.fromJson(response);
  }

  Future<void> delete(String diaryId) async {
    await _apiClient.delete(
      '/daily-site-diaries/$diaryId',
    );
  }
}