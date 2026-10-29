namespace CSM.Application.Reporting.Dtos;

public sealed record FinancialSummaryResponse(
    decimal TotalBudget,
    decimal TotalExpenses,
    decimal ExpenseRecords,
    decimal PayrollPaid,
    decimal RemainingBudget,
    decimal BudgetUsedPercent,
    decimal TotalInvoiced,
    decimal OutstandingReceivables,
    decimal OutstandingPayables,
    decimal PettyCashOpeningBalance,
    decimal PettyCashIn,
    decimal PettyCashOut,
    decimal PettyCashBalance,
    int ActivePettyCashAccounts);
