class DailyProgressLog {
  const DailyProgressLog({
    required this.id,
    required this.companyId,
    required this.projectId,
    required this.logDate,
    this.weatherCondition,
    this.temperatureCelsius,
    required this.laborCount,
    required this.contractorLaborCount,
    required this.progressPercentage,
    this.workCompleted,
    this.workPlannedNext,
    this.materialsUsedSummary,
    this.equipmentUsedSummary,
    this.delays,
    this.issues,
    this.safetyNotes,
    this.remarks,
    required this.createdAtUtc,
  });

  final String id;
  final String companyId;
  final String projectId;
  final DateTime logDate;
  final String? weatherCondition;
  final double? temperatureCelsius;
  final int laborCount;
  final int contractorLaborCount;
  final double progressPercentage;
  final String? workCompleted;
  final String? workPlannedNext;
  final String? materialsUsedSummary;
  final String? equipmentUsedSummary;
  final String? delays;
  final String? issues;
  final String? safetyNotes;
  final String? remarks;
  final DateTime createdAtUtc;

  factory DailyProgressLog.fromJson(
    Map<String, dynamic> json,
  ) {
    return DailyProgressLog(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      projectId: json['projectId'] as String,
      logDate: DateTime.parse(
        json['logDate'] as String,
      ),
      weatherCondition:
          json['weatherCondition'] as String?,
      temperatureCelsius:
          (json['temperatureCelsius'] as num?)?.toDouble(),
      laborCount:
          (json['laborCount'] as num).toInt(),
      contractorLaborCount:
          (json['contractorLaborCount'] as num).toInt(),
      progressPercentage:
          (json['progressPercentage'] as num).toDouble(),
      workCompleted:
          json['workCompleted'] as String?,
      workPlannedNext:
          json['workPlannedNext'] as String?,
      materialsUsedSummary:
          json['materialsUsedSummary'] as String?,
      equipmentUsedSummary:
          json['equipmentUsedSummary'] as String?,
      delays: json['delays'] as String?,
      issues: json['issues'] as String?,
      safetyNotes: json['safetyNotes'] as String?,
      remarks: json['remarks'] as String?,
      createdAtUtc: DateTime.parse(
        json['createdAtUtc'] as String,
      ),
    );
  }
}
