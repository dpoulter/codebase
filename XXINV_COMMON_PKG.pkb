--------------------------------------------------------
--  DDL for Package Body XXINV_COMMON_PKG
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "XXINV_COMMON_PKG" 
AS

/*
+==========================================================================+
|             Copyright(c) company                                         |
|                             All rights reserved                          |
                                                                           |
+==========================================================================+
|  $Header: /source/iam/oracle/custom/package\040body/XXINV_COMMON_PKG_1.sql,v 1.1 2014/12/10 14:20:36 poultd10 Exp $
|
|  DESCRIPTION
|
| Date       Author      Description
| =======    ==========  ================================================
|
+==========================================================================+
*/

--------------------------------------------------------------------------------
----- Global Variables
--------------------------------------------------------------------------------
  g_pkg           varchar2(30) := 'xxinv_common_pkg';
  g_entering      varchar2(30) := 'Entering ';



--------------------------------------------------------------------------------
----- Private Procedures
--------------------------------------------------------------------------------

-- ===========================================================================
--
-- PROCEDURE   : write_log
-- Description : Writes log messages to fnd_log_messages for debugging
--
-- Parameters:   p_proc Calling Procedure Name
--
--------------------------------------------------------------------------------

PROCEDURE write_log(
    p_proc IN VARCHAR2,
    p_msg  IN VARCHAR2)
IS
BEGIN
  IF( FND_LOG.LEVEL_statement >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) THEN
    dbms_output.put_line(g_pkg||'.'||p_proc||':'|| p_msg);
    fnd_log.STRING(log_level => fnd_log.level_statement ,module => g_pkg||'.'||p_proc ,MESSAGE => p_msg);
  END IF;
END write_log;

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
  RETURN NUMBER
IS
  CURSOR available_qty_cu (organization_id_cp mtl_parameters.ORGANIZATION_ID%TYPE
                         , inventory_item_id_cp mtl_system_items.inventory_item_id%TYPE
                         , subinventory_code_cp mtl_secondary_inventories.secondary_inventory_name%TYPE)
  IS
      SELECT  SUM(qty) qty
      FROM
        -- On Hand Qty
        (SELECT
         SUM(moqd.transaction_quantity) qty
        FROM mtl_onhand_quantities_detail moqd
        INNER JOIN mtl_secondary_inventories msi
        ON moqd.organization_id          = msi.organization_id
        AND msi.secondary_inventory_name = moqd.subinventory_code
        WHERE moqd.inventory_item_id     =inventory_item_id_cp
        AND moqd.organization_id         = organization_id_cp
        AND (moqd.subinventory_code      =subinventory_code_cp
        OR subinventory_code_cp         IS NULL)
        AND msi.reservable_type          =1
      UNION ALL
      --Reservations
      SELECT
        SUM (-mr.primary_reservation_quantity) reservation_quantity
      FROM mtl_reservations mr
      LEFT OUTER JOIN oe_order_lines_all ool
      ON mr.demand_source_line_id = ool.line_id
      AND mr.demand_source_type_id=8
      WHERE mr.inventory_item_id  =inventory_item_id_cp
      AND mr.organization_id      = organization_id_cp
      AND ( mr.subinventory_code  =subinventory_code_cp
      OR mr.subinventory_code    IS NULL
      OR subinventory_code_cp    IS NULL )
      UNION ALL
      --Internal Requisition in Progress
      SELECT
        SUM(-prd.req_line_quantity)
      FROM po_requisition_lines_all prl
      INNER JOIN po_requisition_headers_all prh
      ON prl.requisition_header_id = prh.requisition_header_id
      INNER JOIN po_req_distributions_all prd
      ON prl.requisition_line_id              = prd.requisition_line_id
      WHERE prl.source_type_code              = 'INVENTORY'
      AND NVL(prl.transferred_to_oe_flag,'N') = 'N'
      AND NVL (prl.cancel_flag,'N')           = 'N'
      AND NVL(prh.transferred_to_oe_flag,'N') = 'N'
      AND NVL (prh.cancel_flag,'N')           = 'N'
      AND prh.authorization_status           IN ('APPROVED','IN PROCESS')
      AND prl.item_id                         = inventory_item_id_cp
      AND prl.source_organization_id          = organization_id_cp
      AND ( prl.source_subinventory           =subinventory_code_cp
      OR prl.source_subinventory             IS NULL
      OR prl.source_subinventory              = 'Any'
      OR subinventory_code_cp                IS NULL )
        ) ;
    available_ln NUMBER;
  BEGIN
    OPEN available_qty_cu (ORGANIZATION_ID_CP => organization_id_p
                          ,inventory_item_id_cp => inventory_item_id_p
                          ,subinventory_code_cp => subinventory_code_p );
    FETCH available_qty_cu INTO available_ln;
    CLOSE available_qty_cu;
    RETURN NVL ( available_ln,0 ) ;
  END net_supply_demand;

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
  RETURN VARCHAR2
