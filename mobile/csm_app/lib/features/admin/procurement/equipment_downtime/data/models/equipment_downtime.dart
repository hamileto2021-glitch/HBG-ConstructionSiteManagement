class EquipmentDowntime {
  const EquipmentDowntime({
    required this.id,
    required this.companyId,
    required this.equipmentId,
    required this.equipmentCode,
    required this.equipmentName,
    this.constructionSiteId,
    this.constructionSiteCode,
    this.constructionSiteName,
    required this.startedAtUtc,
    this.endedAtUtc,
    required this.downtimeNumber,
    required this.reason,
    this.resolution,
    this.durationHours,
    required this.createdAtUtc,
    this.updatedAtUtc,
  });

  final String id;
  final String companyId;
  final String equipmentId;
  final String equipmentCode;
  final String equipmentName;
  final String? constructionSiteId;
  final String? constructionSiteCode;
  final String? constructionSiteName;
  final DateTime startedAtUtc;
  final DateTime? endedAtUtc;
  final String downtimeNumber;
  final String reason;
  final String? resolution;
  final double? durationHours;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;

  bool get isOpen => endedAtUtc == null;

  factory EquipmentDowntime.fromJson(
    Map<String, dynamic> json,
  ) {
    return EquipmentDowntime(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      equipmentId: json['equipmentId'] as String,
      equipmentCode: json['equipmentCode'] as String,
      equipmentName: json['equipmentName'] as String,
      constructionSiteId:
          json['constructionSiteId'] as String?,
      constructionSiteCode:
          json['constructionSiteCode'] as String?,
      constructionSiteName:
          json['constructionSiteName'] as String?,
      startedAtUtc:
          DateTime.parse(json['startedAtUtc'] as String),
      endedAtUtc: json['endedAtUtc'] == null
          ? null
          : DateTime.parse(json['endedAtUtc'] as String),
      downtimeNumber:
          json['downtimeNumber'] as String,
      reason: json['reason'] as String,
      resolution: json['resolution'] as String?,
      durationHours:
          (json['durationHours'] as num?)?.toDouble(),
      createdAtUtc:
          DateTime.parse(json['createdAtUtc'] as String),
      updatedAtUtc: json['updatedAtUtc'] == null
          ? null
          : DateTime.parse(json['updatedAtUtc'] as String),
    );
  }
}
