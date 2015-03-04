--------------------------------------------------------
--  DDL for Package Body XXAR_COMMON_PKG
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "XXAR_COMMON_PKG" 
AS

/*
+==========================================================================+
|  $Header: /source/iam/oracle/custom/package\040body/XXAR_COMMON_PKG_1.sql,v 1.1 2014/12/10 14:20:36 poultd10 Exp $
|
|  DESCRIPTION
|
| Date       Author      Description
| =======    ==========  ================================================
| 24-Jan-14  Dale Poulter Initial Creation
+==========================================================================+
*/

--------------------------------------------------------------------------------
----- Global Variables
--------------------------------------------------------------------------------
  g_pkg           varchar2(30) := 'xxar_common_pkg';



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
-- FUNCTION   : get_default_trx_type
-- Description : Get Default trx Type for Batch Source
--
-- Parameters:
--
--------------------------------------------------------------------------------

function get_default_trx_type(
    p_org_id IN ra_batch_sources_all.org_id%type,
    p_batch_source  IN ra_batch_sources_all.name%type)
      return ra_cust_trx_types_all.name%type is

   cursor default_trx_type(
    cp_org_id ra_batch_sources_all.org_id%type,
    cp_batch_source  ra_batch_sources_all.name%type) is
      select a.name
      from ra_batch_sources_all      b,
           ra_cust_trx_types_all     a
      where
      b.name = cp_batch_source
      and b.org_id = cp_org_id
      and a.cust_trx_type_id = b.default_inv_trx_type;

    l_trx_type_name ra_cust_trx_types_all.name%type;

begin
    open default_trx_type(cp_org_id => P_org_id
                         ,cp_batch_source => p_batch_source);
    fetch default_trx_type into l_trx_type_name;
    close default_trx_type;

    return l_trx_type_name;

  end get_default_trx_type;

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
  RETURN ra_batch_sources%ROWTYPE IS

l_proc VARCHAR2(100) := 'get_transaction_source_rec';

CURSOR c_trx_source (cp_org_id IN  hr_organization_units.organization_id%TYPE
                    ,cp_name   IN  ra_batch_sources.name%TYPE)  IS
 SELECT rbs.*
 FROM  ra_batch_sources_all rbs
 WHERE NVL(rbs.status,'A') = 'A'
 AND   rbs.name   = cp_name
 AND   rbs.org_id = cp_org_id;

l_transaction_source_rec  c_trx_source%ROWTYPE;

BEGIN

 OPEN c_trx_source (cp_org_id => p_org_id
                   ,cp_name   => p_name);
 FETCH c_trx_source INTO l_transaction_source_rec;
 CLOSE c_trx_source;

 RETURN(l_transaction_source_rec);

EXCEPTION
WHEN OTHERS THEN
  RETURN(NULL);
END get_transaction_source_rec;

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
  RETURN hz_Locations%ROWTYPE IS

  l_proc VARCHAR2(100) := 'get_location_rec';

  cursor c_location (cp_orig_system_ref in hz_locations.orig_system_reference%type) is
  select *
  from hz_locations
  where orig_system_reference = cp_orig_system_ref;

  r_location  c_location%ROWTYPE;

BEGIN

 OPEN c_location (p_orig_system_ref);
 FETCH c_location INTO r_location;
 CLOSE c_location;

 RETURN(r_location);

EXCEPTION
WHEN OTHERS THEN
  RETURN(NULL);
END get_location_rec;

-- ===========================================================================
--
-- FUNCTION   : get_cust_site_rec
-- Description : Get record from hz_cust_acct_sites_all

-- Parameters:   p_cust_acct_site_id  Table Id Column
--
--------------------------------------------------------------------------------
FUNCTION get_cust_site_rec (
            p_cust_acct_site_id  IN  hz_cust_acct_sites.cust_acct_site_id%type)
  RETURN hz_cust_acct_sites_all%ROWTYPE IS

  l_proc VARCHAR2(100) := 'get_cust_site_rec';

  cursor c_site (cp_cust_acct_site_id in hz_cust_acct_sites.cust_acct_site_id%type) is
  select *
  from hz_cust_acct_sites_all
  where cust_acct_site_id = cp_cust_acct_site_id;

  r_site  c_site%ROWTYPE;

