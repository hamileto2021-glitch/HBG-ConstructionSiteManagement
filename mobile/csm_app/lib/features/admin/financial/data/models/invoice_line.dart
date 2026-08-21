class InvoiceLine {
  const InvoiceLine({
    required this.id,
    required this.companyId,
    required this.invoiceId,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    required this.createdAtUtc,
    this.updatedAtUtc,
  });

  final String id;
  final String companyId;
  final String invoiceId;
  final String description;
  final double quantity;
  final double unitPrice;
  final double lineTotal;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;

  factory InvoiceLine.fromJson(
    Map<String, dynamic> json,
  ) {
    return InvoiceLine(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      invoiceId: json['invoiceId'] as String,
      description: json['description'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      lineTotal: (json['lineTotal'] as num).toDouble(),
      createdAtUtc: DateTime.parse(
        json['createdAtUtc'] as String,
      ),
      updatedAtUtc: json['updatedAtUtc'] == null
          ? null
          : DateTime.parse(
              json['updatedAtUtc'] as String,
            ),
    );
  }
}