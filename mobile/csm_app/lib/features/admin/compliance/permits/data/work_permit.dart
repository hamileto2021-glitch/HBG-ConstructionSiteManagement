class WorkPermit {
  const WorkPermit({
    required this.id,
    required this.companyId,
    required this.constructionSiteId,
    required this.constructionSiteName,
    this.projectId,
    required this.permitNumber,
    required this.permitType,
    required this.name,
    this.issuingAuthority,
    this.applicationDate,
    this.issueDate,
    this.expiryDate,
    required this.status,
    required this.expiryAlertDays,
    required this.issuedBy,
    this.conditions,
    this.notes,
    required this.createdAtUtc,
    this.updatedAtUtc,
  });

  final String id;
  final String companyId;
  final String constructionSiteId;
  final String constructionSiteName;
  final String? projectId;

  final String permitNumber;
  final String permitType;
  final String name;

  final String? issuingAuthority;
  final String issuedBy;

  final DateTime? applicationDate;
  final DateTime? issueDate;
  final DateTime? expiryDate;

  final String status;
  final int expiryAlertDays;

  final String? conditions;
  final String? notes;

  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;

  // ===== Enterprise Expiry Tracking =====

  int get daysRemaining {
    if (expiryDate == null) return 9999;

    final today = DateTime.now();
    final expiry = DateTime(
      expiryDate!.year,
      expiryDate!.month,
      expiryDate!.day,
    );

    return expiry
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
  }

  bool get isExpired => daysRemaining < 0;

  bool get isExpiringSoon =>
      !isExpired && daysRemaining <= expiryAlertDays;

  // ===== JSON =====

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    final text = value.toString();
    if (text.isEmpty) return null;

    return DateTime.tryParse(text);
  }
  static String _statusName(dynamic value) {
    final status = value?.toString() ?? 'Draft';

    switch (status) {
      case '1':
      case 'Draft':
        return 'Draft';

      case '2':
      case 'Pending':
        return 'Pending';

      case '3':
      case 'Active':
        return 'Active';

      case '4':
      case 'Expired':
        return 'Expired';

      case '5':
      case 'Suspended':
        return 'Suspended';

      case '6':
      case 'Revoked':
        return 'Revoked';

      case '7':
      case 'Closed':
        return 'Closed';

      default:
        return 'Draft';
    }
  }

  factory WorkPermit.fromJson(Map<String, dynamic> json) {
    return WorkPermit(
      id: (json['id'] ?? '').toString(),
      companyId: (json['companyId'] ?? '').toString(),
      constructionSiteId:
      (json['constructionSiteId'] ?? '').toString(),
      constructionSiteName:
      (json['constructionSiteName'] ?? '').toString(),
      projectId: json['projectId']?.toString(),

      permitNumber: (json['permitNumber'] ?? '').toString(),
      permitType: (json['permitType'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),

      issuingAuthority: json['issuingAuthority']?.toString(),

      applicationDate: _parseDate(json['applicationDate']),
      issueDate: _parseDate(json['issueDate']),
      expiryDate: _parseDate(json['expiryDate']),
      issuedBy: (json['issuedByName'] ??
          json['issuedBy'] ??
          '')
          .toString(),

      status: _statusName(json['status']),
      expiryAlertDays:
      (json['expiryAlertDays'] as num?)?.toInt() ?? 30,

      conditions: json['conditions']?.toString(),
      notes: json['notes']?.toString(),

      createdAtUtc:
      DateTime.tryParse((json['createdAtUtc'] ?? '').toString()) ??
          DateTime.now(),

      updatedAtUtc: _parseDate(json['updatedAtUtc']),
    );
  }
}