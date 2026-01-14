namespace Wms.Api.Domain.Entities;

public sealed class StockTransaction
{
    public long TxnId { get; set; }
    public string TxnNo { get; set; } = "";
    public string TxnType { get; set; } = ""; // IN/OUT
    public int WarehouseId { get; set; }
    public string? RefNo { get; set; }
    public string Status { get; set; } = "POSTED";
    public int CreatedBy { get; set; }
    public DateTime CreatedAt { get; set; }
}
