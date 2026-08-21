class FinancialSummary {
  const FinancialSummary({
    required this.totalBudget,
    required this.totalExpenses,
    required this.totalInvoices,
    required this.totalCompletedPayments,
    required this.outstandingReceivables,
    required this.outstandingPayables,
  });

  final double totalBudget;
  final double totalExpenses;
  final double totalInvoices;
  final double totalCompletedPayments;
  final double outstandingReceivables;
  final double outstandingPayables;

  factory FinancialSummary.fromJson(
      Map<String, dynamic> json,
      ) {
    return FinancialSummary(
      totalBudget: (json['totalBudget'] as num).toDouble(),
      totalExpenses: (json['totalExpenses'] as num).toDouble(),
      totalInvoices: (json['totalInvoices'] as num).toDouble(),
      totalCompletedPayments:
      (json['totalCompletedPayments'] as num).toDouble(),
      outstandingReceivables:
      (json['outstandingReceivables'] as num).toDouble(),
      outstandingPayables:
      (json['outstandingPayables'] as num).toDouble(),
    );
  }
}