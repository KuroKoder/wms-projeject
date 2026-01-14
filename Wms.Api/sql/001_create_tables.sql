/* ============================================================
   001_create_tables.sql
   - Create core tables for Mini WMS
   ============================================================ */

-- USE WmsDb;
USE WmsDb;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

---------------------------------------------------------------
-- MASTER
---------------------------------------------------------------

IF OBJECT_ID('dbo.roles') IS NULL
BEGIN
  CREATE TABLE dbo.roles (
    role_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_roles PRIMARY KEY,
    role_code NVARCHAR(30) NOT NULL CONSTRAINT UQ_roles_role_code UNIQUE,
    role_name NVARCHAR(100) NOT NULL,
    is_active BIT NOT NULL CONSTRAINT DF_roles_is_active DEFAULT(1),
    created_at DATETIME2(0) NOT NULL CONSTRAINT DF_roles_created_at DEFAULT SYSUTCDATETIME()
  );
END
GO

IF OBJECT_ID('dbo.users') IS NULL
BEGIN
  CREATE TABLE dbo.users (
    user_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_users PRIMARY KEY,
    username NVARCHAR(50) NOT NULL CONSTRAINT UQ_users_username UNIQUE,
    password_hash VARBINARY(256) NULL,
    display_name NVARCHAR(120) NOT NULL,
    email NVARCHAR(120) NULL,
    is_active BIT NOT NULL CONSTRAINT DF_users_is_active DEFAULT(1),
    created_at DATETIME2(0) NOT NULL CONSTRAINT DF_users_created_at DEFAULT SYSUTCDATETIME()
  );
END
GO

IF OBJECT_ID('dbo.user_roles') IS NULL
BEGIN
  CREATE TABLE dbo.user_roles (
    user_id INT NOT NULL,
    role_id INT NOT NULL,
    CONSTRAINT PK_user_roles PRIMARY KEY (user_id, role_id),
    CONSTRAINT FK_user_roles_users FOREIGN KEY (user_id) REFERENCES dbo.users(user_id),
    CONSTRAINT FK_user_roles_roles FOREIGN KEY (role_id) REFERENCES dbo.roles(role_id)
  );
END
GO

IF OBJECT_ID('dbo.warehouses') IS NULL
BEGIN
  CREATE TABLE dbo.warehouses (
    warehouse_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_warehouses PRIMARY KEY,
    warehouse_code NVARCHAR(30) NOT NULL CONSTRAINT UQ_warehouses_code UNIQUE,
    warehouse_name NVARCHAR(120) NOT NULL,
    address NVARCHAR(255) NULL,
    is_active BIT NOT NULL CONSTRAINT DF_warehouses_is_active DEFAULT(1),
    created_at DATETIME2(0) NOT NULL CONSTRAINT DF_warehouses_created_at DEFAULT SYSUTCDATETIME()
  );
END
GO

IF OBJECT_ID('dbo.locations') IS NULL
BEGIN
  CREATE TABLE dbo.locations (
    location_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_locations PRIMARY KEY,
    warehouse_id INT NOT NULL,
    location_code NVARCHAR(40) NOT NULL,
    location_type NVARCHAR(20) NOT NULL CONSTRAINT DF_locations_type DEFAULT('BIN'),
    is_active BIT NOT NULL CONSTRAINT DF_locations_is_active DEFAULT(1),
    created_at DATETIME2(0) NOT NULL CONSTRAINT DF_locations_created_at DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_locations_warehouses FOREIGN KEY (warehouse_id) REFERENCES dbo.warehouses(warehouse_id),
    CONSTRAINT UQ_locations_wh_code UNIQUE (warehouse_id, location_code),
    CONSTRAINT CK_locations_type CHECK (location_type IN ('BIN','STAGING','RECEIVING','SHIPPING'))
  );
END
GO

IF OBJECT_ID('dbo.items') IS NULL
BEGIN
  CREATE TABLE dbo.items (
    item_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_items PRIMARY KEY,
    sku NVARCHAR(50) NOT NULL CONSTRAINT UQ_items_sku UNIQUE,
    item_name NVARCHAR(150) NOT NULL,
    uom NVARCHAR(10) NOT NULL CONSTRAINT DF_items_uom DEFAULT('PCS'),
    barcode NVARCHAR(60) NULL,
    is_active BIT NOT NULL CONSTRAINT DF_items_is_active DEFAULT(1),
    created_at DATETIME2(0) NOT NULL CONSTRAINT DF_items_created_at DEFAULT SYSUTCDATETIME()
  );
END
GO

---------------------------------------------------------------
-- INVENTORY
---------------------------------------------------------------

