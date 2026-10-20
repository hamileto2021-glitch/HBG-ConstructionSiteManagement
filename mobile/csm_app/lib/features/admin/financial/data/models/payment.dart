enum PaymentDirection {
  incoming,
  outgoing,
}

enum PaymentStatus {
  pending,
  completed,
  cancelled,
}

class Payment {
  const Payment({
    required this.id,
    required this.companyId,
    required this.constructionSiteId,
    this.projectId,
    this.invoiceId,
    this.vendorId,
    required this.paymentNumber,
    required this.paymentDate,
    required this.direction,
    required this.amount,
    required this.currencyCode,
    required this.exchangeRate,
    this.paymentMethod,
    this.referenceNumber,
    this.notes,
    required this.status,
    required this.createdAtUtc,
    this.updatedAtUtc,
  });

  final String id;
  final String companyId;

  /// NEW
  final String constructionSiteId;
  final String? projectId;

  final String? invoiceId;
  final String? vendorId;

  final String paymentNumber;
  final DateTime paymentDate;

  final PaymentDirection direction;

  final double amount;
  final String currencyCode;
  final double exchangeRate;

  final String? paymentMethod;
  final String? referenceNumber;
  final String? notes;

  final PaymentStatus status;

  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;

  factory Payment.fromJson(
      Map<String, dynamic> json,
      ) {
    return Payment(
      id: json['id'] as String,
      companyId: json['companyId'] as String,

      constructionSiteId:
      json['constructionSiteId'] as String,

      projectId:
      json['projectId'] as String?,

      invoiceId:
      json['invoiceId'] as String?,

      vendorId:
      json['vendorId'] as String?,

      paymentNumber:
      json['paymentNumber'] as String,

      paymentDate: DateTime.parse(
        json['paymentDate'] as String,
      ),

      direction: _directionFromValue(
        json['direction'],
      ),

      amount:
      (json['amount'] as num).toDouble(),

      currencyCode:
      json['currencyCode'] as String,

      exchangeRate:
      (json['exchangeRate'] as num).toDouble(),

      paymentMethod:
      json['paymentMethod'] as String?,

      referenceNumber:
      json['referenceNumber'] as String?,

      notes:
      json['notes'] as String?,

      status: _statusFromValue(
        json['status'],
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
    );
  }

  static PaymentDirection _directionFromValue(
      dynamic value,
      ) {
    if (value is num) {
      switch (value.toInt()) {
        case 1:
          return PaymentDirection.incoming;
        case 2:
          return PaymentDirection.outgoing;
      }
    }

    switch (
    value.toString().trim().toLowerCase()) {
      case 'incoming':
        return PaymentDirection.incoming;
      case 'outgoing':
        return PaymentDirection.outgoing;
      default:
        throw FormatException(
          'Unknown payment direction: $value',
        );
    }
  }

  static PaymentStatus _statusFromValue(
      dynamic value,
      ) {
    if (value is num) {
      switch (value.toInt()) {
        case 1:
          return PaymentStatus.pending;
        case 2:
          return PaymentStatus.completed;
        case 3:
          return PaymentStatus.cancelled;
      }
    }

    switch (
    value.toString().trim().toLowerCase()) {
      case 'pending':
        return PaymentStatus.pending;
      case 'completed':
        return PaymentStatus.completed;
      case 'cancelled':
        return PaymentStatus.cancelled;
      default:
        throw FormatException(
          'Unknown payment status: $value',
        );
    }
  }
}

extension PaymentDirectionX on PaymentDirection {
  String get displayName {
    switch (this) {
      case PaymentDirection.incoming:
        return 'Incoming';
      case PaymentDirection.outgoing:
        return 'Outgoing';
    }
  }

  String get apiValue {
    switch (this) {
      case PaymentDirection.incoming:
        return 'Incoming';
      case PaymentDirection.outgoing:
        return 'Outgoing';
    }
  }
}

extension PaymentStatusX on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get apiValue {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class CreatePaymentRequest {
  const CreatePaymentRequest({
    required this.constructionSiteId,
    this.projectId,
    this.invoiceId,
    this.vendorId,
    required this.paymentNumber,
    required this.paymentDate,
    required this.direction,
    required this.amount,
    required this.currencyCode,
    required this.exchangeRate,
    this.paymentMethod,
    this.referenceNumber,
    this.notes,
  });

  final String constructionSiteId;
  final String? projectId;
  final String? invoiceId;
  final String? vendorId;

  final String paymentNumber;
  final DateTime paymentDate;
  final PaymentDirection direction;

  final double amount;
  final String currencyCode;
  final double exchangeRate;

  final String? paymentMethod;
  final String? referenceNumber;
  final String? notes;

  Map<String, dynamic> toJson() {
    return {
      'constructionSiteId':
      constructionSiteId,
      'projectId': projectId,
      'invoiceId': invoiceId,
      'vendorId': vendorId,
      'paymentNumber': paymentNumber,
      'paymentDate':
      paymentDate.toIso8601String(),
      'direction': direction.name,
      'amount': amount,
      'currencyCode': currencyCode,
      'exchangeRate': exchangeRate,
      'paymentMethod': paymentMethod,
      'referenceNumber': referenceNumber,
      'notes': notes,
    };
  }
}

class UpdatePaymentRequest {
  const UpdatePaymentRequest({
    required this.constructionSiteId,
    this.projectId,
    this.invoiceId,
    this.vendorId,
    required this.paymentDate,
    required this.direction,
    required this.amount,
    required this.currencyCode,
    required this.exchangeRate,
    this.paymentMethod,
    this.referenceNumber,
    this.notes,
  });

  final String constructionSiteId;
  final String? projectId;
  final String? invoiceId;
  final String? vendorId;

  final DateTime paymentDate;
  final PaymentDirection direction;

  final double amount;
  final String currencyCode;
  final double exchangeRate;

  final String? paymentMethod;
  final String? referenceNumber;
  final String? notes;

  Map<String, dynamic> toJson() {
    return {
      'constructionSiteId':
      constructionSiteId,
      'projectId': projectId,
      'invoiceId': invoiceId,
      'vendorId': vendorId,
      'paymentDate':
      paymentDate.toIso8601String(),
      'direction': direction.name,
      'amount': amount,
      'currencyCode': currencyCode,
      'exchangeRate': exchangeRate,
      'paymentMethod': paymentMethod,
      'referenceNumber': referenceNumber,
      'notes': notes,
    };
  }
}