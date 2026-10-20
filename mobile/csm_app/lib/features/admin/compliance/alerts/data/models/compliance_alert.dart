class ComplianceAlert {
  final String permitId;
  final String permitNumber;
  final String siteName;
  final String permitHolder;
  final DateTime expiryDate;
  final int daysRemaining;
  final bool isExpired;

  ComplianceAlert({
    required this.permitId,
    required this.permitNumber,
    required this.siteName,
    required this.permitHolder,
    required this.expiryDate,
    required this.daysRemaining,
    required this.isExpired,
  });

  factory ComplianceAlert.fromJson(Map<String, dynamic> json) {
    return ComplianceAlert(
      permitId: json['permitId'],
      permitNumber: json['permitNumber'],
      siteName: json['siteName'],
      permitHolder: json['permitHolder'],
      expiryDate: DateTime.parse(json['expiryDate']),
      daysRemaining: json['daysRemaining'],
      isExpired: json['isExpired'],
    );
  }
}