BEGIN

 OPEN c_site (p_cust_acct_site_id);
 FETCH c_site INTO r_site;
 CLOSE c_site;

 RETURN(r_site);

EXCEPTION
WHEN OTHERS THEN
  RETURN(NULL);
END get_cust_site_rec;

-- ===========================================================================
--
-- FUNCTION   : get_cust_site_rec
-- Description : Get record from hz_cust_acct_sites_all

-- Parameters:   p_site_use_id
--
--------------------------------------------------------------------------------
FUNCTION get_cust_site_rec (
            p_site_use_id in hz_cust_site_uses_all.site_use_id%type)
  RETURN hz_cust_acct_sites_all%ROWTYPE IS

  l_proc VARCHAR2(100) := 'get_cust_site_rec';

cursor c_site_ref (cp_site_use_id in hz_cust_site_uses_all.site_use_id%type) is
  select hcas.*
  from hz_cust_acct_sites_all hcas,
       hz_cust_site_uses_all hcsu
  where hcas.cust_acct_site_id = hcsu.cust_acct_site_id
  and hcsu.site_use_id = cp_site_use_id;

  r_site  c_site_ref%ROWTYPE;

BEGIN

 OPEN c_site_ref (p_site_use_id);
 FETCH c_site_ref INTO r_site;
 CLOSE c_site_ref;

 RETURN(r_site);

EXCEPTION
WHEN OTHERS THEN
  RETURN(NULL);
END get_cust_site_rec;

-- ===========================================================================
--
-- FUNCTION   : get_party_site_rec
-- Description : Get record from hz_party_sites

-- Parameters:   p_party_site_id
--
--------------------------------------------------------------------------------
FUNCTION get_party_site_rec (
            p_party_site_id in hz_party_sites.party_site_id%type)
  RETURN hz_party_sites%ROWTYPE IS

  l_proc VARCHAR2(100) := 'get_party_site_rec';

cursor c_site_ref (cp_party_site_id in hz_party_sites.party_site_id%type) is
  select *
  from hz_party_sites
  where party_site_id = cp_party_site_id;

  r_site  c_site_ref%ROWTYPE;

BEGIN

 OPEN c_site_ref (p_party_site_id);
 FETCH c_site_ref INTO r_site;
 CLOSE c_site_ref;

 RETURN(r_site);

EXCEPTION
WHEN OTHERS THEN
  RETURN(NULL);
END get_party_site_rec;

-- ===========================================================================
--
-- FUNCTION   : get_bill_to_site_use_rec
-- Description : Get Bill To Site use record for HZ Location Original System ref

-- Parameters:  p_location_ref HZ Location Original System ref
--
--------------------------------------------------------------------------------
FUNCTION get_bill_to_site_use_rec (
            p_location_ref in hz_locations.orig_system_reference%type)
  RETURN hz_cust_site_uses_all%ROWTYPE IS

  cursor c_site (cp_location_ref  in hz_locations.orig_system_reference%type ) is
  select hcsu.*
  from hz_cust_acct_sites_all hcas,
       hz_cust_site_uses_all hcsu,
       hz_party_sites hps,
       hz_locations hl
  where hcas.cust_acct_site_id = hcsu.cust_acct_site_id
  and hcas.party_site_id = hps.party_site_id
  and hps.location_id = hl.location_id
  and hcsu.site_use_code='BILL_TO'
  and hl.orig_system_reference = cp_location_ref;


  l_proc VARCHAR2(100) := 'get_bill_to_site_use_rec';
   r_site  c_site%ROWTYPE;

BEGIN

 OPEN c_site (p_location_ref);
 FETCH c_site INTO r_site;
 CLOSE c_site;

 RETURN(r_site);

EXCEPTION
WHEN OTHERS THEN
  RETURN(NULL);
END get_bill_to_site_use_rec;


