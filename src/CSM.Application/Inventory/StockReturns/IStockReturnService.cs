using CSM.Application.Inventory.StockReturns.Dtos;

namespace CSM.Application.Inventory.StockReturns;

public interface IStockReturnService
{
    Task<StockReturnResponse> CreateAsync(
        Guid currentUserId,
        CreateStockReturnRequest request,
        CancellationToken cancellationToken = default);
}
