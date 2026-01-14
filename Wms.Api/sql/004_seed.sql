/* ============================================================
   004_seed.sql
   - Seed initial data for local testing
   ============================================================ */

-- USE WmsDb;
USE WmsDb;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

-- Roles
IF NOT EXISTS (SELECT 1 FROM dbo.roles WHERE role_code='ADMIN')
  INSERT INTO dbo.roles(role_code, role_name) VALUES ('ADMIN','Administrator');

IF NOT EXISTS (SELECT 1 FROM dbo.roles WHERE role_code='OPERATOR')
  INSERT INTO dbo.roles(role_code, role_name) VALUES ('OPERATOR','Operator');

-- User
IF NOT EXISTS (SELECT 1 FROM dbo.users WHERE username='admin')
BEGIN
  INSERT INTO dbo.users(username, password_hash, display_name, email)
  VALUES ('admin', NULL, 'Admin', 'admin@local');
END

DECLARE @admin_id INT = (SELECT user_id FROM dbo.users WHERE username='admin');
DECLARE @admin_role_id INT = (SELECT role_id FROM dbo.roles WHERE role_code='ADMIN');

IF NOT EXISTS (SELECT 1 FROM dbo.user_roles WHERE user_id=@admin_id AND role_id=@admin_role_id)
  INSERT INTO dbo.user_roles(user_id, role_id) VALUES (@admin_id, @admin_role_id);

-- Warehouse
IF NOT EXISTS (SELECT 1 FROM dbo.warehouses WHERE warehouse_code='WH-01')
  INSERT INTO dbo.warehouses(warehouse_code, warehouse_name, address) VALUES ('WH-01','Main Warehouse',NULL);

DECLARE @wh_id INT = (SELECT warehouse_id FROM dbo.warehouses WHERE warehouse_code='WH-01');

-- Locations
IF NOT EXISTS (SELECT 1 FROM dbo.locations WHERE warehouse_id=@wh_id AND location_code='BIN-001')
  INSERT INTO dbo.locations(warehouse_id, location_code, location_type) VALUES (@wh_id,'BIN-001','BIN');

IF NOT EXISTS (SELECT 1 FROM dbo.locations WHERE warehouse_id=@wh_id AND location_code='BIN-002')
  INSERT INTO dbo.locations(warehouse_id, location_code, location_type) VALUES (@wh_id,'BIN-002','BIN');

-- Demo item
IF NOT EXISTS (SELECT 1 FROM dbo.items WHERE sku='SKU-001')
  INSERT INTO dbo.items(sku, item_name, uom, barcode) VALUES ('SKU-001','Keyboard','PCS',NULL);
