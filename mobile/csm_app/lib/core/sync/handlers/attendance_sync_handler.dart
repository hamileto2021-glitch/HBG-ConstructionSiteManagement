import '../../../features/admin/hrm/data/models/attendance/attendance.dart';
import '../../../features/admin/hrm/data/repositories/attendance_repository.dart';
import '../sync_queue_service.dart';

class AttendanceSyncHandler {
  AttendanceSyncHandler({
    required this.repository,
  });

  final AttendanceRepository repository;

  Future<void> handle(SyncQueueItem item) async {
    switch (item.operation) {
      case SyncOperation.create:
        final payload = item.payload;

        await repository.checkIn(
          employeeId: payload['employeeId'] as String,
          constructionSiteId: payload['constructionSiteId'] as String,
          shiftId: payload['shiftId'] as String?,
          checkInAtUtc: DateTime.parse(
            payload['checkInAtUtc'] as String,
          ),
          latitude: (payload['latitude'] as num?)?.toDouble(),
          longitude: (payload['longitude'] as num?)?.toDouble(),
          accuracyMeters:
          (payload['accuracyMeters'] as num?)?.toDouble(),
          source: AttendanceSource.values.firstWhere(
                (e) => e.name == payload['source'],
          ),
          biometricReference:
          payload['biometricReference'] as String?,
          remarks: payload['remarks'] as String?,
        );
        break;

      case SyncOperation.update:
      case SyncOperation.delete:
      // Reserved for future implementation.
        break;
    }
  }
}