enum LeaveStatus {
  pending,
  approved,
  rejected,
  cancelled,
}

class Leave {
  const Leave({
    required this.id,
    required this.companyId,
    required this.employeeId,
    required this.employeeNumber,
    required this.employeeName,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.numberOfDays,
    this.reason,
    required this.status,
    this.reviewedBy,
    this.reviewedAtUtc,
    this.reviewRemarks,
    required this.createdAtUtc,
  });

  final String id;
  final String companyId;
  final String employeeId;
  final String employeeNumber;
  final String employeeName;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final double numberOfDays;
  final String? reason;
  final LeaveStatus status;
  final String? reviewedBy;
  final DateTime? reviewedAtUtc;
  final String? reviewRemarks;
  final DateTime createdAtUtc;

  factory Leave.fromJson(Map<String, dynamic> json) {
    return Leave(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      employeeId: json['employeeId'] as String,
      employeeNumber: json['employeeNumber'] as String,
      employeeName: json['employeeName'] as String,
      leaveType: json['leaveType'] as String,
      startDate: DateTime.parse(
        json['startDate'] as String,
      ),
      endDate: DateTime.parse(
        json['endDate'] as String,
      ),
      numberOfDays:
          (json['numberOfDays'] as num).toDouble(),
      reason: json['reason'] as String?,
      status: _parseStatus(json['status']),
      reviewedBy: json['reviewedBy'] as String?,
      reviewedAtUtc:
          _parseDateTime(json['reviewedAtUtc']),
      reviewRemarks:
          json['reviewRemarks'] as String?,
      createdAtUtc: DateTime.parse(
        json['createdAtUtc'] as String,
      ),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }

  static LeaveStatus _parseStatus(dynamic value) {
    if (value is num) {
      switch (value.toInt()) {
        case 1:
          return LeaveStatus.pending;
        case 2:
          return LeaveStatus.approved;
        case 3:
          return LeaveStatus.rejected;
        case 4:
          return LeaveStatus.cancelled;
      }
    }

    final name = value.toString().split('.').last;

    switch (name) {
      case 'pending':
      case 'Pending':
        return LeaveStatus.pending;

      case 'approved':
      case 'Approved':
        return LeaveStatus.approved;

      case 'rejected':
      case 'Rejected':
        return LeaveStatus.rejected;

      case 'cancelled':
      case 'Cancelled':
        return LeaveStatus.cancelled;

      default:
        throw FormatException(
          'Unknown leave status: $value',
        );
    }
  }
}
