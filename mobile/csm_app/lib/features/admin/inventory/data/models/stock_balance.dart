class StockBalance {
  const StockBalance({
    required this.stockItemId,
    required this.constructionSiteId,
    required this.siteName,
    required this.materialId,
    required this.materialCode,
    required this.materialName,
    required this.unitOfMeasure,
    required this.quantityOnHand,
    required this.quantityReserved,
    required this.availableQuantity,
    required this.reorderLevel,
    this.maximumStockLevel,
    required this.averageUnitCost,
    this.storageLocation,
  });

  final String stockItemId;
  final String constructionSiteId;
  final String siteName;
  final String materialId;
  final String materialCode;
  final String materialName;
  final String unitOfMeasure;
  final double quantityOnHand;
  final double quantityReserved;
  final double availableQuantity;
  final double reorderLevel;
  final double? maximumStockLevel;
  final double averageUnitCost;
  final String? storageLocation;

  factory StockBalance.fromJson(
    Map<String, dynamic> json,
  ) {
    return StockBalance(
      stockItemId: json['stockItemId'] as String,
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
      quantityOnHand:
          (json['quantityOnHand'] as num).toDouble(),
      quantityReserved:
          (json['quantityReserved'] as num).toDouble(),
      availableQuantity:
          (json['availableQuantity'] as num).toDouble(),
      reorderLevel:
          (json['reorderLevel'] as num).toDouble(),
      maximumStockLevel:
          json['maximumStockLevel'] == null
              ? null
              : (json['maximumStockLevel'] as num).toDouble(),
      averageUnitCost:
          (json['averageUnitCost'] as num).toDouble(),
      storageLocation:
          json['storageLocation'] as String?,
    );
  }

  bool get isLowStock =>
      reorderLevel > 0 &&
      quantityOnHand <= reorderLevel;
}
