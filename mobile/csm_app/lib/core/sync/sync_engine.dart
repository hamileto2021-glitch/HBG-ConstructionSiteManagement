import 'sync_operation_handler.dart';
import 'sync_queue_service.dart';
import 'package:flutter/foundation.dart';


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
    required SyncQueueStore queue,
    required SyncOperationHandler handler,
  }) : _queue = queue,
       _handler = handler;

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
          final message = error.toString();

          debugPrint('========================');
          debugPrint('SYNC FAILED');
          debugPrint('Entity: ${item.entityType}');
          debugPrint('ID: ${item.id}');
          debugPrint('Error: $message');
          debugPrint('Payload: ${item.payload}');
          debugPrint('========================');

          // Attendance duplicate
          final isAttendanceDuplicate =
          message.contains('already been recorded');

          // Daily Progress duplicate
          final isDailyProgressDuplicate =
          message.contains('daily progress log already exists');

          if (isAttendanceDuplicate || isDailyProgressDuplicate) {
            debugPrint('Duplicate detected -> removing from queue');
            await _queue.remove(item.id);
            processed++;
            continue;
          }

          await _queue.markRetry(
            id: item.id,
            error: message,
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
