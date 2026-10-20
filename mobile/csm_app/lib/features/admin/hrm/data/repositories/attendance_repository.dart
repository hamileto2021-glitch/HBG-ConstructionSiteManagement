import '../../../../../core/network/api_client.dart';
import '../models/attendance/attendance.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

import '../../../../../core/database/app_database.dart';
import '../../../../../core/sync/connectivity_service.dart';
import 'package:flutter/foundation.dart';


class AttendanceRepository {
  AttendanceRepository({
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

  Future<List<Attendance>> getAll({
    String? employeeId,
    String? constructionSiteId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final query = <String, String>{};

    if (employeeId != null && employeeId.isNotEmpty) {
      query['employeeId'] = employeeId;
    }

    if (constructionSiteId != null &&
        constructionSiteId.isNotEmpty) {
      query['constructionSiteId'] = constructionSiteId;
    }

    if (fromDate != null) {
      query['fromDate'] = _dateOnly(fromDate);
    }

    if (toDate != null) {
      query['toDate'] = _dateOnly(toDate);
    }

    final response = await _apiClient.getList(
      '/Attendances',
      queryParameters: query,
    );

    return response
        .map(
          (item) => Attendance.fromJson(
        item as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  Future<Attendance> getById(
      String attendanceId,
      ) async {
    final response = await _apiClient.get(
      '/Attendances/$attendanceId',
    );

    return Attendance.fromJson(response);
  }


  Future<Attendance> checkIn({
    required String employeeId,
    required String constructionSiteId,
    String? shiftId,
    required DateTime checkInAtUtc,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    required AttendanceSource source,
    String? biometricReference,
    String? remarks,
  }) async {
    final payload = {
      'employeeId': employeeId,
      'constructionSiteId': constructionSiteId,
      'shiftId': shiftId,
      'checkInAtUtc': checkInAtUtc.toUtc().toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'accuracyMeters': accuracyMeters,
      'source': _sourceName(source),
      'biometricReference': biometricReference,
      'remarks': remarks,
    };

    // ONLINE
    final online = await _connectivity.isOnline();

    debugPrint('ATTENDANCE ONLINE: $online');

    if (online) {
      final response = await _apiClient.post(
        '/Attendances/check-in',
        body: payload,
      );

      return Attendance.fromJson(response);
    }

    debugPrint('OFFLINE -> enqueue attendance');

    // OFFLINE
    final id = _uuid.v4();

    await _db.attendanceLocal.save(
      id: id,
      employeeId: employeeId,
      employeeName: 'Offline Employee',
      attendanceDate: checkInAtUtc,
      status: 'Present',
      checkIn: checkInAtUtc.toIso8601String(),
      latitude: latitude,
      longitude: longitude,
    );


    debugPrint('QUEUE ENQUEUED: $id');

    await _db.syncQueueDao.enqueue(
      id: id,
      entity: 'Attendance',
      action: 'POST',
      payload: jsonEncode(payload),
    );

    return Attendance.fromJson({
      'id': id,
      'companyId': '',
      'employeeId': employeeId,
      'employeeName': 'Offline Employee',
      'employeeNumber': 'OFFLINE',
      'constructionSiteId': constructionSiteId,
      'siteName': 'Offline',
      'shiftId': shiftId,
      'shiftName': null,
      'attendanceDate': checkInAtUtc.toUtc().toIso8601String(),
      'checkInAtUtc': checkInAtUtc.toUtc().toIso8601String(),
      'checkOutAtUtc': null,
      'status': 'Present',
      'source': _sourceName(source),
      'isCheckInWithinGeofence': true,
      'isCheckOutWithinGeofence': true,
      'regularHours': 0,
      'overtimeHours': 0,
      'requiresApproval': false,
      'isApproved': false,
      'createdAtUtc': DateTime.now().toUtc().toIso8601String(),
      'approvedByName': null,
      'approvedAtUtc': null,
      'remarks': remarks,
    });
  }

  Future<Attendance> checkOut({
    required String attendanceId,
    required DateTime checkOutAtUtc,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    String? remarks,
  }) async {
    final response = await _apiClient.put(
      '/Attendances/$attendanceId/check-out',
      body: <String, dynamic>{
        'checkOutAtUtc':
        checkOutAtUtc.toUtc().toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'accuracyMeters': accuracyMeters,
        'remarks': remarks,
      },
    );

    return Attendance.fromJson(response);
  }

  Future<Attendance> approve({
    required String attendanceId,
    String? remarks,
  }) async {
    final response = await _apiClient.put(
      '/Attendances/$attendanceId/approve',
      body: <String, dynamic>{
        'remarks': remarks,
      },
    );

    return Attendance.fromJson(response);
  }

  Future<Attendance> overrideAttendance({
    required String attendanceId,
    required DateTime checkInAtUtc,
    DateTime? checkOutAtUtc,
    required AttendanceStatus status,
    required String reason,
    String? remarks,
  }) async {
    final response = await _apiClient.put(
      '/Attendances/$attendanceId/override',
      body: <String, dynamic>{
        'checkInAtUtc':
        checkInAtUtc.toUtc().toIso8601String(),
        'checkOutAtUtc':
        checkOutAtUtc?.toUtc().toIso8601String(),
        'status': _statusName(status),
        'reason': reason,
        'remarks': remarks,
      },
    );

    return Attendance.fromJson(response);
  }

  String _dateOnly(DateTime date) {
    return date.toIso8601String().split('T').first;
  }

  String _sourceName(AttendanceSource source) {
    switch (source) {
      case AttendanceSource.mobileGps:
        return 'MobileGps';
      case AttendanceSource.biometric:
        return 'Biometric';
      case AttendanceSource.manual:
        return 'Manual';
      case AttendanceSource.imported:
        return 'Imported';
    }
  }

  String _statusName(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.halfDay:
        return 'HalfDay';
      case AttendanceStatus.leave:
        return 'Leave';
      case AttendanceStatus.holiday:
        return 'Holiday';
    }
  }
}