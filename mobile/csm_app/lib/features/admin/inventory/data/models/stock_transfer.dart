class CreateStockTransferRequest {
  const CreateStockTransferRequest({
    required this.sourceConstructionSiteId,
    required this.destinationConstructionSiteId,
    required this.materialId,
    required this.quantity,
    required this.transferDateUtc,
    required this.transferNumber,
    this.requestedBy,
    this.approvedBy,
    this.remarks,
  });

  final String sourceConstructionSiteId;
  final String destinationConstructionSiteId;
  final String materialId;
  final double quantity;
  final DateTime transferDateUtc;
  final String transferNumber;
  final String? requestedBy;
  final String? approvedBy;
  final String? remarks;

  Map<String, dynamic> toJson() {
    return {
      'sourceConstructionSiteId':
      sourceConstructionSiteId,
      'destinationConstructionSiteId':
      destinationConstructionSiteId,
      'materialId': materialId,
      'quantity': quantity,
      'transferDateUtc':
      transferDateUtc.toUtc().toIso8601String(),
      'transferNumber': transferNumber,
      'requestedBy': requestedBy,
      'approvedBy': approvedBy,
      'remarks': remarks,
    };
  }
}

class StockTransfer {
  const StockTransfer({
    required this.transferOutMovementId,
    required this.transferInMovementId,
    required this.materialId,
    required this.materialCode,
    required this.materialName,
    required this.unitOfMeasure,
    required this.sourceConstructionSiteId,
    required this.sourceSiteName,
    required this.destinationConstructionSiteId,
    required this.destinationSiteName,
    required this.quantity,
    required this.unitCost,
    required this.sourceQuantityBefore,
    required this.sourceQuantityAfter,
    required this.destinationQuantityBefore,
    required this.destinationQuantityAfter,
    required this.transferDateUtc,
    required this.transferNumber,
    this.requestedBy,
    this.approvedBy,
    this.remarks,
  });

  final String transferOutMovementId;
  final String transferInMovementId;
  final String materialId;
  final String materialCode;
  final String materialName;
  final String unitOfMeasure;
  final String sourceConstructionSiteId;
  final String sourceSiteName;
  final String destinationConstructionSiteId;
  final String destinationSiteName;
  final double quantity;
  final double unitCost;
  final double sourceQuantityBefore;
  final double sourceQuantityAfter;
  final double destinationQuantityBefore;
  final double destinationQuantityAfter;
  final DateTime transferDateUtc;
  final String transferNumber;
  final String? requestedBy;
  final String? approvedBy;
  final String? remarks;

  factory StockTransfer.fromJson(
      Map<String, dynamic> json,
      ) {
    return StockTransfer(
      transferOutMovementId:
      json['transferOutMovementId'] as String,
      transferInMovementId:
      json['transferInMovementId'] as String,
      materialId:
      json['materialId'] as String,
      materialCode:
      json['materialCode'] as String? ?? '',
      materialName:
      json['materialName'] as String? ?? '',
      unitOfMeasure:
      json['unitOfMeasure'] as String? ?? '',
      sourceConstructionSiteId:
      json['sourceConstructionSiteId'] as String,
      sourceSiteName:
      json['sourceSiteName'] as String? ?? '',
      destinationConstructionSiteId:
      json['destinationConstructionSiteId']
      as String,
      destinationSiteName:
      json['destinationSiteName'] as String? ?? '',
      quantity:
      (json['quantity'] as num).toDouble(),
      unitCost:
      (json['unitCost'] as num).toDouble(),
      sourceQuantityBefore:
      (json['sourceQuantityBefore'] as num)
          .toDouble(),
      sourceQuantityAfter:
      (json['sourceQuantityAfter'] as num)
          .toDouble(),
      destinationQuantityBefore:
      (json['destinationQuantityBefore'] as num)
          .toDouble(),
      destinationQuantityAfter:
      (json['destinationQuantityAfter'] as num)
          .toDouble(),
      transferDateUtc:
      DateTime.parse(
        json['transferDateUtc'] as String,
      ),
      transferNumber:
      json['transferNumber'] as String? ?? '',
      requestedBy:
      json['requestedBy'] as String?,
      approvedBy:
      json['approvedBy'] as String?,
      remarks:
      json['remarks'] as String?,
    );
  }
}