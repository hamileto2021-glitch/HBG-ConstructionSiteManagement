import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/sync_queue_table.dart';

part 'sync_queue_dao.g.dart';

@DriftAccessor(tables: [SyncQueue])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  Future<List<SyncQueueData>> getPending() {
    return (select(syncQueue)
      ..where((t) => t.synced.equals(false))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<void> enqueue({
    required String id,
    required String entity,
    required String action,
    required String payload,
  }) {
    return into(syncQueue).insert(
      SyncQueueCompanion.insert(
        id: id,
        entity: entity,
        action: action,
        payload: payload,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> markSynced(String id) {
    return (update(syncQueue)..where((t) => t.id.equals(id))).write(
      const SyncQueueCompanion(
        synced: Value(true),
      ),
    );
  }
}