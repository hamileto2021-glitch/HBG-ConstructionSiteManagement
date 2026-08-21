import 'sync_queue_service.dart';

abstract interface class SyncOperationHandler {
  Future<void> handle(SyncQueueItem item);
}
