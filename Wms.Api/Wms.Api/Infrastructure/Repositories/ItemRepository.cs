using Dapper;
using Wms.Api.Domain.Entities;
using Wms.Api.Infrastructure.Db;

namespace Wms.Api.Infrastructure.Repositories;

public sealed class ItemRepository : IItemRepository
{
    private readonly SqlConnectionFactory _factory;

    public ItemRepository(SqlConnectionFactory factory) => _factory = factory;

    public async Task<int> CreateAsync(Item item, CancellationToken ct)
    {
        const string sql = """
        INSERT INTO dbo.items (sku, item_name, uom, is_active, created_at)
        VALUES (@Sku, @ItemName, @Uom, @IsActive, SYSUTCDATETIME());
        SELECT CAST(SCOPE_IDENTITY() AS INT);
        """;

        using var conn = _factory.CreateConnection();
        var id = await conn.ExecuteScalarAsync<int>(new CommandDefinition(sql, item, cancellationToken: ct));
        return id;
    }

    public async Task<Item?> GetByIdAsync(int itemId, CancellationToken ct)
    {
        const string sql = """
        SELECT item_id AS ItemId, sku AS Sku, item_name AS ItemName, uom AS Uom, is_active AS IsActive
        FROM dbo.items
        WHERE item_id = @itemId;
        """;

        using var conn = _factory.CreateConnection();
        return await conn.QuerySingleOrDefaultAsync<Item>(new CommandDefinition(sql, new { itemId }, cancellationToken: ct));
    }

    public async Task<IEnumerable<Item>> GetAllAsync(CancellationToken ct)
    {
        const string sql = """
        SELECT item_id AS ItemId, sku AS Sku, item_name AS ItemName, uom AS Uom, is_active AS IsActive
        FROM dbo.items
        ORDER BY item_id DESC;
        """;

        using var conn = _factory.CreateConnection();
        return await conn.QueryAsync<Item>(new CommandDefinition(sql, cancellationToken: ct));
    }
}
