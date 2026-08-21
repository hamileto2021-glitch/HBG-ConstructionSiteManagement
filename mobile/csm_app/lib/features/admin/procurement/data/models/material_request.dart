enum Priority {
  low,
  normal,
  high,
  critical,
}

enum MaterialRequestStatus {
  draft,
  submitted,
  approved,
  partiallyApproved,
  rejected,
  ordered,
  partiallyDelivered,
  delivered,
  cancelled,
}

class MaterialRequestLine {
  const MaterialRequestLine({
    required this.id,
    required this.materialId,
    required this.materialCode,
    required this.materialName,
    required this.unitOfMeasure,
    required this.requestedQuantity,
    required this.approvedQuantity,
    required this.deliveredQuantity,
    this.remarks,
  });

  final String id;
  final String materialId;
  final String materialCode;
  final String materialName;
  final String unitOfMeasure;
  final double requestedQuantity;
  final double approvedQuantity;
  final double deliveredQuantity;
  final String? remarks;

  factory MaterialRequestLine.fromJson(
    Map<String, dynamic> json,
  ) {
    return MaterialRequestLine(
      id: json['id'] as String,
      materialId: json['materialId'] as String,
      materialCode: json['materialCode'] as String? ?? '',
      materialName: json['materialName'] as String? ?? '',
      unitOfMeasure: json['unitOfMeasure'] as String? ?? '',
      requestedQuantity:
          (json['requestedQuantity'] as num).toDouble(),
      approvedQuantity:
          (json['approvedQuantity'] as num).toDouble(),
      deliveredQuantity:
          (json['deliveredQuantity'] as num).toDouble(),
      remarks: json['remarks'] as String?,
    );
  }
}

class MaterialRequest {
  const MaterialRequest({
    required this.id,
    required this.companyId,
    required this.constructionSiteId,
    required this.siteName,
    this.projectId,
    this.projectCode,
    this.projectName,
    required this.requestNumber,
    required this.requestDate,
    this.requiredByDate,
    this.purpose,
    required this.priority,
    required this.status,
    required this.requestedBy,
    this.approvedBy,
    this.approvedAtUtc,
    this.approvalRemarks,
    required this.createdAtUtc,
    this.updatedAtUtc,
    required this.lines,
  });

  final String id;
  final String companyId;
  final String constructionSiteId;
  final String siteName;
  final String? projectId;
  final String? projectCode;
  final String? projectName;
  final String requestNumber;
  final DateTime requestDate;
  final DateTime? requiredByDate;
  final String? purpose;
  final Priority priority;
  final MaterialRequestStatus status;
  final String requestedBy;
  final String? approvedBy;
  final DateTime? approvedAtUtc;
  final String? approvalRemarks;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;
  final List<MaterialRequestLine> lines;

  factory MaterialRequest.fromJson(
    Map<String, dynamic> json,
  ) {
    return MaterialRequest(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      constructionSiteId:
          json['constructionSiteId'] as String,
      siteName: json['siteName'] as String? ?? '',
      projectId: json['projectId'] as String?,
      projectCode: json['projectCode'] as String?,
      projectName: json['projectName'] as String?,
      requestNumber:
          json['requestNumber'] as String? ?? '',
      requestDate: DateTime.parse(
        json['requestDate'] as String,
      ),
      requiredByDate:
          json['requiredByDate'] == null
              ? null
              : DateTime.parse(
                  json['requiredByDate'] as String,
                ),
      purpose: json['purpose'] as String?,
      priority: _priorityFromValue(
        json['priority'],
      ),
      status: _statusFromValue(
        json['status'],
      ),
      requestedBy: json['requestedBy'] as String,
      approvedBy: json['approvedBy'] as String?,
      approvedAtUtc:
          json['approvedAtUtc'] == null
              ? null
              : DateTime.parse(
                  json['approvedAtUtc'] as String,
                ),
      approvalRemarks:
          json['approvalRemarks'] as String?,
      createdAtUtc: DateTime.parse(
        json['createdAtUtc'] as String,
      ),
      updatedAtUtc:
          json['updatedAtUtc'] == null
              ? null
              : DateTime.parse(
                  json['updatedAtUtc'] as String,
                ),
      lines:
          (json['lines'] as List<dynamic>? ?? [])
              .map(
                (item) =>
                    MaterialRequestLine.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList(),
    );
  }

  static Priority _priorityFromValue(
    dynamic value,
  ) {
    if (value is num) {
      switch (value.toInt()) {
        case 1:
          return Priority.low;
        case 2:
          return Priority.normal;
        case 3:
          return Priority.high;
        case 4:
          return Priority.critical;
      }
    }

    final normalized =
        value?.toString().trim().toLowerCase();

    switch (normalized) {
      case 'low':
        return Priority.low;
      case 'normal':
        return Priority.normal;
      case 'high':
        return Priority.high;
      case 'critical':
        return Priority.critical;
      default:
        throw FormatException(
          'Unknown material request priority: $value',
        );
    }
  }

  static MaterialRequestStatus _statusFromValue(
    dynamic value,
  ) {
    if (value is num) {
      switch (value.toInt()) {
        case 1:
          return MaterialRequestStatus.draft;
        case 2:
          return MaterialRequestStatus.submitted;
        case 3:
          return MaterialRequestStatus.approved;
        case 4:
          return MaterialRequestStatus.partiallyApproved;
        case 5:
          return MaterialRequestStatus.rejected;
        case 6:
          return MaterialRequestStatus.ordered;
        case 7:
          return MaterialRequestStatus.partiallyDelivered;
        case 8:
          return MaterialRequestStatus.delivered;
        case 9:
          return MaterialRequestStatus.cancelled;
      }
    }

    final normalized =
        value?.toString().trim().toLowerCase();

    switch (normalized) {
      case 'draft':
        return MaterialRequestStatus.draft;
      case 'submitted':
        return MaterialRequestStatus.submitted;
      case 'approved':
        return MaterialRequestStatus.approved;
      case 'partiallyapproved':
      case 'partially_approved':
      case 'partially approved':
        return MaterialRequestStatus.partiallyApproved;
      case 'rejected':
        return MaterialRequestStatus.rejected;
      case 'ordered':
        return MaterialRequestStatus.ordered;
      case 'partiallydelivered':
      case 'partially_delivered':
      case 'partially delivered':
        return MaterialRequestStatus.partiallyDelivered;
      case 'delivered':
        return MaterialRequestStatus.delivered;
      case 'cancelled':
        return MaterialRequestStatus.cancelled;
      default:
        throw FormatException(
          'Unknown material request status: $value',
        );
    }
  }
}

class MaterialRequestLineInput {
  const MaterialRequestLineInput({
    required this.materialId,
    required this.requestedQuantity,
    this.remarks,
  });

  final String materialId;
  final double requestedQuantity;
  final String? remarks;

  Map<String, dynamic> toJson() {
    return {
      'materialId': materialId,
      'requestedQuantity': requestedQuantity,
      'remarks': remarks,
    };
  }
}

class MaterialRequestApprovalLine {
  const MaterialRequestApprovalLine({
    required this.materialRequestLineId,
    required this.approvedQuantity,
  });

  final String materialRequestLineId;
  final double approvedQuantity;

  Map<String, dynamic> toJson() {
    return {
      'materialRequestLineId': materialRequestLineId,
      'approvedQuantity': approvedQuantity,
    };
  }
}
