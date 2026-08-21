class CreateStockIssueRequest {
  const CreateStockIssueRequest({
    required this.constructionSiteId,
    required this.materialId,
    required this.quantity,
    required this.issueDateUtc,
    required this.referenceNumber,
    this.issuedTo,
    this.purpose,
    this.remarks,
  });

  final String constructionSiteId;
  final String materialId;
  final double quantity;
  final DateTime issueDateUtc;
  final String referenceNumber;
  final String? issuedTo;
  final String? purpose;
  final String? remarks;

  Map<String, dynamic> toJson() {
    return {
      'constructionSiteId': constructionSiteId,
      'materialId': materialId,
      'quantity': quantity,
      'issueDateUtc': issueDateUtc
          .toUtc()
          .toIso8601String(),
      'referenceNumber': referenceNumber,
      'issuedTo': issuedTo,
      'purpose': purpose,
      'remarks': remarks,
    };
  }
}

class StockIssue {
  const StockIssue({
    required this.stockMovementId,
    required this.stockItemId,
    required this.constructionSiteId,
    required this.siteName,
    required this.materialId,
    required this.materialCode,
    required this.materialName,
    required this.unitOfMeasure,
    required this.quantityIssued,
    required this.quantityOnHandBefore,
    required this.quantityOnHandAfter,
    required this.unitCost,
    required this.totalCost,
    required this.issueDateUtc,
    required this.referenceNumber,
    this.issuedTo,
    this.purpose,
    this.remarks,
  });

  final String stockMovementId;
  final String stockItemId;
  final String constructionSiteId;
  final String siteName;
  final String materialId;
  final String materialCode;
  final String materialName;
  final String unitOfMeasure;
  final double quantityIssued;
  final double quantityOnHandBefore;
  final double quantityOnHandAfter;
  final double unitCost;
  final double totalCost;
  final DateTime issueDateUtc;
  final String referenceNumber;
  final String? issuedTo;
  final String? purpose;
  final String? remarks;

  factory StockIssue.fromJson(
      Map<String, dynamic> json,
      ) {
    return StockIssue(
      stockMovementId:
      json['stockMovementId'] as String,
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
      quantityIssued:
      (json['quantityIssued'] as num).toDouble(),
      quantityOnHandBefore:
      (json['quantityOnHandBefore'] as num)
          .toDouble(),
      quantityOnHandAfter:
      (json['quantityOnHandAfter'] as num)
          .toDouble(),
      unitCost:
      (json['unitCost'] as num).toDouble(),
      totalCost:
      (json['totalCost'] as num).toDouble(),
      issueDateUtc:
      DateTime.parse(
        json['issueDateUtc'] as String,
      ),
      referenceNumber:
      json['referenceNumber'] as String? ?? '',
      issuedTo:
      json['issuedTo'] as String?,
      purpose:
      json['purpose'] as String?,
      remarks:
      json['remarks'] as String?,
    );
  }
}