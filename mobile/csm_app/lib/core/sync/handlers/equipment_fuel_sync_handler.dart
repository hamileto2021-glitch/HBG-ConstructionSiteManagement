import 'package:flutter/foundation.dart';

import 'package:csm_app/features/admin/procurement/equipment_fuel_logs/data/repositories/equipment_fuel_log_repository.dart';

import '../sync_queue_service.dart';

class EquipmentFuelSyncHandler {
  EquipmentFuelSyncHandler({
    required this.repository,
  });

  final EquipmentFuelLogRepository repository;

  Future<void> handle(SyncQueueItem item) async {
    switch (item.operation) {
      case SyncOperation.create:
        final payload = Map<String, dynamic>.from(item.payload);

        debugPrint('FUEL SYNC PAYLOAD: $payload');

        await repository.syncCreate(payload);
        break;

      case SyncOperation.update:
        break;

      case SyncOperation.delete:
        break;
    }
  }
}