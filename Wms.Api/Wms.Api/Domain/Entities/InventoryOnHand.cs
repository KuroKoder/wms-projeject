namespace Wms.Api.Domain.Entities;

public sealed class InventoryOnHand
{
    public int WarehouseId { get; set; }
    public int LocationId { get; set; }
    public int ItemId { get; set; }
    public decimal QtyOnHand { get; set; }
    public decimal QtyReserved { get; set; }
}
