class CreateStockReturnRequest {
  const CreateStockReturnRequest({
    required this.originalIssueMovementId,
    required this.quantity,
    required this.returnDateUtc,
    required this.referenceNumber,
    this.returnedBy,
    this.reason,
    this.remarks,
  });

  final String originalIssueMovementId;
  final double quantity;
  final DateTime returnDateUtc;
  final String referenceNumber;
  final String? returnedBy;
  final String? reason;
  final String? remarks;

  Map<String, dynamic> toJson() {
    return {
      'originalIssueMovementId': originalIssueMovementId,
      'quantity': quantity,
      'returnDateUtc':
      returnDateUtc.toUtc().toIso8601String(),
      'referenceNumber': referenceNumber,
      'returnedBy': returnedBy,
      'reason': reason,
      'remarks': remarks,
    };
  }
}

class StockReturn {
  const StockReturn({
    required this.id,
    required this.originalIssueMovementId,
    required this.stockItemId,
    required this.constructionSiteId,
    required this.siteName,
    required this.materialId,
    required this.materialCode,
    required this.materialName,
    required this.unitOfMeasure,
    required this.originalIssuedQuantity,
    required this.previouslyReturnedQuantity,
    required this.returnedQuantity,
    required this.remainingReturnableQuantity,
    required this.unitCost,
    required this.quantityOnHandBefore,
    required this.quantityOnHandAfter,
    required this.returnDateUtc,
    required this.referenceNumber,
    this.returnedBy,
    this.reason,
    this.remarks,
  });

  final String id;
  final String originalIssueMovementId;
  final String stockItemId;
  final String constructionSiteId;
  final String siteName;
  final String materialId;
  final String materialCode;
  final String materialName;
  final String unitOfMeasure;
  final double originalIssuedQuantity;
  final double previouslyReturnedQuantity;
  final double returnedQuantity;
  final double remainingReturnableQuantity;
  final double unitCost;
  final double quantityOnHandBefore;
  final double quantityOnHandAfter;
  final DateTime returnDateUtc;
  final String referenceNumber;
  final String? returnedBy;
  final String? reason;
  final String? remarks;

  factory StockReturn.fromJson(
      Map<String, dynamic> json,
      ) {
    return StockReturn(
      id: json['id'] as String,
      originalIssueMovementId:
      json['originalIssueMovementId'] as String,
      stockItemId:
      json['stockItemId'] as String,
      constructionSiteId:
      json['constructionSiteId'] as String,
      siteName:
      json['siteName'] as String? ?? '',
      materialId:
      json['materialId'] as String,
      materialCode:
      json['materialCode'] as String? ?? '',
      materialName:
      json['materialName'] as String? ?? '',
      unitOfMeasure:
      json['unitOfMeasure'] as String? ?? '',
      originalIssuedQuantity:
      (json['originalIssuedQuantity'] as num)
          .toDouble(),
      previouslyReturnedQuantity:
      (json['previouslyReturnedQuantity'] as num)
          .toDouble(),
      returnedQuantity:
      (json['returnedQuantity'] as num)
          .toDouble(),
      remainingReturnableQuantity:
      (json['remainingReturnableQuantity'] as num)
          .toDouble(),
      unitCost:
      (json['unitCost'] as num).toDouble(),
      quantityOnHandBefore:
      (json['quantityOnHandBefore'] as num)
          .toDouble(),
      quantityOnHandAfter:
      (json['quantityOnHandAfter'] as num)
          .toDouble(),
      returnDateUtc:
      DateTime.parse(
        json['returnDateUtc'] as String,
      ),
      referenceNumber:
      json['referenceNumber'] as String? ?? '',
      returnedBy:
      json['returnedBy'] as String?,
      reason:
      json['reason'] as String?,
      remarks:
      json['remarks'] as String?,
    );
  }
}