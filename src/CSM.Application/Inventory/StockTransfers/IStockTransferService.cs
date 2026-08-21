using CSM.Application.Inventory.StockTransfers.Dtos;

namespace CSM.Application.Inventory.StockTransfers;

public interface IStockTransferService
{
    Task<StockTransferResponse> CreateAsync(
        Guid currentUserId,
        CreateStockTransferRequest request,
        CancellationToken cancellationToken = default);
}
