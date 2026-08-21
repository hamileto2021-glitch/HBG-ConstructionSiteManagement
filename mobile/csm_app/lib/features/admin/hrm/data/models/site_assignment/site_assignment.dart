enum SiteAssignmentStatus {
  active,
  inactive,
}

class SiteAssignment {
  const SiteAssignment({
    required this.id,
    required this.companyId,
    required this.employeeId,
    required this.employeeNumber,
    required this.employeeName,
    required this.constructionSiteId,
    required this.siteName,
    required this.startDate,
    this.endDate,
    this.roleAtSite,
    required this.isPrimaryAssignment,
    this.remarks,
    required this.isActive,
    required this.createdAtUtc,
  });

  final String id;
  final String companyId;
  final String employeeId;
  final String employeeNumber;
  final String employeeName;
  final String constructionSiteId;
  final String siteName;
  final DateTime startDate;
  final DateTime? endDate;
  final String? roleAtSite;
  final bool isPrimaryAssignment;
  final String? remarks;
  final bool isActive;
  final DateTime createdAtUtc;

  SiteAssignmentStatus get status =>
      isActive
          ? SiteAssignmentStatus.active
          : SiteAssignmentStatus.inactive;

  factory SiteAssignment.fromJson(
    Map<String, dynamic> json,
  ) {
    return SiteAssignment(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      employeeId: json['employeeId'] as String,
      employeeNumber: json['employeeNumber'] as String,
      employeeName: json['employeeName'] as String,
      constructionSiteId:
          json['constructionSiteId'] as String,
      siteName: json['siteName'] as String,
      startDate: DateTime.parse(
        json['startDate'] as String,
      ),
      endDate: _parseDate(
        json['endDate'],
      ),
      roleAtSite: json['roleAtSite'] as String?,
      isPrimaryAssignment:
          json['isPrimaryAssignment'] as bool,
      remarks: json['remarks'] as String?,
      isActive: json['isActive'] as bool,
      createdAtUtc: DateTime.parse(
        json['createdAtUtc'] as String,
      ),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.parse(value.toString());
  }
}
