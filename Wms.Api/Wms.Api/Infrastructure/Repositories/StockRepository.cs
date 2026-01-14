using Dapper;
using Wms.Api.Domain.Entities;
using Wms.Api.Infrastructure.Db;

namespace Wms.Api.Infrastructure.Repositories;

public sealed class StockRepository : IStockRepository
{
    private readonly SqlConnectionFactory _factory;

    public StockRepository(SqlConnectionFactory factory) => _factory = factory;

    public async Task<InventoryOnHand?> GetOnHandAsync(int warehouseId, int locationId, int itemId, CancellationToken ct)
    {
        const string sql = """
        SELECT warehouse_id AS WarehouseId,
               location_id AS LocationId,
               item_id AS ItemId,
               qty_onhand AS QtyOnHand,
               qty_reserved AS QtyReserved
        FROM dbo.inventory_onhand
        WHERE warehouse_id = @warehouseId AND location_id = @locationId AND item_id = @itemId;
        """;

        using var conn = _factory.CreateConnection();
        return await conn.QuerySingleOrDefaultAsync<InventoryOnHand>(
            new CommandDefinition(sql, new { warehouseId, locationId, itemId }, cancellationToken: ct));
    }

    public async Task<(long txnId, string txnNo)> StockInAsync(
        int warehouseId, int toLocationId, int itemId, decimal qty,
        string? refNo, string? remarks, int createdBy, CancellationToken ct)
    {
        using var conn = _factory.CreateConnection();

        var p = new DynamicParameters();
        p.Add("@warehouse_id", warehouseId);
        p.Add("@to_location_id", toLocationId);
        p.Add("@item_id", itemId);
        p.Add("@qty", qty);
        p.Add("@ref_no", refNo);
        p.Add("@remarks", remarks);
        p.Add("@created_by", createdBy);
        p.Add("@txn_id", dbType: System.Data.DbType.Int64, direction: System.Data.ParameterDirection.Output);
        p.Add("@txn_no", dbType: System.Data.DbType.String, size: 30, direction: System.Data.ParameterDirection.Output);

        await conn.ExecuteAsync(new CommandDefinition(
            "dbo.sp_stock_in",
            p,
            commandType: System.Data.CommandType.StoredProcedure,
            cancellationToken: ct));

        return (p.Get<long>("@txn_id"), p.Get<string>("@txn_no"));
    }

    public async Task<(long txnId, string txnNo)> StockOutAsync(
        int warehouseId, int fromLocationId, int itemId, decimal qty,
        string? refNo, string? remarks, int createdBy, CancellationToken ct)
    {
        using var conn = _factory.CreateConnection();

        var p = new DynamicParameters();
        p.Add("@warehouse_id", warehouseId);
        p.Add("@from_location_id", fromLocationId);
        p.Add("@item_id", itemId);
        p.Add("@qty", qty);
        p.Add("@ref_no", refNo);
        p.Add("@remarks", remarks);
        p.Add("@created_by", createdBy);
        p.Add("@txn_id", dbType: System.Data.DbType.Int64, direction: System.Data.ParameterDirection.Output);
        p.Add("@txn_no", dbType: System.Data.DbType.String, size: 30, direction: System.Data.ParameterDirection.Output);

        await conn.ExecuteAsync(new CommandDefinition(
            "dbo.sp_stock_out",
            p,
            commandType: System.Data.CommandType.StoredProcedure,
            cancellationToken: ct));

        return (p.Get<long>("@txn_id"), p.Get<string>("@txn_no"));
    }

    public async Task<decimal> GetItemBalanceAsync(int warehouseId, int itemId, CancellationToken ct)
    {
        const string sql = """
        SELECT COALESCE(SUM(qty_onhand), 0)
        FROM dbo.inventory_onhand
        WHERE warehouse_id = @warehouseId AND item_id = @itemId;
        """;

        using var conn = _factory.CreateConnection();
        return await conn.ExecuteScalarAsync<decimal>(
            new CommandDefinition(sql, new { warehouseId, itemId }, cancellationToken: ct));
    }
}
