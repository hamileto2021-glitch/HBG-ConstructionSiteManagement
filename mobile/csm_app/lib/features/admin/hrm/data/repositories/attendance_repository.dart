import '../../../../../core/network/api_client.dart';
import '../models/attendance/attendance.dart';

class AttendanceRepository {
  AttendanceRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

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
    final response = await _apiClient.post(
      '/Attendances/check-in',
      body: <String, dynamic>{
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
      },
    );

    return Attendance.fromJson(response);
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