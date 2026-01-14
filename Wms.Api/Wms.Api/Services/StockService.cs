using Wms.Api.Dtos;
using Wms.Api.Infrastructure.Repositories;

namespace Wms.Api.Services;

public sealed class StockService
{
    private readonly IStockRepository _stockRepository;

    public StockService(IStockRepository stockRepository) => _stockRepository = stockRepository;

    public async Task<(long txnId, string txnNo)> StockInAsync(StockInRequest req, CancellationToken ct)
    {
        Validate(req.WarehouseId, req.ToLocationId, req.ItemId, req.Qty);

        return await _stockRepository.StockInAsync(
            req.WarehouseId, req.ToLocationId, req.ItemId, req.Qty,
            req.RefNo, req.Remarks, req.CreatedBy, ct);
    }

    public async Task<(long txnId, string txnNo)> StockOutAsync(StockOutRequest req, CancellationToken ct)
    {
        Validate(req.WarehouseId, req.FromLocationId, req.ItemId, req.Qty);

        return await _stockRepository.StockOutAsync(
            req.WarehouseId, req.FromLocationId, req.ItemId, req.Qty,
            req.RefNo, req.Remarks, req.CreatedBy, ct);
    }

    private static void Validate(int warehouseId, int locationId, int itemId, decimal qty)
    {
        if (warehouseId <= 0) throw new ArgumentException("warehouseId must be > 0");
        if (locationId <= 0) throw new ArgumentException("locationId must be > 0");
        if (itemId <= 0) throw new ArgumentException("itemId must be > 0");
        if (qty <= 0) throw new ArgumentException("qty must be > 0");
    }
}