IF OBJECT_ID('dbo.inventory_onhand') IS NULL
BEGIN
  CREATE TABLE dbo.inventory_onhand (
    warehouse_id INT NOT NULL,
    location_id INT NOT NULL,
    item_id INT NOT NULL,
    qty_onhand DECIMAL(18,3) NOT NULL CONSTRAINT DF_onhand_qty DEFAULT(0),
    qty_reserved DECIMAL(18,3) NOT NULL CONSTRAINT DF_onhand_reserved DEFAULT(0),
    row_version ROWVERSION NOT NULL,
    CONSTRAINT PK_inventory_onhand PRIMARY KEY (warehouse_id, location_id, item_id),
    CONSTRAINT FK_onhand_wh FOREIGN KEY (warehouse_id) REFERENCES dbo.warehouses(warehouse_id),
    CONSTRAINT FK_onhand_loc FOREIGN KEY (location_id) REFERENCES dbo.locations(location_id),
    CONSTRAINT FK_onhand_item FOREIGN KEY (item_id) REFERENCES dbo.items(item_id),
    CONSTRAINT CK_onhand_nonneg CHECK (qty_onhand >= 0 AND qty_reserved >= 0)
  );
END
GO

---------------------------------------------------------------
-- TRANSACTIONS
---------------------------------------------------------------

IF OBJECT_ID('dbo.stock_txn_hdr') IS NULL
BEGIN
  CREATE TABLE dbo.stock_txn_hdr (
    txn_id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_stock_txn_hdr PRIMARY KEY,
    txn_no NVARCHAR(30) NOT NULL CONSTRAINT UQ_stock_txn_hdr_txn_no UNIQUE,
    txn_type NVARCHAR(10) NOT NULL,
    warehouse_id INT NOT NULL,
    ref_no NVARCHAR(50) NULL,
    remarks NVARCHAR(255) NULL,
    status NVARCHAR(15) NOT NULL CONSTRAINT DF_stock_txn_hdr_status DEFAULT('POSTED'),
    created_by INT NOT NULL,
    created_at DATETIME2(0) NOT NULL CONSTRAINT DF_stock_txn_hdr_created_at DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_txn_hdr_wh FOREIGN KEY (warehouse_id) REFERENCES dbo.warehouses(warehouse_id),
    CONSTRAINT FK_txn_hdr_user FOREIGN KEY (created_by) REFERENCES dbo.users(user_id),
    CONSTRAINT CK_txn_hdr_type CHECK (txn_type IN ('IN','OUT','MOVE','ADJ')),
    CONSTRAINT CK_txn_hdr_status CHECK (status IN ('DRAFT','POSTED','CANCELLED'))
  );
END
GO

IF OBJECT_ID('dbo.stock_txn_dtl') IS NULL
BEGIN
  CREATE TABLE dbo.stock_txn_dtl (
    txn_line_id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_stock_txn_dtl PRIMARY KEY,
    txn_id BIGINT NOT NULL,
    line_no INT NOT NULL,
    item_id INT NOT NULL,
    from_location_id INT NULL,
    to_location_id INT NULL,
    qty DECIMAL(18,3) NOT NULL,
    unit_cost DECIMAL(18,4) NULL,
    CONSTRAINT FK_txn_dtl_hdr FOREIGN KEY (txn_id) REFERENCES dbo.stock_txn_hdr(txn_id),
    CONSTRAINT FK_txn_dtl_item FOREIGN KEY (item_id) REFERENCES dbo.items(item_id),
    CONSTRAINT FK_txn_dtl_from_loc FOREIGN KEY (from_location_id) REFERENCES dbo.locations(location_id),
    CONSTRAINT FK_txn_dtl_to_loc FOREIGN KEY (to_location_id) REFERENCES dbo.locations(location_id),
    CONSTRAINT UQ_txn_dtl_line UNIQUE (txn_id, line_no),
    CONSTRAINT CK_txn_dtl_qty CHECK (qty > 0),
    CONSTRAINT CK_txn_dtl_loc CHECK ((from_location_id IS NOT NULL OR to_location_id IS NOT NULL))
  );
END
GO

---------------------------------------------------------------
-- OPTIONAL AUDIT
---------------------------------------------------------------

IF OBJECT_ID('dbo.api_audit_log') IS NULL
BEGIN
  CREATE TABLE dbo.api_audit_log (
    audit_id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_api_audit_log PRIMARY KEY,
    user_id INT NULL,
    action NVARCHAR(50) NOT NULL,
    entity NVARCHAR(50) NOT NULL,
    entity_key NVARCHAR(100) NULL,
    created_at DATETIME2(0) NOT NULL CONSTRAINT DF_api_audit_created_at DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_api_audit_user FOREIGN KEY (user_id) REFERENCES dbo.users(user_id)
  );
END
GO
