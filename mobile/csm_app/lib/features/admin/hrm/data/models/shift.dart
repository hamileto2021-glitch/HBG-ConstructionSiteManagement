enum ShiftStatus { active, inactive }

class Shift {
  const Shift({
    required this.id,
    required this.companyId,
    required this.code,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.gracePeriodMinutes,
    required this.standardHours,
    required this.isNightShift,
    required this.isActive,
    required this.createdAtUtc,
  });

  final String id;
  final String companyId;
  final String code;
  final String name;
  final String startTime;
  final String endTime;
  final int gracePeriodMinutes;
  final double standardHours;
  final bool isNightShift;
  final bool isActive;
  final DateTime createdAtUtc;

  ShiftStatus get status =>
      isActive ? ShiftStatus.active : ShiftStatus.inactive;

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      gracePeriodMinutes: json['gracePeriodMinutes'] as int,
      standardHours:
      (json['standardHours'] as num).toDouble(),
      isNightShift: json['isNightShift'] as bool,
      isActive: json['isActive'] as bool,
      createdAtUtc: DateTime.parse(
        json['createdAtUtc'] as String,
      ),
    );
  }
}