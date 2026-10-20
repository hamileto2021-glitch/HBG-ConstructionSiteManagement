import 'package:flutter/foundation.dart';

import '../../../features/admin/equipment/data/repositories/equipment_hour_repository.dart';
import '../sync_queue_service.dart';

class EquipmentHourSyncHandler {
  EquipmentHourSyncHandler({
    required this.repository,
  });

  final EquipmentHourRepository repository;

  Future<void> handle(SyncQueueItem item) async {
    switch (item.operation) {
      case SyncOperation.create:
        final payload = Map<String, dynamic>.from(item.payload);

        // Convert legacy queued records
        if (payload.containsKey('projectId')) {
          payload['siteId'] = payload.remove('projectId');
        }

        // Ensure required fields exist
        payload['activity'] ??= 'Equipment Operation';

        final operator =
        (payload['operatorName'] ?? '').toString().trim();

        payload['operatorName'] =
        operator.isEmpty ? 'Unknown Operator' : operator;

        debugPrint('SYNC PAYLOAD: $payload');

        await repository.syncCreate(payload);
        break;

      case SyncOperation.update:
        await repository.syncUpdate(item.entityId, item.payload);
        break;

      case SyncOperation.delete:
        await repository.syncDelete(item.entityId);
        break;
    }
  }
}