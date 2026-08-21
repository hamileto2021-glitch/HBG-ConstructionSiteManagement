import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:csm_app/core/sync/sync_engine.dart';
import 'package:csm_app/core/sync/sync_operation_handler.dart';
import 'package:csm_app/core/sync/sync_queue_service.dart';

class FakeQueue implements SyncQueueStore {
  final List<SyncQueueItem> items = [];
  final List<String> removedIds = [];
  final Map<String, String> retryErrors = {};

  @override
  Future<String> enqueue({
    required String entityType,
    required String entityId,
    required SyncOperation operation,
    required Map<String, dynamic> payload,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<SyncQueueItem>> getPending({
    int? limit,
  }) async {
    if (limit == null || items.length <= limit) {
      return List<SyncQueueItem>.from(items);
    }

    return items.take(limit).toList();
  }

  @override
  Future<void> markRetry({
    required String id,
    required String error,
  }) async {
    retryErrors[id] = error;
  }

  @override
  Future<void> remove(String id) async {
    removedIds.add(id);
    items.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> clear() async {
    items.clear();
  }
}

class FakeHandler implements SyncOperationHandler {
  FakeHandler({
    this.shouldFail = false,
  });

  final bool shouldFail;

  int handledCount = 0;

  @override
  Future<void> handle(SyncQueueItem item) async {
    handledCount++;

    if (shouldFail) {
      throw Exception('Sync failed');
    }
  }
}

SyncQueueItem createItem(String id) {
  return SyncQueueItem(
    id: id,
    entityType: 'TestEntity',
    entityId: id,
    operation: SyncOperation.create,
    payload: <String, dynamic>{
      'name': 'Test',
    },
    createdAtUtc: DateTime.utc(2026, 1, 1),
    retryCount: 0,
  );
}

void main() {
  group('SyncEngine', () {
    test('removes successfully processed operations', () async {
      final queue = FakeQueue()
        ..items.add(createItem('1'));

      final handler = FakeHandler();

      final engine = SyncEngine(
        queue: queue,
        handler: handler,
      );

      final result = await engine.synchronize();

      expect(result.processed, 1);
      expect(result.failed, 0);
      expect(handler.handledCount, 1);
      expect(queue.removedIds, contains('1'));
      expect(queue.retryErrors, isEmpty);
      expect(queue.items, isEmpty);
    });

    test('records retry when operation fails', () async {
      final queue = FakeQueue()
        ..items.add(createItem('1'));

      final handler = FakeHandler(
        shouldFail: true,
      );

      final engine = SyncEngine(
        queue: queue,
        handler: handler,
      );

      final result = await engine.synchronize();

      expect(result.processed, 0);
      expect(result.failed, 1);
      expect(handler.handledCount, 1);
      expect(queue.removedIds, isEmpty);
      expect(queue.retryErrors['1'], contains('Sync failed'));
      expect(queue.items, hasLength(1));
    });

    test('processes multiple operations', () async {
      final queue = FakeQueue()
        ..items.add(createItem('1'))
        ..items.add(createItem('2'))
        ..items.add(createItem('3'));

      final handler = FakeHandler();

      final engine = SyncEngine(
        queue: queue,
        handler: handler,
      );

      final result = await engine.synchronize();

      expect(result.processed, 3);
      expect(result.failed, 0);
      expect(handler.handledCount, 3);
      expect(queue.items, isEmpty);
    });

    test('does not start a second synchronization while running',
        () async {
      final queue = FakeQueue()
        ..items.add(createItem('1'));

      final handler = BlockingHandler();

      final engine = SyncEngine(
        queue: queue,
        handler: handler,
      );

      final firstSync = engine.synchronize();

      await handler.started.future;

      final secondResult = await engine.synchronize();

      expect(secondResult.processed, 0);
      expect(secondResult.failed, 0);
      expect(engine.isRunning, isTrue);

      handler.complete();

      final firstResult = await firstSync;

      expect(firstResult.processed, 1);
      expect(firstResult.failed, 0);
      expect(engine.isRunning, isFalse);
    });
  });
}

class BlockingHandler implements SyncOperationHandler {
  final Completer<void> started = Completer<void>();
  final Completer<void> _release = Completer<void>();

  @override
  Future<void> handle(SyncQueueItem item) async {
    if (!started.isCompleted) {
      started.complete();
    }

    await _release.future;
  }

  void complete() {
    if (!_release.isCompleted) {
      _release.complete();
    }
  }
}

