enum AttendanceStatus {
  present,
  absent,
  late,
  halfDay,
  leave,
  holiday,
}

enum AttendanceSource {
  mobileGps,
  biometric,
  manual,
  imported,
}

class Attendance {
  const Attendance({
    required this.id,
    required this.companyId,
    required this.employeeId,
    required this.employeeNumber,
    required this.employeeName,
    required this.constructionSiteId,
    required this.siteName,
    this.shiftId,
    this.shiftCode,
    this.shiftName,
    required this.attendanceDate,
    this.checkInAtUtc,
    this.checkOutAtUtc,
    this.checkInLatitude,
    this.checkInLongitude,
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.checkInAccuracyMeters,
    this.checkOutAccuracyMeters,
    required this.isCheckInWithinGeofence,
    required this.isCheckOutWithinGeofence,
    required this.status,
    required this.source,
    required this.regularHours,
    required this.overtimeHours,
    this.biometricReference,
    required this.requiresApproval,
    required this.isApproved,
    this.approvedBy,
    this.approvedAtUtc,
    this.manualOverrideReason,
    this.remarks,
    required this.createdAtUtc,
  });

  final String id;
  final String companyId;
  final String employeeId;
  final String employeeNumber;
  final String employeeName;
  final String constructionSiteId;
  final String siteName;
  final String? shiftId;
  final String? shiftCode;
  final String? shiftName;
  final DateTime attendanceDate;
  final DateTime? checkInAtUtc;
  final DateTime? checkOutAtUtc;
  final double? checkInLatitude;
  final double? checkInLongitude;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final double? checkInAccuracyMeters;
  final double? checkOutAccuracyMeters;
  final bool isCheckInWithinGeofence;
  final bool isCheckOutWithinGeofence;
  final AttendanceStatus status;
  final AttendanceSource source;
  final double regularHours;
  final double overtimeHours;
  final String? biometricReference;
  final bool requiresApproval;
  final bool isApproved;
  final String? approvedBy;
  final DateTime? approvedAtUtc;
  final String? manualOverrideReason;
  final String? remarks;
  final DateTime createdAtUtc;

  factory Attendance.fromJson(
      Map<String, dynamic> json,
      ) {
    return Attendance(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      employeeId: json['employeeId'] as String,
      employeeNumber:
      json['employeeNumber'] as String,
      employeeName:
      json['employeeName'] as String,
      constructionSiteId:
      json['constructionSiteId'] as String,
      siteName: json['siteName'] as String,
      shiftId: json['shiftId'] as String?,
      shiftCode: json['shiftCode'] as String?,
      shiftName: json['shiftName'] as String?,
      attendanceDate: DateTime.parse(
        json['attendanceDate'] as String,
      ),
      checkInAtUtc:
      _parseDateTime(json['checkInAtUtc']),
      checkOutAtUtc:
      _parseDateTime(json['checkOutAtUtc']),
      checkInLatitude:
      (json['checkInLatitude'] as num?)?.toDouble(),
      checkInLongitude:
      (json['checkInLongitude'] as num?)?.toDouble(),
      checkOutLatitude:
      (json['checkOutLatitude'] as num?)?.toDouble(),
      checkOutLongitude:
      (json['checkOutLongitude'] as num?)?.toDouble(),
      checkInAccuracyMeters:
      (json['checkInAccuracyMeters'] as num?)
          ?.toDouble(),
      checkOutAccuracyMeters:
      (json['checkOutAccuracyMeters'] as num?)
          ?.toDouble(),
      isCheckInWithinGeofence:
      json['isCheckInWithinGeofence'] as bool,
      isCheckOutWithinGeofence:
      json['isCheckOutWithinGeofence'] as bool,
      status: _parseStatus(json['status']),
      source: _parseSource(json['source']),
      regularHours:
      (json['regularHours'] as num).toDouble(),
      overtimeHours:
      (json['overtimeHours'] as num).toDouble(),
      biometricReference:
      json['biometricReference'] as String?,
      requiresApproval:
      json['requiresApproval'] as bool,
      isApproved:
      json['isApproved'] as bool,
      approvedBy:
      json['approvedBy'] as String?,
      approvedAtUtc:
      _parseDateTime(json['approvedAtUtc']),
      manualOverrideReason:
      json['manualOverrideReason'] as String?,
      remarks: json['remarks'] as String?,
      createdAtUtc: DateTime.parse(
        json['createdAtUtc'] as String,
      ),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }

  static AttendanceStatus _parseStatus(dynamic value) {
    final name = value.toString().split('.').last;

    switch (name) {
      case 'present':
      case 'Present':
        return AttendanceStatus.present;

      case 'absent':
      case 'Absent':
        return AttendanceStatus.absent;

      case 'late':
      case 'Late':
        return AttendanceStatus.late;

      case 'halfDay':
      case 'HalfDay':
        return AttendanceStatus.halfDay;

      case 'leave':
      case 'Leave':
        return AttendanceStatus.leave;

      case 'holiday':
      case 'Holiday':
        return AttendanceStatus.holiday;

      default:
        throw FormatException(
          'Unknown attendance status: $value',
        );
    }
  }

  static AttendanceSource _parseSource(dynamic value) {
    final name = value.toString().split('.').last;

    switch (name) {
      case 'mobileGps':
      case 'MobileGps':
        return AttendanceSource.mobileGps;

      case 'biometric':
      case 'Biometric':
        return AttendanceSource.biometric;

      case 'manual':
      case 'Manual':
        return AttendanceSource.manual;

      case 'imported':
      case 'Imported':
        return AttendanceSource.imported;

      default:
        throw FormatException(
          'Unknown attendance source: $value',
        );
    }
  }
}