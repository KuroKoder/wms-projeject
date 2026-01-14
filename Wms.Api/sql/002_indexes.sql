/* ============================================================
   002_indexes.sql
   - Create helpful indexes
   ============================================================ */

-- USE WmsDb;
USE WmsDb;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

-- inventory_onhand: lookup by item
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_onhand_item' AND object_id=OBJECT_ID('dbo.inventory_onhand'))
BEGIN
  CREATE INDEX IX_onhand_item
  ON dbo.inventory_onhand(item_id)
  INCLUDE (qty_onhand, qty_reserved, warehouse_id, location_id);
END
GO

-- stock_txn_hdr: recency and type queries
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_txn_hdr_created_at' AND object_id=OBJECT_ID('dbo.stock_txn_hdr'))
BEGIN
  CREATE INDEX IX_txn_hdr_created_at ON dbo.stock_txn_hdr(created_at DESC);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_txn_hdr_type' AND object_id=OBJECT_ID('dbo.stock_txn_hdr'))
BEGIN
  CREATE INDEX IX_txn_hdr_type ON dbo.stock_txn_hdr(txn_type, created_at DESC);
END
GO

-- stock_txn_dtl: item history
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_txn_dtl_item' AND object_id=OBJECT_ID('dbo.stock_txn_dtl'))
BEGIN
  CREATE INDEX IX_txn_dtl_item
  ON dbo.stock_txn_dtl(item_id, txn_id)
  INCLUDE (qty, from_location_id, to_location_id);
END
GO
