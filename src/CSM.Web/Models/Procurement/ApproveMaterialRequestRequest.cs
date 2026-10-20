
namespace CSM.Web.Models.Procurement;

public sealed class ApproveMaterialRequestRequest
{
    public string? Remarks { get; set; }

    public IReadOnlyCollection<MaterialRequestApprovalLine> Lines { get; set; }
        = Array.Empty<MaterialRequestApprovalLine>();
}

public sealed class MaterialRequestApprovalLine
{
    public Guid MaterialRequestLineId { get; set; }

    public decimal ApprovedQuantity { get; set; }
}
