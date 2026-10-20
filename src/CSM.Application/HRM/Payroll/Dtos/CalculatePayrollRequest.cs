
namespace CSM.Application.HRM.Payroll.Dtos;

public sealed record CalculatePayrollRequest(
    decimal OvertimeMultiplier,
    decimal Allowances,
    decimal Bonuses,
    decimal TaxDeduction,
    decimal PensionDeduction,
    decimal OtherDeductions,
    decimal? RegularHours = null,
    int? WorkingDays = null,
    decimal? OvertimeHours = null);
