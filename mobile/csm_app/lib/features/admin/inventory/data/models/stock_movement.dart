enum StockMovementType {
  openingBalance,
  goodsReceipt,
  issue,
  returnMovement,
  transferIn,
  transferOut,
  adjustmentIncrease,
  adjustmentDecrease,
}

class StockMovement {
  const StockMovement({
    required this.id,
    required this.stockItemId,
    required this.constructionSiteId,
    required this.siteName,
    required this.materialId,
    required this.materialCode,
    required this.materialName,
    required this.unitOfMeasure,
    required this.movementType,
    required this.movementDateUtc,
    required this.quantity,
    this.stockBalanceBefore,
    this.stockBalanceAfter,
    this.unitCost,
    this.totalCost,
    this.referenceType,
    this.referenceId,
    this.referenceNumber,
    this.remarks,
  });

  final String id;
  final String stockItemId;
  final String constructionSiteId;
  final String siteName;
  final String materialId;
  final String materialCode;
  final String materialName;
  final String unitOfMeasure;
  final StockMovementType movementType;
  final DateTime movementDateUtc;
  final double quantity;
  final double? stockBalanceBefore;
  final double? stockBalanceAfter;
  final double? unitCost;
  final double? totalCost;
  final String? referenceType;
  final String? referenceId;
  final String? referenceNumber;
  final String? remarks;

  factory StockMovement.fromJson(
      Map<String, dynamic> json,
      ) {
    return StockMovement(
      id: json['id'] as String,
      stockItemId: json['stockItemId'] as String,
      constructionSiteId:
      json['constructionSiteId'] as String,
      siteName: json['siteName'] as String? ?? '',
      materialId: json['materialId'] as String,
      materialCode:
      json['materialCode'] as String? ?? '',
      materialName:
      json['materialName'] as String? ?? '',
      unitOfMeasure:
      json['unitOfMeasure'] as String? ?? '',
      movementType:
      _movementTypeFromValue(json['movementType']),
      movementDateUtc: DateTime.parse(
        json['movementDateUtc'] as String,
      ),
      quantity:
      (json['quantity'] as num).toDouble(),
      stockBalanceBefore:
      json['stockBalanceBefore'] == null
          ? null
          : (json['stockBalanceBefore'] as num).toDouble(),
      stockBalanceAfter:
      json['stockBalanceAfter'] == null
          ? null
          : (json['stockBalanceAfter'] as num).toDouble(),
      unitCost: json['unitCost'] == null
          ? null
          : (json['unitCost'] as num).toDouble(),
      totalCost: json['totalCost'] == null
          ? null
          : (json['totalCost'] as num).toDouble(),
      referenceType:
      json['referenceType'] as String?,
      referenceId:
      json['referenceId'] as String?,
      referenceNumber:
      json['referenceNumber'] as String?,
      remarks:
      json['remarks'] as String?,
    );
  }

  static StockMovementType _movementTypeFromValue(
      dynamic value,
      ) {
    if (value is num) {
      switch (value.toInt()) {
        case 1:
          return StockMovementType.openingBalance;
        case 2:
          return StockMovementType.goodsReceipt;
        case 3:
          return StockMovementType.issue;
        case 4:
          return StockMovementType.returnMovement;
        case 5:
          return StockMovementType.transferIn;
        case 6:
          return StockMovementType.transferOut;
        case 7:
          return StockMovementType.adjustmentIncrease;
        case 8:
          return StockMovementType.adjustmentDecrease;
      }
    }

    final normalized = value
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('_', '')
        .replaceAll('-', '')
        .replaceAll(' ', '');

    switch (normalized) {
      case 'openingbalance':
      case '1':
        return StockMovementType.openingBalance;

      case 'goodsreceipt':
      case '2':
        return StockMovementType.goodsReceipt;

      case 'issue':
      case '3':
        return StockMovementType.issue;

      case 'return':
      case '4':
        return StockMovementType.returnMovement;

      case 'transferin':
      case '5':
        return StockMovementType.transferIn;

      case 'transferout':
      case '6':
        return StockMovementType.transferOut;

      case 'adjustmentincrease':
      case '7':
        return StockMovementType.adjustmentIncrease;

      case 'adjustmentdecrease':
      case '8':
        return StockMovementType.adjustmentDecrease;

      default:
        throw FormatException(
          'Unknown stock movement type: $value',
        );
    }
  }
}

