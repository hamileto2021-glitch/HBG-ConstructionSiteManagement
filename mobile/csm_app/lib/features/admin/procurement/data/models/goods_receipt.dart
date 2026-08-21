class GoodsReceiptLineInput {
  const GoodsReceiptLineInput({
    required this.purchaseOrderLineId,
    required this.receivedQuantity,
    required this.acceptedQuantity,
    required this.rejectedQuantity,
    this.rejectionReason,
    this.remarks,
  });

  final String purchaseOrderLineId;
  final double receivedQuantity;
  final double acceptedQuantity;
  final double rejectedQuantity;
  final String? rejectionReason;
  final String? remarks;

  Map<String, dynamic> toJson() {
    return {
      'purchaseOrderLineId': purchaseOrderLineId,
      'receivedQuantity': receivedQuantity,
      'acceptedQuantity': acceptedQuantity,
      'rejectedQuantity': rejectedQuantity,
      'rejectionReason': rejectionReason,
      'remarks': remarks,
    };
  }
}

class GoodsReceiptLine {
  const GoodsReceiptLine({
    required this.id,
    required this.purchaseOrderLineId,
    required this.materialId,
    required this.materialCode,
    required this.materialName,
    required this.receivedQuantity,
    required this.acceptedQuantity,
    required this.rejectedQuantity,
    required this.stockBalanceBefore,
    required this.stockBalanceAfter,
    this.rejectionReason,
    this.remarks,
  });

  final String id;
  final String purchaseOrderLineId;
  final String materialId;
  final String materialCode;
  final String materialName;
  final double receivedQuantity;
  final double acceptedQuantity;
  final double rejectedQuantity;
  final double? stockBalanceBefore;
  final double? stockBalanceAfter;
  final String? rejectionReason;
  final String? remarks;

  factory GoodsReceiptLine.fromJson(
      Map<String, dynamic> json,
      ) {
    return GoodsReceiptLine(
      id: json['id'] as String,
      purchaseOrderLineId:
      json['purchaseOrderLineId'] as String,
      materialId:
      json['materialId'] as String,
      materialCode:
      json['materialCode'] as String? ?? '',
      materialName:
      json['materialName'] as String? ?? '',
      receivedQuantity:
      (json['receivedQuantity'] as num).toDouble(),
      acceptedQuantity:
      (json['acceptedQuantity'] as num).toDouble(),
      rejectedQuantity:
      (json['rejectedQuantity'] as num).toDouble(),
      stockBalanceBefore:
      json['stockBalanceBefore'] == null
          ? null
          : (json['stockBalanceBefore'] as num)
          .toDouble(),
      stockBalanceAfter:
      json['stockBalanceAfter'] == null
          ? null
          : (json['stockBalanceAfter'] as num)
          .toDouble(),
      rejectionReason:
      json['rejectionReason'] as String?,
      remarks:
      json['remarks'] as String?,
    );
  }
}

class GoodsReceipt {
  const GoodsReceipt({
    required this.id,
    required this.purchaseOrderId,
    required this.purchaseOrderNumber,
    required this.constructionSiteId,
    required this.siteName,
    required this.receiptNumber,
    required this.receivedAtUtc,
    required this.receivedBy,
    this.deliveryNoteNumber,
    this.vehiclePlateNumber,
    this.remarks,
    required this.lines,
  });

  final String id;
  final String purchaseOrderId;
  final String purchaseOrderNumber;
  final String constructionSiteId;
  final String siteName;
  final String receiptNumber;
  final DateTime receivedAtUtc;
  final String receivedBy;
  final String? deliveryNoteNumber;
  final String? vehiclePlateNumber;
  final String? remarks;
  final List<GoodsReceiptLine> lines;

  factory GoodsReceipt.fromJson(
      Map<String, dynamic> json,
      ) {
    return GoodsReceipt(
      id: json['id'] as String,
      purchaseOrderId:
      json['purchaseOrderId'] as String,
      purchaseOrderNumber:
      json['purchaseOrderNumber'] as String? ?? '',
      constructionSiteId:
      json['constructionSiteId'] as String,
      siteName:
      json['siteName'] as String? ?? '',
      receiptNumber:
      json['receiptNumber'] as String? ?? '',
      receivedAtUtc:
      DateTime.parse(
        json['receivedAtUtc'] as String,
      ),
      receivedBy:
      json['receivedBy'] as String,
      deliveryNoteNumber:
      json['deliveryNoteNumber'] as String?,
      vehiclePlateNumber:
      json['vehiclePlateNumber'] as String?,
      remarks:
      json['remarks'] as String?,
      lines:
      (json['lines'] as List<dynamic>? ?? [])
          .map(
            (item) => GoodsReceiptLine.fromJson(
          item as Map<String, dynamic>,
        ),
      )
          .toList(),
    );
  }
}
