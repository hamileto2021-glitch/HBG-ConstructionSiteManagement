namespace CSM.Web.Models.Reporting;

// Mirrors the API's FinancialSummaryResponse, property for property.
public sealed class FinancialSummaryResponse
{
    // Budget
    public decimal TotalBudget { get; set; }

    // Expenses = ExpenseRecords + PayrollPaid + PettyCashOut
    public decimal TotalExpenses { get; set; }
    public decimal ExpenseRecords { get; set; }
    public decimal PayrollPaid { get; set; }

    public decimal RemainingBudget { get; set; }
    public decimal BudgetUsedPercent { get; set; }

    // Invoices
    public decimal TotalInvoiced { get; set; }
    public decimal OutstandingReceivables { get; set; }
    public decimal OutstandingPayables { get; set; }

    // Petty cash: opening + cash in - cash out = balance
    public decimal PettyCashOpeningBalance { get; set; }
    public decimal PettyCashIn { get; set; }
    public decimal PettyCashOut { get; set; }
    public decimal PettyCashBalance { get; set; }
    public int ActivePettyCashAccounts { get; set; }
}
