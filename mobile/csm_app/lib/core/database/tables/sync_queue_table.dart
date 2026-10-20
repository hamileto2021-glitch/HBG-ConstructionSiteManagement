import 'package:drift/drift.dart';

class SyncQueue extends Table {
  TextColumn get id => text()();

  TextColumn get entity => text()();

  TextColumn get action => text()();

  TextColumn get payload => text()();

  DateTimeColumn get createdAt =>
      dateTime()();

  BoolColumn get synced =>
      boolean().withDefault(
        const Constant(false),
      )();

  @override
  Set<Column> get primaryKey => {id};
}