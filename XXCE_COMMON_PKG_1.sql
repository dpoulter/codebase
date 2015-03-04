--------------------------------------------------------
--  DDL for Package Body XXCE_COMMON_PKG
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "XXCE_COMMON_PKG" 
AS

/*
+==========================================================================+
|  $Header: /source/iam/oracle/custom/package\040body/XXCE_COMMON_PKG_1.sql,v 1.1 2014/12/10 14:20:36 poultd10 Exp $
|
|  DESCRIPTION Cash Management Common Function and Procedures
|
| Date       Author      Description
| =======    ==========  ================================================
| 19-Jun-14  Dale Poulter  Initial Creation
+==========================================================================+
*/

--------------------------------------------------------------------------------
----- Global Variables
--------------------------------------------------------------------------------
g_pkg           varchar2(30) := 'xxce_common_pkg';

--------------------------------------------------------------------------------
----- Private Procedures
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
----- Public Procedures
--------------------------------------------------------------------------------

-- ===========================================================================
--
-- PROCEDURE   : BANK_TRX_TYPES_FN
-- Description : Get Transaction Type
--
-- Parameters:
--------------------------------------------------------------------------------
  FUNCTION BANK_TRX_TYPES_FN(bank_account_id_cp IN ce_transaction_codes.bank_account_id%TYPE,
                             trx_code_cp        IN ce_transaction_codes.trx_code%TYPE,
                             trx_type_cp        IN ce_transaction_codes.trx_type%TYPE,
                             reconcile_flag_cp  IN ce_transaction_codes.reconcile_flag%TYPE)
    RETURN BOOLEAN AS
    CURSOR trx_types(bank_account_id_cp ce_transaction_codes.bank_account_id%TYPE, trx_code_cp ce_transaction_codes.trx_code%TYPE) IS
      SELECT trx_type
        FROM ce_transaction_codes
       WHERE bank_account_id = bank_account_id_cp
         AND trx_code = trx_code_cp;

    trx_types_cv       trx_types%ROWTYPE;
    trx_description_lv xxicl_ce_trx_codes_mapping.description%TYPE;
    l_proc             varchar2(30) := 'BANK_TRX_TYPES_FN';

  BEGIN


   -- debug
   xx_appl_common_pkg.write_log(g_pkg, l_proc, 'parameters: bank_account_id_cp='||bank_account_id_cp||
                                               ', trx_code_cp'||trx_code_cp||
                                               ', trx_type_cp'||trx_type_cp||
                                               ', reconcile_flag_cp'||reconcile_flag_cp);

    OPEN trx_types(bank_account_id_cp, trx_code_cp);
    FETCH trx_types
      INTO trx_types_cv;
    CLOSE trx_types;

    IF trx_types_cv.trx_type IS NOT NULL THEN

      RETURN TRUE;

    ELSE
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                        trx_code_cp ||
                        ': This Transaction Code (Charge Type) Does Not Exists In The System');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                        trx_code_cp ||
                        ': This Transaction Code (Charge Type) Does Not Exists In The System');

      RETURN FALSE;

    END IF;

    --
    RETURN FALSE;

  END BANK_TRX_TYPES_FN;

-- ===========================================================================
--
-- PROCEDURE   : check_statement_exists
-- Description : Check Statement Exists
--
-- Parameters:
--------------------------------------------------------------------------------
FUNCTION check_statement_exists( bank_account_num_p IN ce_statement_headers_int.bank_account_num%TYPE
                                     , bank_account_id_p  IN ce_statement_headers.bank_account_id%TYPE
                                     , statement_number_p IN ce_statement_headers.statement_number%TYPE
                                     , org_id_p    IN ce_statement_headers.org_id%TYPE
                                      ) RETURN number IS

statement_header_id_ln       ce_statement_headers.statement_header_id%TYPE;
statement_number_ln          ce_statement_headers.statement_number%TYPE;

CURSOR statement_exists( bank_account_id_cp  IN ce_statement_headers.bank_account_id%TYPE
                       , statement_number_cp IN ce_statement_headers.statement_number%TYPE
                       , org_id_cp   IN ce_statement_headers.org_id%TYPE
                       ) IS
   SELECT statement_header_id
   FROM   ce_statement_headers
   WHERE  bank_account_id = bank_account_id_cp
   AND    statement_number = statement_number_cp;

