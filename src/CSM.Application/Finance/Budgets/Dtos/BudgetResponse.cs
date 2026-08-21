using CSM.Domain.Enums;

namespace CSM.Application.Finance.Budgets.Dtos;

public sealed record BudgetResponse(
    Guid Id,
    Guid CompanyId,
    Guid ConstructionSiteId,
    Guid? ProjectId,
    string BudgetNumber,
    string Name,
    string? Description,
    decimal TotalAmount,
    string CurrencyCode,
    DateOnly? EffectiveFrom,
    DateOnly? EffectiveTo,
    BudgetStatus Status,
    Guid? ApprovedBy,
    DateTime? ApprovedAtUtc,
    DateTime CreatedAtUtc,
    DateTime? UpdatedAtUtc);
