import 'dart:convert';

import '../database/app_database.dart';

enum SyncOperation { create, update, delete }

class SyncQueueItem {
  const SyncQueueItem({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.createdAtUtc,
    required this.retryCount,
    this.lastError,
  });

  final String id;
  final String entityType;
  final String entityId;
  final SyncOperation operation;
  final Map<String, dynamic> payload;
  final DateTime createdAtUtc;
  final int retryCount;
  final String? lastError;
}

abstract interface class SyncQueueStore {
  Future<List<SyncQueueItem>> getPending({int? limit});
  Future<void> markRetry({
    required String id,
    required String error,
  });
  Future<void> remove(String id);
  Future<void> clear();
}

class SyncQueueService implements SyncQueueStore {
  SyncQueueService({AppDatabase? database})
      : _database = database ?? AppDatabase();

  final AppDatabase _database;

  @override
  Future<List<SyncQueueItem>> getPending({int? limit}) async {
    final rows = await _database.syncQueueDao.getPending();

    final items = rows.map((row) {
      return SyncQueueItem(
        id: row.id,
        entityType: row.entity,
        entityId: row.id,
        operation: switch (row.action.toUpperCase()) {
          'POST' => SyncOperation.create,
          'PUT' => SyncOperation.update,
          'DELETE' => SyncOperation.delete,
          _ => SyncOperation.create,
        },
        payload: Map<String, dynamic>.from(
          jsonDecode(row.payload) as Map,
        ),
        createdAtUtc: row.createdAt,
        retryCount: 0,
        lastError: null,
      );
    }).toList();

    return limit == null ? items : items.take(limit).toList();
  }

  @override
  Future<void> markRetry({
    required String id,
    required String error,
  }) async {
    // Keep pending until the next sync attempt.
  }

  @override
  Future<void> remove(String id) async {
    await _database.syncQueueDao.markSynced(id);
  }

  @override
  Future<void> clear() async {
    final rows = await _database.syncQueueDao.getPending();
    for (final row in rows) {
      await _database.syncQueueDao.markSynced(row.id);
    }
  }
}