AS
  CURSOR material_status_cu1 ( serial_number_cp mtl_unit_transactions.serial_number%TYPE
                             , top_update_date_cp mtl_material_status_history.creation_date%TYPE)
  IS
    SELECT mms.status_code
    FROM
      (SELECT mmsh.serial_number,
        mmsh.status_id,
        row_number() over (partition BY mmsh.serial_number order by mmsh.status_update_id DESC) rownr
      FROM mtl_material_status_history mmsh
      WHERE mmsh.serial_number = serial_number_cp
      AND mmsh.creation_date  <= top_update_date_cp
      ) details
  INNER JOIN mtl_material_statuses mms
  ON details.status_id = mms.status_id
  WHERE details.rownr  =1;

  CURSOR material_status_cu2 ( serial_number_cp mtl_unit_transactions.serial_number%TYPE)
  IS
    SELECT mms.status_code
    FROM mtl_serial_numbers msn
    LEFT OUTER JOIN mtl_material_statuses mms
    ON msn.status_id        = mms.status_id
    WHERE msn.serial_number = serial_number_cp;

  material_status_lc mtl_material_statuses.status_code%TYPE;
  l_proc varchar2(30) := 'material_status';
BEGIN

  if top_update_date_p is not null then
      OPEN material_status_cu1 (serial_number_cp => serial_number_p, top_update_date_cp => top_update_date_p);
      FETCH material_status_cu1 INTO material_status_lc;
      CLOSE material_status_cu1;
  else
      OPEN material_status_cu2 (serial_number_cp => serial_number_p);
      FETCH material_status_cu2 INTO material_status_lc;
      CLOSE material_status_cu2;
  end if;

  RETURN material_status_lc;

exception when others then
  write_log( l_proc, 'Oracle error ' || SQLERRM );
  --RETURN NULL;
  raise;
END material_status;

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
  RETURN mtl_system_items_b%ROWTYPE IS

l_proc VARCHAR2(100) := 'get_item_details';

CURSOR c_item ( cp_inventory_item_id  IN mtl_system_items_b.inventory_item_id%TYPE
               ,cp_inv_org_id         IN mtl_system_items_b.organization_id%TYPE) IS
  SELECT *
  FROM  mtl_system_items_b
  WHERE inventory_item_id = cp_inventory_item_id
  AND   organization_id   = cp_inv_org_id;

l_item  c_item%ROWTYPE;

BEGIN
  write_log(l_proc,g_entering||l_proc);

  OPEN c_item(cp_inventory_item_id => p_inventory_item_id
             ,cp_inv_org_id        => p_inv_org_id);
  FETCH c_item INTO l_item;
  IF c_item%NOTFOUND THEN
    write_log(l_proc,'ERROR: Could not find Item Details for Item Id: '
                           ||p_inventory_item_id
                           ||', and Org Id: '
                           ||p_inv_org_id);
  END IF;
  CLOSE c_item;

  RETURN(l_item);

EXCEPTION
WHEN OTHERS THEN
  write_log(l_proc, 'Oracle Error in '||l_proc||' - '||sqlerrm);
  RETURN NULL;
END get_item_details ;

-- +-------------------------------------------------------------------------+
-- |----< get_fifo_cost  >------------------------------------------------|
-- +-------------------------------------------------------------------------+
--
-- Description: Get FIFO Cost
--
-- Parameters: 
--
-- ---------------------------------------------------------------------------
FUNCTION get_fifo_cost(
           p_inventory_item_id  IN mtl_system_items_b.inventory_item_id%TYPE
          ,p_inv_org_id         IN mtl_system_items_b.organization_id%TYPE
          ,p_cost_group_id      in cst_quantity_layers.cost_group_id%type)
          
  RETURN number IS

  cursor c_layers(cp_inventory_item_id in number,
                  cp_org_id in number, 
                  cp_layer_id in number) is 
  select layer_cost
  from cst_inv_layers csl
  where csl.inventory_item_id = cp_inventory_item_id
  and csl.organization_id = cp_org_id
  and csl.layer_id = cp_layer_id;
  
  l_proc VARCHAR2(100) := 'get_fifo_cost';
  l_layer_cost  cst_inv_layers.layer_cost%type;
  l_layer_id    cst_inv_layers.layer_id%type;

BEGIN
 
   write_log(l_proc,g_entering||l_proc);
  
   --Get Layer Cost
   select layer_id
   into l_layer_id
   from cst_quantity_layers
   where organization_id = p_inv_org_id
   and inventory_item_id = p_inventory_item_id
   and cost_group_id = p_cost_group_id;

   --Get layer
   open c_layers (  p_inventory_item_id,   p_inv_org_id,l_layer_id);
   fetch c_layers into l_layer_cost;
   close c_layers;

   return l_layer_cost;
   
EXCEPTION
WHEN OTHERS THEN
  write_log(l_proc, 'Oracle Error in '||l_proc||' - '||sqlerrm);
  RETURN NULL;
  
END get_fifo_cost ;

END xxinv_common_pkg;
