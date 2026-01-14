/* ============================================================
   003_sprocs.sql
   - Sequence + function + stored procedures
   ============================================================ */

-- USE WmsDb;
USE WmsDb;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

---------------------------------------------------------------
-- SEQUENCE for txn numbering
---------------------------------------------------------------
IF OBJECT_ID('dbo.seq_txn_no', 'SO') IS NULL
BEGIN
  EXEC('CREATE SEQUENCE dbo.seq_txn_no AS BIGINT START WITH 1 INCREMENT BY 1;');
END
GO

---------------------------------------------------------------
-- Function: Generate Txn No
-- Format: {TYPE}-{yyyyMMdd}-{000000}
---------------------------------------------------------------
CREATE OR ALTER FUNCTION dbo.fn_gen_txn_no(@txn_type NVARCHAR(10))
RETURNS NVARCHAR(30)
AS
BEGIN
  DECLARE @seq BIGINT = NEXT VALUE FOR dbo.seq_txn_no;
  DECLARE @date NVARCHAR(8) = CONVERT(NVARCHAR(8), GETDATE(), 112);
  DECLARE @num NVARCHAR(6) = RIGHT(CONCAT('000000', CAST(@seq AS NVARCHAR(20))), 6);
  RETURN CONCAT(@txn_type, '-', @date, '-', @num);
END
GO

---------------------------------------------------------------
-- SP: STOCK IN
---------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_stock_in
  @warehouse_id INT,
  @to_location_id INT,
  @item_id INT,
  @qty DECIMAL(18,3),
  @ref_no NVARCHAR(50) = NULL,
  @remarks NVARCHAR(255) = NULL,
  @created_by INT,
  @txn_id BIGINT OUTPUT,
  @txn_no NVARCHAR(30) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  IF @warehouse_id <= 0 THROW 50010, 'warehouse_id must be > 0', 1;
  IF @to_location_id <= 0 THROW 50011, 'to_location_id must be > 0', 1;
  IF @item_id <= 0 THROW 50012, 'item_id must be > 0', 1;
  IF @qty <= 0 THROW 50013, 'qty must be > 0', 1;

  IF NOT EXISTS (SELECT 1 FROM dbo.warehouses WHERE warehouse_id=@warehouse_id AND is_active=1)
    THROW 50014, 'warehouse not found', 1;

  IF NOT EXISTS (SELECT 1 FROM dbo.locations WHERE location_id=@to_location_id AND warehouse_id=@warehouse_id AND is_active=1)
    THROW 50015, 'location not found in warehouse', 1;

  IF NOT EXISTS (SELECT 1 FROM dbo.items WHERE item_id=@item_id AND is_active=1)
    THROW 50016, 'item not found', 1;

  BEGIN TRAN;

    SET @txn_no = dbo.fn_gen_txn_no('IN');

    INSERT INTO dbo.stock_txn_hdr (txn_no, txn_type, warehouse_id, ref_no, remarks, status, created_by)
    VALUES (@txn_no, 'IN', @warehouse_id, @ref_no, @remarks, 'POSTED', @created_by);

    SET @txn_id = SCOPE_IDENTITY();

    INSERT INTO dbo.stock_txn_dtl (txn_id, line_no, item_id, from_location_id, to_location_id, qty)
    VALUES (@txn_id, 1, @item_id, NULL, @to_location_id, @qty);

    -- Upsert onhand with lock to avoid race
    IF EXISTS (
      SELECT 1
      FROM dbo.inventory_onhand WITH (UPDLOCK, HOLDLOCK)
      WHERE warehouse_id=@warehouse_id AND location_id=@to_location_id AND item_id=@item_id
    )
    BEGIN
      UPDATE dbo.inventory_onhand
      SET qty_onhand = qty_onhand + @qty
      WHERE warehouse_id=@warehouse_id AND location_id=@to_location_id AND item_id=@item_id;
    END
    ELSE
    BEGIN
      INSERT INTO dbo.inventory_onhand (warehouse_id, location_id, item_id, qty_onhand, qty_reserved)
      VALUES (@warehouse_id, @to_location_id, @item_id, @qty, 0);
    END

  COMMIT;
END
GO

