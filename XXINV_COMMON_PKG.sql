--------------------------------------------------------
--  DDL for Package XXINV_COMMON_PKG
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE "XXINV_COMMON_PKG" 
AS

/*
+==========================================================================+
|  $Header: /source/iam/oracle/custom/package\040body/XXINV_COMMON_PKG.sql,v 1.1 2014/12/10 14:20:36 poultd10 Exp $
|
|  DESCRIPTION
|
| Date       Author      Description
| =======    ==========  ================================================
|
+==========================================================================+
*/


-- ===========================================================================
--
-- FUNCTION   : net_supply_demand
-- Description : Net Supply and Demand for Inventory Item
--
-- Parameters:   organization_id_p Inventory Organization Id
--               inventory_item_id_p Inventory item Id
--               subinventory_code_p Subvinventory Code
--------------------------------------------------------------------------------

FUNCTION net_supply_demand(
    organization_id_p mtl_parameters.ORGANIZATION_ID%TYPE,
    inventory_item_id_p mtl_system_items.inventory_item_id%TYPE,
    subinventory_code_p mtl_secondary_inventories.secondary_inventory_name%TYPE := NULL)
  RETURN NUMBER;

-- ===========================================================================
--
-- FUNCTION   : material_status
-- Description : Get Material Status for Serial Item at the date of Top Update Date
--                . If Top Update Date is null then return current status.

-- Parameters:   serial_number_p Item Serial Number
--               top_update_date_p Latest Update date of the Material status.
--------------------------------------------------------------------------------
FUNCTION material_status(
    serial_number_p mtl_unit_transactions.serial_number%TYPE,
    top_update_date_p mtl_material_status_history.creation_date%TYPE default null)
  RETURN VARCHAR2;

-- +-------------------------------------------------------------------------+
-- |----< get_item_details  >------------------------------------------------|
-- +-------------------------------------------------------------------------+
--
-- Description: Get item record
--
--
--
-- ---------------------------------------------------------------------------
FUNCTION get_item_details(
           p_inventory_item_id  IN mtl_system_items_b.inventory_item_id%TYPE
          ,p_inv_org_id         IN mtl_system_items_b.organization_id%TYPE)
  RETURN mtl_system_items_b%ROWTYPE ;

END xxinv_common_pkg ;
