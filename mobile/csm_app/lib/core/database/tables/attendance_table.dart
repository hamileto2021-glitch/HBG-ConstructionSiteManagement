import 'package:drift/drift.dart';

class AttendanceTable extends Table {
  TextColumn get id => text()();

  TextColumn get employeeId => text()();

  TextColumn get employeeName => text()();

  DateTimeColumn get attendanceDate => dateTime()();

  TextColumn get status => text()();

  TextColumn get checkIn => text().nullable()();

  TextColumn get checkOut => text().nullable()();

  RealColumn get latitude => real().nullable()();

  RealColumn get longitude => real().nullable()();

  BoolColumn get synced =>
      boolean().withDefault(
        const Constant(false),
      )();

  DateTimeColumn get updatedAt =>
      dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}