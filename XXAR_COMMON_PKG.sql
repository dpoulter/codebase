--------------------------------------------------------
--  DDL for Package XXAR_COMMON_PKG
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE "XXAR_COMMON_PKG" 
AS

/*
+==========================================================================+
|  $Header: /source/iam/oracle/custom/package\040body/XXAR_COMMON_PKG.sql,v 1.1 2014/12/10 14:20:36 poultd10 Exp $
|
|  DESCRIPTION
|
| Date       Author      Description
| =======    ==========  ================================================
| 24-Jan-14  Dale Poulter Initial Creation
+==========================================================================+
*/
-- ===========================================================================
--
-- PROCEDURE   : get_default_trx_type
-- Description : Get Default trx Type for Batch Source
--
-- Parameters:
--
--------------------------------------------------------------------------------

function get_default_trx_type(
    p_org_id IN ra_batch_sources_all.org_id%type,
    p_batch_source  IN ra_batch_sources_all.name%type)
      return ra_cust_trx_types_all.name%type;
-- ===========================================================================
--
-- FUNCTION   : get_transaction_source_rec
-- Description : Get Transaction Source details from a source name
--
-- Parameters:
--
--------------------------------------------------------------------------------
FUNCTION get_transaction_source_rec (
            p_org_id                   IN  hr_organization_units.organization_id%TYPE
           ,p_name                     IN  ra_batch_sources.name%TYPE)
  RETURN ra_batch_sources%ROWTYPE ;

-- ===========================================================================
--
-- FUNCTION   : get_location_rec
-- Description : Get record from hz_locations for original System reference
--
-- Parameters:   p_orig_system_ref  original System reference
--
--------------------------------------------------------------------------------
FUNCTION get_location_rec (
            p_orig_system_ref        IN  hz_locations.orig_system_reference%type)
  RETURN hz_Locations%ROWTYPE;
-- ===========================================================================
--
-- PROCEDURE   : memo_line_id
-- Description : Get Memo Line for the memo line name and Org Id
--
-- Parameters:   org_id_p         Organization Id
--               memo_line_name_p Memo Line Name
--
--------------------------------------------------------------------------------

-- ===========================================================================
--
-- FUNCTION   : get_cust_site_rec
-- Description : Get record from hz_cust_acct_sites_all

-- Parameters:   p_cust_acct_site_id  Table Id Column
--
--------------------------------------------------------------------------------
FUNCTION get_cust_site_rec (
            p_cust_acct_site_id  IN  hz_cust_acct_sites.cust_acct_site_id%type)
  RETURN hz_cust_acct_sites_all%ROWTYPE  ;

-- ===========================================================================
--
-- FUNCTION   : get_party_site_rec
-- Description : Get record from hz_party_sites

-- Parameters:   p_party_site_id
--
--------------------------------------------------------------------------------
FUNCTION get_party_site_rec (
            p_party_site_id in hz_party_sites.party_site_id%type)
  RETURN hz_party_sites%ROWTYPE ;

-- ===========================================================================
--
-- FUNCTION   : get_bill_to_site_use_rec
-- Description : Get Bill To Site use record for HZ Location Original System ref

-- Parameters:  p_location_ref HZ Location Original System ref
--
--------------------------------------------------------------------------------
FUNCTION get_bill_to_site_use_rec (
            p_location_ref in hz_locations.orig_system_reference%type)
  RETURN hz_cust_site_uses_all%ROWTYPE;

FUNCTION memo_line_id(
    org_id_p         NUMBER,
    memo_line_name_p VARCHAR2)
  RETURN NUMBER;

-- ===========================================================================
--
-- PROCEDURE   : get_tax_code
-- Description : Get Tax Code for Third party Tax name
--
-- Parameters:   p_tax_regime_code Tax Regime Code
--               p_tax_name        Third party tax name
--               p_date            Effective Date
--               p_org_id          Organization Id
--------------------------------------------------------------------------------

 FUNCTION get_tax_code(p_tax_regime_code in zx_rates_b.tax_regime_code%type
                     , p_tax_name in varchar2
                     , p_date in date
                     , p_org_id in number)
    RETURN zx_rates_b.tax_rate_code%type;

-- ===========================================================================
--
-- PROCEDURE   : get_payment_method_id
-- Description : Get Payment Method ID
--
-- Parameters:   p_proc Calling Procedure Name
--
--------------------------------------------------------------------------------

 FUNCTION get_payment_method_id(p_pay_method VARCHAR2)
    RETURN ar_receipt_methods.receipt_method_id%type;

-- ===========================================================================
--
-- PROCEDURE   : get_cust_receipt_method
-- Description : Get Customer Receipt Method
--
-- Parameters:   p_proc Calling Procedure Name
--
--------------------------------------------------------------------------------

 FUNCTION get_cust_receipt_method(p_customer_id IN NUMBER,
			                            p_site_use_id IN NUMBER DEFAULT null,
				                          p_pay_method_id IN NUMBER DEFAULT null)
    RETURN ra_cust_receipt_methods.CUST_RECEIPT_METHOD_ID%type ;
-- ===========================================================================
--
-- PROCEDURE   : insert_interface_line
-- Description : Insert record into ra_interface_lines_all
--
-- Parameters:
--
--------------------------------------------------------------------------------


PROCEDURE insert_interface_line(
             p_interface_line_rec          IN ra_interface_lines_all%ROWTYPE
            ,x_return_status               OUT VARCHAR2);

END xxar_common_pkg ;
