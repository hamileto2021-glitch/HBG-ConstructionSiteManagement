using CSM.Application.Inventory.StockIssues.Dtos;

namespace CSM.Application.Inventory.StockIssues;

public interface IStockIssueService
{
    Task<StockIssueResponse> CreateAsync(
        Guid currentUserId,
        CreateStockIssueRequest request,
        CancellationToken cancellationToken = default);
}
