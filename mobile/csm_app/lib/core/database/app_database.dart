

import 'package:drift/drift.dart';


import 'database_connection.dart';

import 'dao/attendance_local_repository.dart';
import 'dao/sync_queue_dao.dart';
import 'tables/sync_queue_table.dart';
import 'tables/attendance_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    SyncQueue,
    AttendanceTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openDatabaseConnection());

  late final syncQueueDao = SyncQueueDao(this);
  late final attendanceLocal =
  AttendanceLocalRepository(this);

  @override
  int get schemaVersion => 1;
}

