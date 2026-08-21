namespace CSM.Application.Inventory.StockTransfers.Dtos;

public sealed class StockTransferResponse
{
    public Guid TransferOutMovementId { get; set; }

    public Guid TransferInMovementId { get; set; }

    public Guid MaterialId { get; set; }

    public string MaterialCode { get; set; } = string.Empty;

    public string MaterialName { get; set; } = string.Empty;

    public string UnitOfMeasure { get; set; } = string.Empty;

    public Guid SourceConstructionSiteId { get; set; }

    public string SourceSiteName { get; set; } = string.Empty;

    public Guid DestinationConstructionSiteId { get; set; }

    public string DestinationSiteName { get; set; } = string.Empty;

    public decimal Quantity { get; set; }

    public decimal UnitCost { get; set; }

    public decimal SourceQuantityBefore { get; set; }

    public decimal SourceQuantityAfter { get; set; }

    public decimal DestinationQuantityBefore { get; set; }

    public decimal DestinationQuantityAfter { get; set; }

    public DateTime TransferDateUtc { get; set; }

    public string TransferNumber { get; set; } = string.Empty;

    public string? RequestedBy { get; set; }

    public string? ApprovedBy { get; set; }

    public string? Remarks { get; set; }
}
