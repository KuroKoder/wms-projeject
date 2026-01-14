namespace Wms.Api.Dtos;

public sealed class StockInRequest
{
    public int WarehouseId { get; set; }
    public int ToLocationId { get; set; }
    public int ItemId { get; set; }
    public decimal Qty { get; set; }
    public string? RefNo { get; set; }
    public string? Remarks { get; set; }
    public int CreatedBy { get; set; } = 1; // default user
}