---------------------------------------------------------------
-- SP: STOCK OUT (block negative stock)
---------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_stock_out
  @warehouse_id INT,
  @from_location_id INT,
  @item_id INT,
  @qty DECIMAL(18,3),
  @ref_no NVARCHAR(50) = NULL,
  @remarks NVARCHAR(255) = NULL,
  @created_by INT,
  @txn_id BIGINT OUTPUT,
  @txn_no NVARCHAR(30) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  IF @warehouse_id <= 0 THROW 50110, 'warehouse_id must be > 0', 1;
  IF @from_location_id <= 0 THROW 50111, 'from_location_id must be > 0', 1;
  IF @item_id <= 0 THROW 50112, 'item_id must be > 0', 1;
  IF @qty <= 0 THROW 50113, 'qty must be > 0', 1;

  IF NOT EXISTS (SELECT 1 FROM dbo.warehouses WHERE warehouse_id=@warehouse_id AND is_active=1)
    THROW 50114, 'warehouse not found', 1;

  IF NOT EXISTS (SELECT 1 FROM dbo.locations WHERE location_id=@from_location_id AND warehouse_id=@warehouse_id AND is_active=1)
    THROW 50115, 'location not found in warehouse', 1;

  IF NOT EXISTS (SELECT 1 FROM dbo.items WHERE item_id=@item_id AND is_active=1)
    THROW 50116, 'item not found', 1;

  BEGIN TRAN;

    DECLARE @current DECIMAL(18,3);

    SELECT @current = qty_onhand
    FROM dbo.inventory_onhand WITH (UPDLOCK, HOLDLOCK)
    WHERE warehouse_id=@warehouse_id AND location_id=@from_location_id AND item_id=@item_id;

    IF @current IS NULL
      THROW 50117, 'stock not found', 1;

    IF @current < @qty
      THROW 50118, 'insufficient stock', 1;

    SET @txn_no = dbo.fn_gen_txn_no('OUT');

    INSERT INTO dbo.stock_txn_hdr (txn_no, txn_type, warehouse_id, ref_no, remarks, status, created_by)
    VALUES (@txn_no, 'OUT', @warehouse_id, @ref_no, @remarks, 'POSTED', @created_by);

    SET @txn_id = SCOPE_IDENTITY();

    INSERT INTO dbo.stock_txn_dtl (txn_id, line_no, item_id, from_location_id, to_location_id, qty)
    VALUES (@txn_id, 1, @item_id, @from_location_id, NULL, @qty);

    UPDATE dbo.inventory_onhand
    SET qty_onhand = qty_onhand - @qty
    WHERE warehouse_id=@warehouse_id AND location_id=@from_location_id AND item_id=@item_id;

  COMMIT;
END
GO

---------------------------------------------------------------
-- SP: STOCK MOVE (optional)
---------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_stock_move
  @warehouse_id INT,
  @from_location_id INT,
  @to_location_id INT,
  @item_id INT,
  @qty DECIMAL(18,3),
  @ref_no NVARCHAR(50) = NULL,
  @remarks NVARCHAR(255) = NULL,
  @created_by INT,
  @txn_id BIGINT OUTPUT,
  @txn_no NVARCHAR(30) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  IF @warehouse_id <= 0 THROW 50210, 'warehouse_id must be > 0', 1;
  IF @from_location_id <= 0 THROW 50211, 'from_location_id must be > 0', 1;
  IF @to_location_id <= 0 THROW 50212, 'to_location_id must be > 0', 1;
  IF @from_location_id = @to_location_id THROW 50213, 'from/to location must be different', 1;
  IF @item_id <= 0 THROW 50214, 'item_id must be > 0', 1;
  IF @qty <= 0 THROW 50215, 'qty must be > 0', 1;

  BEGIN TRAN;

    DECLARE @current DECIMAL(18,3);

    SELECT @current = qty_onhand
    FROM dbo.inventory_onhand WITH (UPDLOCK, HOLDLOCK)
    WHERE warehouse_id=@warehouse_id AND location_id=@from_location_id AND item_id=@item_id;

    IF @current IS NULL THROW 50216, 'stock not found', 1;
    IF @current < @qty THROW 50217, 'insufficient stock', 1;

    SET @txn_no = dbo.fn_gen_txn_no('MOVE');

    INSERT INTO dbo.stock_txn_hdr (txn_no, txn_type, warehouse_id, ref_no, remarks, status, created_by)
    VALUES (@txn_no, 'MOVE', @warehouse_id, @ref_no, @remarks, 'POSTED', @created_by);

    SET @txn_id = SCOPE_IDENTITY();

    INSERT INTO dbo.stock_txn_dtl (txn_id, line_no, item_id, from_location_id, to_location_id, qty)
    VALUES (@txn_id, 1, @item_id, @from_location_id, @to_location_id, @qty);

    UPDATE dbo.inventory_onhand
    SET qty_onhand = qty_onhand - @qty
    WHERE warehouse_id=@warehouse_id AND location_id=@from_location_id AND item_id=@item_id;

    IF EXISTS (
      SELECT 1
      FROM dbo.inventory_onhand WITH (UPDLOCK, HOLDLOCK)
      WHERE warehouse_id=@warehouse_id AND location_id=@to_location_id AND item_id=@item_id
    )
    BEGIN
      UPDATE dbo.inventory_onhand
      SET qty_onhand = qty_onhand + @qty
      WHERE warehouse_id=@warehouse_id AND location_id=@to_location_id AND item_id=@item_id;
    END
    ELSE
    BEGIN
      INSERT INTO dbo.inventory_onhand (warehouse_id, location_id, item_id, qty_onhand, qty_reserved)
      VALUES (@warehouse_id, @to_location_id, @item_id, @qty, 0);
    END

  COMMIT;
END
GO

---------------------------------------------------------------
-- SP: GET ITEM BALANCE (sum across locations)
---------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_get_item_balance
  @warehouse_id INT,
  @item_id INT
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    @warehouse_id AS warehouse_id,
    @item_id AS item_id,
    COALESCE(SUM(qty_onhand), 0) AS qty_onhand_total
  FROM dbo.inventory_onhand
  WHERE warehouse_id=@warehouse_id AND item_id=@item_id;
END
GO
