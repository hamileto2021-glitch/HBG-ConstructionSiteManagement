import 'package:flutter/foundation.dart';
import 'package:csm_app/features/admin/projects/data/repositories/project_delay_repository.dart';

import '../sync_queue_service.dart';

class ProjectDelaySyncHandler {
  ProjectDelaySyncHandler({
    required this.repository,
  });

  final ProjectDelayRepository repository;

  Future<void> handle(SyncQueueItem item) async {
    switch (item.operation) {
      case SyncOperation.create:
        final payload = Map<String, dynamic>.from(item.payload);

        debugPrint('PROJECT DELAY SYNC PAYLOAD: $payload');

        await repository.syncCreate(payload);
        break;

      case SyncOperation.update:
        break;

      case SyncOperation.delete:
        break;
    }
  }
}