-- ===========================================================================
--
-- PROCEDURE   : memo_line_id
-- Description : Get Memo Line for the memo line name and Org Id
--
-- Parameters:   org_id_p         Organization Id
--               memo_line_name_p Memo Line Name
--
--------------------------------------------------------------------------------
FUNCTION memo_line_id(
    org_id_p         NUMBER,
    memo_line_name_p VARCHAR2)
  RETURN NUMBER
IS
  memo_line_id_ln NUMBER;
BEGIN
  SELECT memo_line_id
  INTO memo_line_id_ln
  FROM ar_memo_lines_all_tl a
  WHERE org_id = org_id_p
  AND NAME     = memo_line_name_p
  AND LANGUAGE = 'US';
  RETURN memo_line_id_ln;
EXCEPTION
WHEN NO_DATA_FOUND THEN
  RETURN NULL;
END memo_line_id;
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
    RETURN zx_rates_b.tax_rate_code%type IS
    l_tax_code zx_rates_b.tax_rate_code%type;

 BEGIN
     select tax_rate_code
     into l_tax_code
     from zx_rates_b
     where tax_regime_code=p_tax_regime_code
     and tax_status_code='STANDARD'
     and active_flag='Y'
     and tax_class='OUTPUT'
     and p_date between effective_from and nvl(effective_to,p_date)
     and attribute1=p_tax_name;

      RETURN l_tax_code;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN null;
  END get_tax_code;

-- ===========================================================================
--
-- PROCEDURE   : get_payment_method_id
-- Description : Get Payment Method ID
--
-- Parameters:   p_proc Calling Procedure Name
--
--------------------------------------------------------------------------------

 FUNCTION get_payment_method_id(p_pay_method VARCHAR2)
    RETURN ar_receipt_methods.receipt_method_id%type IS

    l_receipt_method_id RA_CUST_RECEIPT_METHODS.receipt_method_id%type;
    l_proc varchar2(30):='get_payment_method_id';

  BEGIN
    select receipt_method_id
    into l_receipt_method_id
    from ar_receipt_methods
    where name=p_pay_method;
    --
    RETURN l_receipt_method_id;
    --
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      write_log(l_proc, 'Payment method not found for : '||p_pay_method);
      RETURN null;

    WHEN OTHERS THEN
      write_log(l_proc, 'Payment method not found for : '||p_pay_method);
      RAISE;

  END get_payment_method_id;

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
    RETURN ra_cust_receipt_methods.CUST_RECEIPT_METHOD_ID%type IS

    l_CUST_RECEIPT_METHOD_ID RA_CUST_RECEIPT_METHODS.CUST_RECEIPT_METHOD_ID%type;
    l_proc varchar2(30):='get_cust_receipt_method';

  BEGIN

    write_log(l_proc, 'Entering '||l_proc);

    write_log(l_proc, 'p_customer_id : '||p_customer_id||', '||
                      'p_site_use_id: '||p_site_use_id||', '||
                      'p_pay_method_id: '||p_pay_method_id);


    select CUST_RECEIPT_METHOD_ID
    into l_CUST_RECEIPT_METHOD_ID
    from ra_cust_receipt_methods
    where CUSTOMER_ID =  p_customer_id
    and SITE_USE_ID = p_site_use_id
    and RECEIPT_METHOD_ID=p_pay_method_id;
    --
    RETURN l_CUST_RECEIPT_METHOD_ID;
    --
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      write_log(l_proc, 'Customer Payment method not found');
      RETURN null;

    WHEN OTHERS THEN
      write_log(l_proc, 'Oracle Error : '||sqlerrm);
      RAISE;

  END get_cust_receipt_method;

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
            ,x_return_status               OUT VARCHAR2) IS

  l_proc VARCHAR2(30) := 'insert_interface_line';
BEGIN

 INSERT INTO ra_interface_lines_all
 VALUES p_interface_line_rec;

 x_return_status := 'S';

EXCEPTION
  WHEN OTHERS THEN
    x_return_status := 'F';
    write_log(l_proc,'Oracle Error '||sqlerrm);
END insert_interface_line;



END xxar_common_pkg;
