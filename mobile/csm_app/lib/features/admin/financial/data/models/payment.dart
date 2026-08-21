enum PaymentDirection {
  incoming,
  outgoing,
}

extension PaymentDirectionX on PaymentDirection {
  String get apiValue {
    switch (this) {
      case PaymentDirection.incoming:
        return 'Incoming';
      case PaymentDirection.outgoing:
        return 'Outgoing';
    }
  }

  String get displayName {
    switch (this) {
      case PaymentDirection.incoming:
        return 'Incoming';
      case PaymentDirection.outgoing:
        return 'Outgoing';
    }
  }

  static PaymentDirection fromJson(dynamic value) {
    final text = value.toString().toLowerCase();

    switch (text) {
      case 'incoming':
      case '1':
        return PaymentDirection.incoming;
      case 'outgoing':
      case '2':
        return PaymentDirection.outgoing;
      default:
        throw FormatException(
          'Unknown payment direction: $value',
        );
    }
  }
}

enum PaymentStatus {
  pending,
  completed,
  cancelled,
}

extension PaymentStatusX on PaymentStatus {
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

  static PaymentStatus fromJson(dynamic value) {
    final text = value.toString().toLowerCase();

    switch (text) {
      case 'pending':
      case '1':
        return PaymentStatus.pending;

      case 'completed':
      case '2':
        return PaymentStatus.completed;

      case 'cancelled':
      case '3':
        return PaymentStatus.cancelled;

      default:
        throw FormatException(
          'Unknown payment status: $value',
        );
    }
  }
}

class Payment {
  const Payment({
    required this.id,
    required this.companyId,
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
      invoiceId: json['invoiceId'] as String?,
      vendorId: json['vendorId'] as String?,
      paymentNumber:
      json['paymentNumber'] as String,
      paymentDate: DateTime.parse(
        json['paymentDate'] as String,
      ),
      direction: PaymentDirectionX.fromJson(
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
      notes: json['notes'] as String?,
      status:
      PaymentStatusX.fromJson(json['status']),
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
}