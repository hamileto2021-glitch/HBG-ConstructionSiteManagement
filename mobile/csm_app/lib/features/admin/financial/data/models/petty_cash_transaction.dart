enum PettyCashTransactionType {
  cashIn,
  cashOut,
}

class PettyCashTransaction {
  const PettyCashTransaction({
    required this.id,
    required this.pettyCashAccountId,
    required this.referenceNumber,
    required this.transactionType,
    required this.transactionDateUtc,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.description,
    this.remarks,
    this.costCodeId,
    this.costCodeName,
    required this.isApproved,
  });

  final String id;
  final String pettyCashAccountId;
  final String referenceNumber;
  final PettyCashTransactionType transactionType;
  final DateTime transactionDateUtc;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String description;
  final String? remarks;
  final String? costCodeId;
  final String? costCodeName;
  final bool isApproved;

  factory PettyCashTransaction.fromJson(
      Map<String, dynamic> json) {
    return PettyCashTransaction(
      id: json['id'] as String,
      pettyCashAccountId:
      json['pettyCashAccountId'] as String,
      referenceNumber:
      json['referenceNumber'] as String? ?? '',
      transactionType:
      (json['transactionType']
          .toString()
          .toLowerCase() ==
          'cashin')
          ? PettyCashTransactionType.cashIn
          : PettyCashTransactionType.cashOut,
      transactionDateUtc: DateTime.parse(
          json['transactionDateUtc'] as String),
      amount: (json['amount'] as num).toDouble(),
      balanceBefore:
      (json['balanceBefore'] as num).toDouble(),
      balanceAfter:
      (json['balanceAfter'] as num).toDouble(),
      description:
      json['description'] as String? ?? '',
      remarks: json['remarks'] as String?,
      costCodeId: json['costCodeId'] as String?,
      costCodeName: json['costCodeName'] as String?,
      isApproved: json['isApproved'] as bool? ?? false,
    );
  }
}