class EquipmentAssignment {
  const EquipmentAssignment({
    required this.id,
    required this.companyId,
    required this.assignmentNumber,
    required this.equipmentId,
    required this.equipmentCode,
    required this.equipmentName,
    required this.constructionSiteId,
    required this.constructionSiteName,
    this.projectId,
    this.projectName,
    required this.assignedAtUtc,
    this.releasedAtUtc,
    this.meterReadingAtAssignment,
    this.meterReadingAtRelease,
    this.remarks,
    required this.createdAtUtc,
    this.updatedAtUtc,
  });

  final String id;
  final String companyId;
  final String assignmentNumber;
  final String equipmentId;
  final String equipmentCode;
  final String equipmentName;
  final String constructionSiteId;
  final String constructionSiteName;
  final String? projectId;
  final String? projectName;
  final DateTime assignedAtUtc;
  final DateTime? releasedAtUtc;
  final double? meterReadingAtAssignment;
  final double? meterReadingAtRelease;
  final String? remarks;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;

  bool get isActive => releasedAtUtc == null;

  factory EquipmentAssignment.fromJson(
    Map<String, dynamic> json,
  ) {
    return EquipmentAssignment(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      assignmentNumber: json['assignmentNumber'] as String,
      equipmentId: json['equipmentId'] as String,
      equipmentCode: json['equipmentCode'] as String,
      equipmentName: json['equipmentName'] as String,
      constructionSiteId: json['constructionSiteId'] as String,
      constructionSiteName:
          json['constructionSiteName'] as String,
      projectId: json['projectId'] as String?,
      projectName: json['projectName'] as String?,
      assignedAtUtc: DateTime.parse(
        json['assignedAtUtc'] as String,
      ),
      releasedAtUtc: json['releasedAtUtc'] == null
          ? null
          : DateTime.parse(
              json['releasedAtUtc'] as String,
            ),
      meterReadingAtAssignment:
          (json['meterReadingAtAssignment'] as num?)?.toDouble(),
      meterReadingAtRelease:
          (json['meterReadingAtRelease'] as num?)?.toDouble(),
      remarks: json['remarks'] as String?,
      createdAtUtc: DateTime.parse(
        json['createdAtUtc'] as String,
      ),
      updatedAtUtc: json['updatedAtUtc'] == null
          ? null
          : DateTime.parse(
              json['updatedAtUtc'] as String,
            ),
    );
  }
}
