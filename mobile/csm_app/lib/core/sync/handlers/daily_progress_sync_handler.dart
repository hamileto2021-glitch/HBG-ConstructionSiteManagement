import 'package:flutter/foundation.dart';

import '../../../features/admin/projects/data/repositories/daily_progress_repository.dart';
import '../sync_queue_service.dart';

class DailyProgressSyncHandler {
  DailyProgressSyncHandler({
    required this.repository,
  });

  final DailyProgressRepository repository;

  Future<void> handle(SyncQueueItem item) async {
    debugPrint('SYNC DAILY PROGRESS START');
    debugPrint(item.payload.toString());

    switch (item.operation) {
      case SyncOperation.create:
        await repository.syncCreate(item.payload);
        debugPrint('SYNC DAILY PROGRESS SUCCESS');
        break;

      case SyncOperation.update:
        await repository.syncUpdate(
          item.entityId,
          item.payload,
        );
        break;

      case SyncOperation.delete:
        await repository.syncDelete(item.entityId);
        break;
    }
  }
}