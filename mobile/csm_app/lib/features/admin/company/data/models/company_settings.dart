class CompanySettings {
  const CompanySettings({
    required this.id,
    required this.name,
    required this.shortName,
    required this.registrationNumber,
    required this.taxNumber,
    required this.email,
    required this.phone,
    required this.website,
    required this.address,
    required this.city,
    required this.country,
    required this.currency,
    required this.timeZone,
    required this.fiscalYearStartMonth,

    // Business Hours
    required this.workStartTime,
    required this.workEndTime,
    required this.lunchBreakMinutes,

    // Attendance
    required this.lateGraceMinutes,
    required this.overtimeAfterHours,

    // Notifications
    required this.notifyLowInventory,
    required this.notifyMaintenance,
    required this.notifyPermitExpiry,
    required this.notifyDailyProgress,

    // Weekend
    required this.weekendDays,

    required this.logoUrl,
    required this.primaryColor,
    required this.secondaryColor,

    required this.defaultLanguage,
    required this.dateFormat,
    required this.numberFormat,
    required this.measurementUnit,

    required this.projectPrefix,
    required this.purchaseOrderPrefix,
    required this.stockIssuePrefix,
    required this.employeePrefix,
  });

  final String id;
  final String name;
  final String shortName;
  final String registrationNumber;
  final String taxNumber;
  final String email;
  final String phone;
  final String website;
  final String address;
  final String city;
  final String country;
  final String currency;
  final String timeZone;
  final int fiscalYearStartMonth;

  // Business Hours
  final String workStartTime;
  final String workEndTime;
  final int lunchBreakMinutes;

  // Attendance
  final int lateGraceMinutes;
  final double overtimeAfterHours;

  // Notifications
  final bool notifyLowInventory;
  final bool notifyMaintenance;
  final bool notifyPermitExpiry;
  final bool notifyDailyProgress;

  // Weekend
  final String weekendDays;

  final String? logoUrl;

  final String primaryColor;
  final String secondaryColor;

  final String defaultLanguage;
  final String dateFormat;
  final String numberFormat;
  final String measurementUnit;

  final String projectPrefix;
  final String purchaseOrderPrefix;
  final String stockIssuePrefix;
  final String employeePrefix;

  factory CompanySettings.fromJson(
      Map<String, dynamic> json,
      ) {
    return CompanySettings(
      id: json['id'],
      name: json['name'] ?? '',
      shortName: json['shortName'] ?? '',
      registrationNumber:
      json['registrationNumber'] ?? '',
      taxNumber: json['taxNumber'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      website: json['website'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      country: json['country'] ?? '',
      currency: json['currency'] ?? 'ETB',
      timeZone:
      json['timeZone'] ??
          'Africa/Addis_Ababa',
      fiscalYearStartMonth:
      json['fiscalYearStartMonth'] ?? 1,

      workStartTime:
      json['workStartTime'] ?? '08:00',
      workEndTime:
      json['workEndTime'] ?? '17:00',
      lunchBreakMinutes:
      json['lunchBreakMinutes'] ?? 60,

      lateGraceMinutes:
      json['lateGraceMinutes'] ?? 15,
      overtimeAfterHours:
      (json['overtimeAfterHours'] ?? 8)
          .toDouble(),

      notifyLowInventory:
      json['notifyLowInventory'] ?? true,
      notifyMaintenance:
      json['notifyMaintenance'] ?? true,
      notifyPermitExpiry:
      json['notifyPermitExpiry'] ?? true,
      notifyDailyProgress:
      json['notifyDailyProgress'] ?? true,

      weekendDays:
      json['weekendDays'] ??
          'Saturday,Sunday',

      logoUrl: json['logoUrl'],

      primaryColor: json['primaryColor'] ?? '#156082',
      secondaryColor: json['secondaryColor'] ?? '#E6F4F1',

      defaultLanguage: json['defaultLanguage'] ?? 'en',
      dateFormat: json['dateFormat'] ?? 'dd/MM/yyyy',
      numberFormat: json['numberFormat'] ?? 'en-ET',
      measurementUnit: json['measurementUnit'] ?? 'Metric',

      projectPrefix: json['projectPrefix'] ?? 'PRJ',
      purchaseOrderPrefix: json['purchaseOrderPrefix'] ?? 'PO',
      stockIssuePrefix: json['stockIssuePrefix'] ?? 'SI',
      employeePrefix: json['employeePrefix'] ?? 'EMP',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'shortName': shortName,
    'registrationNumber':
    registrationNumber,
    'taxNumber': taxNumber,
    'email': email,
    'phone': phone,
    'website': website,
    'address': address,
    'city': city,
    'country': country,
    'currency': currency,
    'timeZone': timeZone,
    'fiscalYearStartMonth':
    fiscalYearStartMonth,

    'workStartTime': workStartTime,
    'workEndTime': workEndTime,
    'lunchBreakMinutes':
    lunchBreakMinutes,

    'lateGraceMinutes':
    lateGraceMinutes,
    'overtimeAfterHours':
    overtimeAfterHours,

    'notifyLowInventory':
    notifyLowInventory,
    'notifyMaintenance':
    notifyMaintenance,
    'notifyPermitExpiry':
    notifyPermitExpiry,
    'notifyDailyProgress':
    notifyDailyProgress,

    'weekendDays': weekendDays,

    'logoUrl': logoUrl,

    'primaryColor': primaryColor,
    'secondaryColor': secondaryColor,

    'defaultLanguage': defaultLanguage,
    'dateFormat': dateFormat,
    'numberFormat': numberFormat,
    'measurementUnit': measurementUnit,

    'projectPrefix': projectPrefix,
    'purchaseOrderPrefix': purchaseOrderPrefix,
    'stockIssuePrefix': stockIssuePrefix,
    'employeePrefix': employeePrefix,
  };
}