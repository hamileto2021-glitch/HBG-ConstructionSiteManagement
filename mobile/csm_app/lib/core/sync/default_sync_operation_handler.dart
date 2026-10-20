import '../../features/admin/equipment/data/repositories/equipment_hour_repository.dart';
import '../../features/admin/hrm/data/repositories/attendance_repository.dart';
import '../../features/admin/projects/data/repositories/daily_progress_repository.dart';

import 'handlers/attendance_sync_handler.dart';
import 'handlers/daily_progress_sync_handler.dart';
import 'handlers/equipment_hour_sync_handler.dart';
import 'sync_operation_handler.dart';
import 'sync_queue_service.dart';
import 'package:csm_app/features/admin/procurement/equipment_fuel_logs/data/repositories/equipment_fuel_log_repository.dart';
import 'handlers/equipment_fuel_sync_handler.dart';
import 'package:csm_app/features/admin/projects/data/repositories/project_delay_repository.dart';
import 'handlers/project_delay_sync_handler.dart';




class DefaultSyncOperationHandler implements SyncOperationHandler {
  DefaultSyncOperationHandler({
    required AttendanceRepository attendanceRepository,
    required DailyProgressRepository dailyProgressRepository,
    required EquipmentHourRepository equipmentHourRepository,
    required EquipmentFuelLogRepository equipmentFuelRepository,
    required ProjectDelayRepository projectDelayRepository,
  })  : _attendance = AttendanceSyncHandler(
    repository: attendanceRepository,
  ),
        _dailyProgress = DailyProgressSyncHandler(
          repository: dailyProgressRepository,
        ),
        _equipmentHour = EquipmentHourSyncHandler(
          repository: equipmentHourRepository,
        ),
        _equipmentFuel = EquipmentFuelSyncHandler(
          repository: equipmentFuelRepository,
        ),
        _projectDelay = ProjectDelaySyncHandler(
          repository: projectDelayRepository,
        );

  final AttendanceSyncHandler _attendance;
  final DailyProgressSyncHandler _dailyProgress;
  final EquipmentHourSyncHandler _equipmentHour;
  final EquipmentFuelSyncHandler _equipmentFuel;
  final ProjectDelaySyncHandler _projectDelay;

  @override
  Future<void> handle(SyncQueueItem item) async {
    switch (item.entityType) {
      case 'Attendance':
        await _attendance.handle(item);
        break;

      case 'DailyProgress':
        await _dailyProgress.handle(item);
        break;

      case 'EquipmentHour':
        await _equipmentHour.handle(item);
        break;

      case 'EquipmentFuel':
        await _equipmentFuel.handle(item);
        break;

      case 'ProjectDelay':
        await _projectDelay.handle(item);
        break;

      default:
        throw UnsupportedError(
          'Unknown sync entity: ${item.entityType}',
        );
    }
  }
}