class CreateStockAdjustmentRequest {
  const CreateStockAdjustmentRequest({
    required this.constructionSiteId,
    required this.materialId,
    required this.increase,
    required this.quantity,
    this.unitCost,
    required this.adjustmentDateUtc,
    required this.adjustmentNumber,
    required this.reason,
    this.approvedBy,
    this.remarks,
  });

  final String constructionSiteId;
  final String materialId;
  final bool increase;
  final double quantity;
  final double? unitCost;
  final DateTime adjustmentDateUtc;
  final String adjustmentNumber;
  final String reason;
  final String? approvedBy;
  final String? remarks;

  Map<String, dynamic> toJson() {
    return {
      'constructionSiteId': constructionSiteId,
      'materialId': materialId,
      'increase': increase,
      'quantity': quantity,
      'unitCost': unitCost,
      'adjustmentDateUtc':
      adjustmentDateUtc.toUtc().toIso8601String(),
      'adjustmentNumber': adjustmentNumber,
      'reason': reason,
      'approvedBy': approvedBy,
      'remarks': remarks,
    };
  }
}

class StockAdjustment {
  const StockAdjustment({
    required this.movementId,
    required this.stockItemId,
    required this.materialId,
    required this.materialCode,
    required this.materialName,
    required this.unitOfMeasure,
    required this.constructionSiteId,
    required this.constructionSiteName,
    required this.increase,
    required this.quantity,
    required this.unitCost,
    required this.quantityBefore,
    required this.quantityAfter,
    required this.adjustmentDateUtc,
    required this.adjustmentNumber,
    required this.reason,
    this.approvedBy,
    this.remarks,
  });

  final String movementId;
  final String stockItemId;
  final String materialId;
  final String materialCode;
  final String materialName;
  final String unitOfMeasure;
  final String constructionSiteId;
  final String constructionSiteName;
  final bool increase;
  final double quantity;
  final double unitCost;
  final double quantityBefore;
  final double quantityAfter;
  final DateTime adjustmentDateUtc;
  final String adjustmentNumber;
  final String reason;
  final String? approvedBy;
  final String? remarks;

  factory StockAdjustment.fromJson(
      Map<String, dynamic> json,
      ) {
    return StockAdjustment(
      movementId:
      json['movementId'] as String,
      stockItemId:
      json['stockItemId'] as String,
      materialId:
      json['materialId'] as String,
      materialCode:
      json['materialCode'] as String? ?? '',
      materialName:
      json['materialName'] as String? ?? '',
      unitOfMeasure:
      json['unitOfMeasure'] as String? ?? '',
      constructionSiteId:
      json['constructionSiteId'] as String,
      constructionSiteName:
      json['constructionSiteName'] as String? ?? '',
      increase:
      json['increase'] as bool,
      quantity:
      (json['quantity'] as num).toDouble(),
      unitCost:
      (json['unitCost'] as num).toDouble(),
      quantityBefore:
      (json['quantityBefore'] as num).toDouble(),
      quantityAfter:
      (json['quantityAfter'] as num).toDouble(),
      adjustmentDateUtc:
      DateTime.parse(
        json['adjustmentDateUtc'] as String,
      ),
      adjustmentNumber:
      json['adjustmentNumber'] as String? ?? '',
      reason:
      json['reason'] as String? ?? '',
      approvedBy:
      json['approvedBy'] as String?,
      remarks:
      json['remarks'] as String?,
    );
  }
}