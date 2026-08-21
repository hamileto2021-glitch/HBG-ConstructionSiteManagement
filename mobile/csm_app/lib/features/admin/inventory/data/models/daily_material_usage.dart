class DailyMaterialUsage {
  const DailyMaterialUsage({
    required this.id,
    required this.constructionSiteId,
    required this.constructionSiteName,
    required this.materialId,
    required this.materialCode,
    required this.materialName,
    required this.dailyProgressLogId,
    required this.loggedByUserId,
    required this.loggedByUserName,
    required this.date,
    required this.quantityIssued,
    required this.quantityUsed,
    required this.quantityReturned,
    required this.quantityVariance,
    required this.requiresSupervisorReview,
    required this.unit,
    this.notes,
  });

  final String id;
  final String constructionSiteId;
  final String constructionSiteName;
  final String materialId;
  final String materialCode;
  final String materialName;
  final String dailyProgressLogId;
  final String loggedByUserId;
  final String loggedByUserName;
  final DateTime date;
  final double quantityIssued;
  final double quantityUsed;
  final double quantityReturned;
  final double quantityVariance;
  final bool requiresSupervisorReview;
  final String unit;
  final String? notes;

  factory DailyMaterialUsage.fromJson(
    Map<String, dynamic> json,
  ) {
    return DailyMaterialUsage(
      id: json['id'] as String,
      constructionSiteId:
          json['constructionSiteId'] as String,
      constructionSiteName:
          json['constructionSiteName'] as String? ?? '',
      materialId: json['materialId'] as String,
      materialCode:
          json['materialCode'] as String? ?? '',
      materialName:
          json['materialName'] as String? ?? '',
      dailyProgressLogId:
          json['dailyProgressLogId'] as String,
      loggedByUserId:
          json['loggedByUserId'] as String,
      loggedByUserName:
          json['loggedByUserName'] as String? ?? '',
      date: DateTime.parse(
        json['date'] as String,
      ),
      quantityIssued:
          (json['quantityIssued'] as num).toDouble(),
      quantityUsed:
          (json['quantityUsed'] as num).toDouble(),
      quantityReturned:
          (json['quantityReturned'] as num).toDouble(),
      quantityVariance:
          (json['quantityVariance'] as num).toDouble(),
      requiresSupervisorReview:
          json['requiresSupervisorReview'] as bool,
      unit: json['unit'] as String? ?? '',
      notes: json['notes'] as String?,
    );
  }
}
class CreateDailyMaterialUsageRequest {
  const CreateDailyMaterialUsageRequest({
    required this.constructionSiteId,
    required this.materialId,
    required this.dailyProgressLogId,
    required this.date,
    required this.quantityIssued,
    required this.quantityUsed,
    required this.quantityReturned,
    required this.unit,
    this.notes,
  });

  final String constructionSiteId;
  final String materialId;
  final String dailyProgressLogId;
  final DateTime date;
  final double quantityIssued;
  final double quantityUsed;
  final double quantityReturned;
  final String unit;
  final String? notes;

  Map<String, dynamic> toJson() {
    return {
      'constructionSiteId': constructionSiteId,
      'materialId': materialId,
      'dailyProgressLogId': dailyProgressLogId,
      'date': date.toIso8601String().split('T').first,
      'quantityIssued': quantityIssued,
      'quantityUsed': quantityUsed,
      'quantityReturned': quantityReturned,
      'unit': unit,
      'notes': notes,
    };
  }
}
