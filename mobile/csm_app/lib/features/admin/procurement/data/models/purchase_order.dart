enum PurchaseOrderStatus {
  draft,
  pendingApproval,
  approved,
  sentToVendor,
  partiallyDelivered,
  delivered,
  closed,
  cancelled,
}

class PurchaseOrderLine {
  const PurchaseOrderLine({
    required this.id,
    required this.materialId,
    required this.materialCode,
    required this.materialName,
    required this.unitOfMeasure,
    this.costCodeId,
    this.costCode,
    required this.orderedQuantity,
    required this.receivedQuantity,
    required this.unitPrice,
    required this.taxAmount,
    required this.lineTotal,
  });

  final String id;
  final String materialId;
  final String materialCode;
  final String materialName;
  final String unitOfMeasure;
  final String? costCodeId;
  final String? costCode;
  final double orderedQuantity;
  final double receivedQuantity;
  final double unitPrice;
  final double taxAmount;
  final double lineTotal;

  factory PurchaseOrderLine.fromJson(
    Map<String, dynamic> json,
  ) {
    return PurchaseOrderLine(
      id: json['id'] as String,
      materialId: json['materialId'] as String,
      materialCode: json['materialCode'] as String? ?? '',
      materialName: json['materialName'] as String? ?? '',
      unitOfMeasure: json['unitOfMeasure'] as String? ?? '',
      costCodeId: json['costCodeId'] as String?,
      costCode: json['costCode'] as String?,
      orderedQuantity:
          (json['orderedQuantity'] as num).toDouble(),
      receivedQuantity:
          (json['receivedQuantity'] as num).toDouble(),
      unitPrice:
          (json['unitPrice'] as num).toDouble(),
      taxAmount:
          (json['taxAmount'] as num).toDouble(),
      lineTotal:
          (json['lineTotal'] as num).toDouble(),
    );
  }
}

class PurchaseOrderLineInput {
  const PurchaseOrderLineInput({
    required this.materialId,
    this.costCodeId,
    required this.orderedQuantity,
    required this.unitPrice,
    required this.taxAmount,
  });

  final String materialId;
  final String? costCodeId;
  final double orderedQuantity;
  final double unitPrice;
  final double taxAmount;

  Map<String, dynamic> toJson() {
    return {
      'materialId': materialId,
      'costCodeId': costCodeId,
      'orderedQuantity': orderedQuantity,
      'unitPrice': unitPrice,
      'taxAmount': taxAmount,
    };
  }
}

class PurchaseOrder {
  const PurchaseOrder({
    required this.id,
    required this.companyId,
    required this.constructionSiteId,
    required this.siteName,
    this.projectId,
    this.projectName,
    required this.vendorId,
    required this.vendorCode,
    required this.vendorName,
    this.materialRequestId,
    this.materialRequestNumber,
    required this.purchaseOrderNumber,
    required this.orderDate,
    this.expectedDeliveryDate,
    required this.currencyCode,
    required this.exchangeRate,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.totalAmount,
    required this.status,
    this.deliveryAddress,
    this.paymentTerms,
    this.notes,
    this.approvedBy,
    this.approvedAtUtc,
    required this.createdAtUtc,
    this.updatedAtUtc,
    required this.lines,
  });

  final String id;
  final String companyId;
  final String constructionSiteId;
  final String siteName;
  final String? projectId;
  final String? projectName;
  final String vendorId;
  final String vendorCode;
  final String vendorName;
  final String? materialRequestId;
  final String? materialRequestNumber;
  final String purchaseOrderNumber;
  final DateTime orderDate;
  final DateTime? expectedDeliveryDate;
  final String currencyCode;
  final double exchangeRate;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final PurchaseOrderStatus status;
  final String? deliveryAddress;
  final String? paymentTerms;
  final String? notes;
  final String? approvedBy;
  final DateTime? approvedAtUtc;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;
  final List<PurchaseOrderLine> lines;

  factory PurchaseOrder.fromJson(
    Map<String, dynamic> json,
  ) {
    return PurchaseOrder(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      constructionSiteId:
          json['constructionSiteId'] as String,
      siteName: json['siteName'] as String? ?? '',
      projectId: json['projectId'] as String?,
      projectName: json['projectName'] as String?,
      vendorId: json['vendorId'] as String,
      vendorCode: json['vendorCode'] as String? ?? '',
      vendorName: json['vendorName'] as String? ?? '',
      materialRequestId:
          json['materialRequestId'] as String?,
      materialRequestNumber:
          json['materialRequestNumber'] as String?,
      purchaseOrderNumber:
          json['purchaseOrderNumber'] as String? ?? '',
      orderDate: DateTime.parse(
        json['orderDate'] as String,
      ),
      expectedDeliveryDate:
          json['expectedDeliveryDate'] == null
              ? null
              : DateTime.parse(
                  json['expectedDeliveryDate'] as String,
                ),
      currencyCode:
          json['currencyCode'] as String? ?? '',
      exchangeRate:
          (json['exchangeRate'] as num).toDouble(),
      subtotal:
          (json['subtotal'] as num).toDouble(),
      taxAmount:
          (json['taxAmount'] as num).toDouble(),
      discountAmount:
          (json['discountAmount'] as num).toDouble(),
      totalAmount:
          (json['totalAmount'] as num).toDouble(),
      status: _statusFromValue(json['status']),
      deliveryAddress:
          json['deliveryAddress'] as String?,
      paymentTerms:
          json['paymentTerms'] as String?,
      notes: json['notes'] as String?,
      approvedBy: json['approvedBy'] as String?,
      approvedAtUtc:
          json['approvedAtUtc'] == null
              ? null
              : DateTime.parse(
                  json['approvedAtUtc'] as String,
                ),
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
                (item) => PurchaseOrderLine.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList(),
    );
  }

  static PurchaseOrderStatus _statusFromValue(
    dynamic value,
  ) {
    if (value is num) {
      switch (value.toInt()) {
        case 1:
          return PurchaseOrderStatus.draft;
        case 2:
          return PurchaseOrderStatus.pendingApproval;
        case 3:
          return PurchaseOrderStatus.approved;
        case 4:
          return PurchaseOrderStatus.sentToVendor;
        case 5:
          return PurchaseOrderStatus.partiallyDelivered;
        case 6:
          return PurchaseOrderStatus.delivered;
        case 7:
          return PurchaseOrderStatus.closed;
        case 8:
          return PurchaseOrderStatus.cancelled;
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
      case 'draft':
      case '1':
        return PurchaseOrderStatus.draft;

      case 'pendingapproval':
      case '2':
        return PurchaseOrderStatus.pendingApproval;

      case 'approved':
      case '3':
        return PurchaseOrderStatus.approved;

      case 'senttovendor':
      case '4':
        return PurchaseOrderStatus.sentToVendor;

      case 'partiallydelivered':
      case '5':
        return PurchaseOrderStatus.partiallyDelivered;

      case 'delivered':
      case '6':
        return PurchaseOrderStatus.delivered;

      case 'closed':
      case '7':
        return PurchaseOrderStatus.closed;

      case 'cancelled':
      case 'canceled':
      case '8':
        return PurchaseOrderStatus.cancelled;

      default:
        throw FormatException(
          'Unknown purchase order status: ',
        );
    }
  }
}
