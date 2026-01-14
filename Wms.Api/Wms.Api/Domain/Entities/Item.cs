namespace Wms.Api.Domain.Entities;

public sealed class Item
{
    public int ItemId { get; set; }
    public string Sku { get; set; } = "";
    public string ItemName { get; set; } = "";
    public string Uom { get; set; } = "PCS";
    public bool IsActive { get; set; } = true;
}
