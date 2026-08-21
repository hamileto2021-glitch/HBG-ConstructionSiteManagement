import 'sync_operation_handler.dart';
import 'sync_queue_service.dart';

class SyncResult {
  const SyncResult({
    required this.processed,
    required this.failed,
  });

  final int processed;
  final int failed;
}

class SyncEngine {
  SyncEngine({
    required this._queue,
    required this._handler,
  });

  final SyncQueueStore _queue;
  final SyncOperationHandler _handler;

  bool _isRunning = false;

  bool get isRunning => _isRunning;

  Future<SyncResult> synchronize({
    int batchSize = 20,
  }) async {
    if (_isRunning) {
      return const SyncResult(
        processed: 0,
        failed: 0,
      );
    }

    _isRunning = true;

    var processed = 0;
    var failed = 0;

    try {
      final items = await _queue.getPending(
        limit: batchSize,
      );

      for (final item in items) {
        try {
          await _handler.handle(item);
          await _queue.remove(item.id);
          processed++;
        } catch (error) {
          await _queue.markRetry(
            id: item.id,
            error: error.toString(),
          );
          failed++;
        }
      }
    } finally {
      _isRunning = false;
    }

    return SyncResult(
      processed: processed,
      failed: failed,
    );
  }
}
