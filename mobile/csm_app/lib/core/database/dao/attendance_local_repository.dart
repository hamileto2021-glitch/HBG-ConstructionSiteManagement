import 'package:drift/drift.dart';

import '../app_database.dart';

class AttendanceLocalRepository {
  AttendanceLocalRepository(this.db);

  final AppDatabase db;

  Future<void> save({
    required String id,
    required String employeeId,
    required String employeeName,
    required DateTime attendanceDate,
    required String status,
    String? checkIn,
    String? checkOut,
    double? latitude,
    double? longitude,
  }) async {
    await db.into(db.attendanceTable).insertOnConflictUpdate(
      AttendanceTableCompanion(
        id: Value(id),
        employeeId: Value(employeeId),
        employeeName: Value(employeeName),
        attendanceDate: Value(attendanceDate),
        status: Value(status),
        checkIn: Value(checkIn),
        checkOut: Value(checkOut),
        latitude: Value(latitude),
        longitude: Value(longitude),
        synced: const Value(false),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<List<AttendanceTableData>> getUnsynced() {
    return (db.select(db.attendanceTable)
      ..where((t) => t.synced.equals(false)))
        .get();
  }

  Future<void> markSynced(String id) async {
    await (db.update(db.attendanceTable)
      ..where((t) => t.id.equals(id)))
        .write(
      const AttendanceTableCompanion(
        synced: Value(true),
      ),
    );
  }
}