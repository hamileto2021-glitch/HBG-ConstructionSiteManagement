enum TimesheetStatus {
  draft,
  submitted,
  approved,
  rejected,
  cancelled,
}

class Timesheet {
  const Timesheet({
    required this.id,
    required this.companyId,
    required this.employeeId,
    required this.employeeNumber,
    required this.employeeName,
    required this.periodStartDate,
    required this.periodEndDate,
    required this.regularHours,
    required this.overtimeHours,
    required this.totalHours,
    required this.status,
    this.submittedBy,
    this.submittedAtUtc,
    this.approvedBy,
    this.approvedAtUtc,
    this.approvalRemarks,
    this.remarks,
    required this.createdAtUtc,
  });

  final String id;
  final String companyId;
  final String employeeId;
  final String employeeNumber;
  final String employeeName;
  final DateTime periodStartDate;
  final DateTime periodEndDate;
  final double regularHours;
  final double overtimeHours;
  final double totalHours;
  final TimesheetStatus status;
  final String? submittedBy;
  final DateTime? submittedAtUtc;
  final String? approvedBy;
  final DateTime? approvedAtUtc;
  final String? approvalRemarks;
  final String? remarks;
  final DateTime createdAtUtc;

  factory Timesheet.fromJson(
    Map<String, dynamic> json,
  ) {
    return Timesheet(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      employeeId: json['employeeId'] as String,
      employeeNumber: json['employeeNumber'] as String,
      employeeName: json['employeeName'] as String,
      periodStartDate: DateTime.parse(
        json['periodStartDate'] as String,
      ),
      periodEndDate: DateTime.parse(
        json['periodEndDate'] as String,
      ),
      regularHours:
          (json['regularHours'] as num).toDouble(),
      overtimeHours:
          (json['overtimeHours'] as num).toDouble(),
      totalHours:
          (json['totalHours'] as num).toDouble(),
      status: _parseStatus(json['status']),
      submittedBy:
          json['submittedBy'] as String?,
      submittedAtUtc:
          _parseDate(json['submittedAtUtc']),
      approvedBy:
          json['approvedBy'] as String?,
      approvedAtUtc:
          _parseDate(json['approvedAtUtc']),
      approvalRemarks:
          json['approvalRemarks'] as String?,
      remarks:
          json['remarks'] as String?,
      createdAtUtc: DateTime.parse(
        json['createdAtUtc'] as String,
      ),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }

  static TimesheetStatus _parseStatus(dynamic value) {
    final name = value.toString().split('.').last;

    switch (name) {
      case 'draft':
      case 'Draft':
        return TimesheetStatus.draft;
      case 'submitted':
      case 'Submitted':
        return TimesheetStatus.submitted;
      case 'approved':
      case 'Approved':
        return TimesheetStatus.approved;
      case 'rejected':
      case 'Rejected':
        return TimesheetStatus.rejected;
      case 'cancelled':
      case 'Cancelled':
        return TimesheetStatus.cancelled;
      default:
        throw FormatException(
          'Unknown timesheet status: $value',
        );
    }
  }
}
