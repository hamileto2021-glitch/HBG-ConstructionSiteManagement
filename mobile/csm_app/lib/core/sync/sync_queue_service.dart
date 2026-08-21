import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../database/local_database.dart';

enum SyncOperation {
  create,
  update,
  delete,
}

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
  Future<String> enqueue({
    required String entityType,
    required String entityId,
    required SyncOperation operation,
    required Map<String, dynamic> payload,
  });

  Future<List<SyncQueueItem>> getPending({
    int? limit,
  });

  Future<void> markRetry({
    required String id,
    required String error,
  });

  Future<void> remove(String id);

  Future<void> clear();
}

class SyncQueueService implements SyncQueueStore {
  SyncQueueService({
    LocalDatabase? database,
    Uuid? uuid,
  })  : _database = database ?? LocalDatabase.instance,
        _uuid = uuid ?? const Uuid();

  final LocalDatabase _database;
  final Uuid _uuid;

  @override
  Future<String> enqueue({
    required String entityType,
    required String entityId,
    required SyncOperation operation,
    required Map<String, dynamic> payload,
  }) async {
    final db = await _database.database;
    final id = _uuid.v4();

    await db.insert(
      'sync_queue',
      <String, dynamic>{
        'id': id,
        'entity_type': entityType,
        'entity_id': entityId,
        'operation': operation.name,
        'payload': jsonEncode(payload),
        'created_at_utc': DateTime.now().toUtc().toIso8601String(),
        'retry_count': 0,
        'last_error': null,
      },
    );

    return id;
  }

  @override
  Future<List<SyncQueueItem>> getPending({
    int? limit,
  }) async {
    final db = await _database.database;

    final rows = await db.query(
      'sync_queue',
      orderBy: 'created_at_utc ASC',
      limit: limit,
    );

    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> markRetry({
    required String id,
    required String error,
  }) async {
    final db = await _database.database;

    await db.rawUpdate(
      '''
      UPDATE sync_queue
      SET retry_count = retry_count + 1,
          last_error = ?
      WHERE id = ?
      ''',
      <Object?>[error, id],
    );
  }

  @override
  Future<void> remove(String id) async {
    final db = await _database.database;

    await db.delete(
      'sync_queue',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  @override
  Future<void> clear() async {
    final db = await _database.database;
    await db.delete('sync_queue');
  }

  SyncQueueItem _fromRow(Map<String, Object?> row) {
    return SyncQueueItem(
      id: row['id']! as String,
      entityType: row['entity_type']! as String,
      entityId: row['entity_id']! as String,
      operation: SyncOperation.values.byName(
        row['operation']! as String,
      ),
      payload: Map<String, dynamic>.from(
        jsonDecode(row['payload']! as String) as Map,
      ),
      createdAtUtc: DateTime.parse(
        row['created_at_utc']! as String,
      ),
      retryCount: row['retry_count']! as int,
      lastError: row['last_error'] as String?,
    );
  }
}
