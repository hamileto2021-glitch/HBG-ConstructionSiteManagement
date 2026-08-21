enum InvoiceType {
  client,
  vendor,
}

extension InvoiceTypeX on InvoiceType {
  String get apiValue {
    switch (this) {
      case InvoiceType.client:
        return 'ClientInvoice';
      case InvoiceType.vendor:
        return 'VendorBill';
    }
  }

  String get displayName {
    switch (this) {
      case InvoiceType.client:
        return 'Client';
      case InvoiceType.vendor:
        return 'Vendor';
    }
  }

  static InvoiceType fromJson(dynamic value) {
    final text = value.toString().toLowerCase();

    switch (text) {
      case 'clientinvoice':
      case 'client':
      case '1':
        return InvoiceType.client;

      case 'vendorbill':
      case 'vendor':
      case '2':
        return InvoiceType.vendor;

      default:
        throw FormatException('Unknown invoice type: $value');
    }
  }
}

enum InvoiceStatus {
  draft,
  issued,
  partiallyPaid,
  paid,
  overdue,
  cancelled,
}

extension InvoiceStatusX on InvoiceStatus {
  String get apiValue {
    switch (this) {
      case InvoiceStatus.draft:
        return 'Draft';
      case InvoiceStatus.issued:
        return 'Issued';
      case InvoiceStatus.partiallyPaid:
        return 'PartiallyPaid';
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.overdue:
        return 'Overdue';
      case InvoiceStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get displayName {
    switch (this) {
      case InvoiceStatus.draft:
        return 'Draft';
      case InvoiceStatus.issued:
        return 'Issued';
      case InvoiceStatus.partiallyPaid:
        return 'Partially Paid';
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.overdue:
        return 'Overdue';
      case InvoiceStatus.cancelled:
        return 'Cancelled';
    }
  }

  static InvoiceStatus fromJson(dynamic value) {
    final text = value.toString().toLowerCase();

    switch (text) {
      case 'draft':
      case '1':
        return InvoiceStatus.draft;
      case 'issued':
      case '2':
        return InvoiceStatus.issued;
      case 'partiallypaid':
      case 'partially_paid':
      case '3':
        return InvoiceStatus.partiallyPaid;
      case 'paid':
      case '4':
        return InvoiceStatus.paid;
      case 'overdue':
      case '5':
        return InvoiceStatus.overdue;
      case 'cancelled':
      case '6':
        return InvoiceStatus.cancelled;
      default:
        throw FormatException('Unknown invoice status: $value');
    }
  }
}

class Invoice {
  const Invoice({
    required this.id,
    required this.companyId,
    required this.constructionSiteId,
    this.projectId,
    this.vendorId,
    required this.invoiceNumber,
    required this.type,
    required this.invoiceDate,
    this.dueDate,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    required this.currencyCode,
    required this.exchangeRate,
    required this.status,
    this.description,
    this.externalReference,
    required this.createdAtUtc,
    this.updatedAtUtc,
  });

  final String id;
  final String companyId;
  final String constructionSiteId;
  final String? projectId;
  final String? vendorId;
  final String invoiceNumber;
  final InvoiceType type;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final String currencyCode;
  final double exchangeRate;
  final InvoiceStatus status;
  final String? description;
  final String? externalReference;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      constructionSiteId: json['constructionSiteId'] as String,
      projectId: json['projectId'] as String?,
      vendorId: json['vendorId'] as String?,
      invoiceNumber: json['invoiceNumber'] as String,
      type: InvoiceTypeX.fromJson(json['type']),
      invoiceDate: DateTime.parse(json['invoiceDate'] as String),
      dueDate: json['dueDate'] == null
          ? null
          : DateTime.parse(json['dueDate'] as String),
      subtotal: (json['subtotal'] as num).toDouble(),
      taxAmount: (json['taxAmount'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      currencyCode: json['currencyCode'] as String,
      exchangeRate: (json['exchangeRate'] as num).toDouble(),
      status: InvoiceStatusX.fromJson(json['status']),
      description: json['description'] as String?,
      externalReference: json['externalReference'] as String?,
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
      updatedAtUtc: json['updatedAtUtc'] == null
          ? null
          : DateTime.parse(json['updatedAtUtc'] as String),
    );
  }
}