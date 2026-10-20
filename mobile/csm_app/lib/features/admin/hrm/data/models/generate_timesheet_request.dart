class GenerateTimesheetRequest {
  const GenerateTimesheetRequest({
    required this.employeeId,
    required this.year,
    required this.month,
  });

  final String employeeId;
  final int year;
  final int month;

  Map<String, dynamic> toJson() => {
    'employeeId': employeeId,
    'year': year,
    'month': month,
  };
}