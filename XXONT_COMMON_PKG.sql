--------------------------------------------------------
--  DDL for Package XXONT_COMMON_PKG
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE "XXONT_COMMON_PKG" 
AS

/*
+==========================================================================+
|  $Header: /source/iam/oracle/custom/package\040body/XXONT_COMMON_PKG.sql,v 1.1 2014/12/10 14:20:36 poultd10 Exp $
|
|  DESCRIPTION
|
| Date       Author      Description
| ========== ==========  ==================================================
| 23-Jul-14  DPoulter    Initial Creation
+==========================================================================+
*/

--------------------------------------------------------------------------------
----- Global Variables
--------------------------------------------------------------------------------


-- ===========================================================================
--
-- FUNCTION   : get_cust_po_num
-- Description : Get Customer PO Number on Order Header
--
-- Parameters:   p_header_id Order Header Id
--
--------------------------------------------------------------------------------

FUNCTION get_cust_po_num(
    p_header_id IN oe_order_headers_all.header_id%type)
            return oe_order_headers.cust_po_number%type;
-- ===========================================================================
--
-- FUNCTION   : get_requestor
-- Description : Get Requestor for internal sales order
--
-- Parameters:   p_header_id Order Header Id
--
--------------------------------------------------------------------------------

  FUNCTION get_requestor(p_header_id IN oe_order_headers_all.header_id%type) RETURN CHAR;
-- ===========================================================================
--
-- FUNCTION   : get_requestor_email
-- Description : Get Requestor Email Address for internal sales order
--
-- Parameters:   p_header_id Order Header Id
--
--------------------------------------------------------------------------------

  function get_requestor_email(p_header_id in oe_order_headers_all.header_id%type) return char ;

  -- ===========================================================================
--
-- FUNCTION   : get_preparer
-- Description : Returms the full name of the person who created the
--               Internal Requisition
--
-- Parameters:   p_header_id Order Header Id
--
--------------------------------------------------------------------------------

  function get_preparer(p_header_id in oe_order_headers_all.header_id%type) return char;
-- ===========================================================================
--
-- FUNCTION   : DELIVER_TO_ADDRESS
-- Description : Return Delivery Address for Pick Slip Number.
--
-- Parameters:   p_header_id Order Header Id
--
--------------------------------------------------------------------------------

  FUNCTION DELIVER_TO_ADDRESS (p_delivery_detail_id in wsh_delivery_details.delivery_detail_id%type )
  RETURN varchar2;

END xxont_common_pkg ;