CURSOR statement_exists_in_intf( bank_account_num_p IN ce_statement_headers_int.bank_account_num%TYPE
                               , statement_number_p IN ce_statement_headers.statement_number%TYPE
                               , org_id_cp   IN ce_statement_headers.org_id%TYPE
                       ) IS
   SELECT cesh.statement_number
   FROM   ce_statement_headers_int cesh
   WHERE  cesh.bank_account_num = bank_account_num_p
   AND    cesh.statement_number = statement_number_p;

   l_proc             VARCHAR2 (30)   := 'statement_exists';
   l_count number;
BEGIN

   OPEN statement_exists(bank_account_id_p
                       , statement_number_p
                       , org_id_p);
   FETCH statement_exists
   INTO statement_header_id_ln;
   CLOSE statement_exists;

    xx_appl_common_pkg.write_log(g_pkg,l_proc, 'statement_header_id_ln ='||statement_header_id_ln);

   IF statement_header_id_ln IS NOT NULL THEN
      RETURN -999999; -- Statement Already Exists in The System
   ELSE
     OPEN statement_exists_in_intf( bank_account_num_p
                                  , statement_number_p
                                  , org_id_p);
     FETCH statement_exists_in_intf
     INTO statement_number_ln;
     CLOSE statement_exists_in_intf;

     xx_appl_common_pkg.write_log(g_pkg,l_proc, 'statement_number_ln ='||statement_number_ln);

     IF statement_number_ln IS NOT NULL THEN

        RETURN -333333; -- Statement Already Exists in The Oracel Statements Interface
     END IF;

   END IF;

   RETURN null; -- Statement Does NOT Exist in the System OR Interface

   EXCEPTION
      WHEN OTHERS THEN
      xx_appl_common_pkg.write_log(g_pkg,l_proc, 'Oracle Error: '||sqlerrm,true);
      return -1;

END check_statement_exists;

-- ===========================================================================
--
-- PROCEDURE   : Retrieve_Foreign_Cur_del
-- Description : Retrieve Foreign Cur del
--
-- Parameters:
--------------------------------------------------------------------------------
procedure Retrieve_Foreign_Cur_del (p_bank_acc_num in ce_bank_accounts.bank_account_num%type
                                   ,p_currency_code in ce_bank_accounts.currency_code%type
                                   ,p_org_id in ce_bank_accounts.account_owner_org_id%type
                                   ,p_rate_type out ce_system_parameters.cashflow_exchange_rate_type%type
                                   ,p_foreign_cur_flag out varchar2
                                   ) is
-- Cursor c_curr
cursor c_curr(cp_ledger_id in gl_ledgers.ledger_id%type
             ,cp_bank_acc_num in ce_bank_accounts.bank_account_num%type
             ,cp_currency_code in ce_bank_accounts.currency_code%type) is
SELECT a.currency_code
    ,  csp.cashflow_exchange_rate_type
FROM   gl_ledgers a
,      ce_bank_accounts b
,      ce_system_parameters csp
WHERE  a.ledger_id = csp.set_of_books_id
AND    b.account_classification = 'INTERNAL'
AND    NVL(b.end_date, SYSDATE) >= SYSDATE
AND    b.currency_code  = cp_currency_code
AND    b.bank_account_num = cp_bank_acc_num
and    a.ledger_id =cp_ledger_id;

--Local Variables
l_currency_code               VARCHAR2(3)  := NULL;
l_foreign_curr_flag           VARCHAR2(1)  := 'N';
l_proc                        varchar2(30) := 'Retrieve_Foreign_Cur_del';

l_ledger_id                   gl_ledgers.ledger_id%type;

BEGIN

  --Get Ledger Id
  l_ledger_id := xx_appl_common_pkg.get_ledger_id(p_org_id);

  --Get Ledger currency
  open c_curr(cp_ledger_id => l_ledger_id
             ,cp_bank_acc_num => p_bank_acc_num
             ,cp_currency_code => p_currency_code
             );
  fetch c_curr into l_currency_code, p_rate_type;
  close c_curr;

  -- If Ledger currency is not the same as the statement line currency
  -- tForeign Currency Flag
  IF l_currency_code != p_currency_code THEN
     p_foreign_cur_flag := 'Y';
  END IF;

EXCEPTION
  WHEN OTHERS THEN
      xx_appl_common_pkg.write_log(g_pkg,l_proc, 'Oracle Error: '||sqlerrm,true);
      raise;
END;


END xxce_common_pkg;
