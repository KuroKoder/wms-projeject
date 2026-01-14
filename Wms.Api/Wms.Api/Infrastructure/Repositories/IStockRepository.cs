using Wms.Api.Domain.Entities;

namespace Wms.Api.Infrastructure.Repositories;

public interface IStockRepository
{
    Task<InventoryOnHand?> GetOnHandAsync(int warehouseId, int locationId, int itemId, CancellationToken ct);

    Task<(long txnId, string txnNo)> StockInAsync(
        int warehouseId, int toLocationId, int itemId, decimal qty,
        string? refNo, string? remarks, int createdBy, CancellationToken ct);

    Task<(long txnId, string txnNo)> StockOutAsync(
        int warehouseId, int fromLocationId, int itemId, decimal qty,
        string? refNo, string? remarks, int createdBy, CancellationToken ct);

    Task<decimal> GetItemBalanceAsync(int warehouseId, int itemId, CancellationToken ct);
}
