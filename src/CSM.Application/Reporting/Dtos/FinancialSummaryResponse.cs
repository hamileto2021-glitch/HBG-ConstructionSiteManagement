namespace CSM.Application.Reporting.Dtos;

public sealed record FinancialSummaryResponse(
    decimal TotalBudget,
    decimal TotalExpenses,
    decimal TotalInvoices,
    decimal TotalCompletedPayments,
    decimal OutstandingReceivables,
    decimal OutstandingPayables);
