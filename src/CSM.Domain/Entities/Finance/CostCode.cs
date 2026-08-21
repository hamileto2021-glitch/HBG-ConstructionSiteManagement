using CSM.Domain.Common;

namespace CSM.Domain.Entities.Finance;

public class CostCode : TenantEntity
{
    public string Code { get; set; } = string.Empty;

    public string Name { get; set; } = string.Empty;

    public string? Description { get; set; }

    public Guid? ParentCostCodeId { get; set; }

    public bool IsActive { get; set; } = true;

    public CostCode? ParentCostCode { get; set; }

    public ICollection<CostCode> Children { get; set; }
        = new List<CostCode>();

    public ICollection<BudgetLine> BudgetLines { get; set; }
        = new List<BudgetLine>();

    public ICollection<Expense> Expenses { get; set; }
        = new List<Expense>();
}