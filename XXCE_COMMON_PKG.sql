--------------------------------------------------------
--  DDL for Package XXCE_COMMON_PKG
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE "XXCE_COMMON_PKG" 
AS

/*
+==========================================================================+
|  $Header: /source/iam/oracle/custom/package\040body/XXCE_COMMON_PKG.sql,v 1.1 2014/12/10 14:20:36 poultd10 Exp $
|
|  DESCRIPTION  Cash Management Common Function and Procedures
|
| Date       Author      Description
| =======    ==========  ================================================
| 19-Jun-14  Dale Poulter  Initial Creation
+==========================================================================+
*/

-- ===========================================================================
--
-- PROCEDURE   : process_api_messages
-- Description : Process API messages and returns error message
--
-- Parameters:   p_msg_count API message count
--               p_msg_data  API message data
--               p_err_msg   Output parameter containing error message
--
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
    RETURN BOOLEAN ;

-- ===========================================================================
--
-- PROCEDURE   : check_statement_exists
-- Description : Check Statement Exists
--
-- Parameters:
--------------------------------------------------------------------------------
FUNCTION check_statement_exists(       bank_account_num_p IN ce_statement_headers_int.bank_account_num%TYPE
                                     , bank_account_id_p  IN ce_statement_headers.bank_account_id%TYPE
                                     , statement_number_p IN ce_statement_headers.statement_number%TYPE
                                     , org_id_p    IN ce_statement_headers.org_id%TYPE
                                      ) RETURN number;


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
                                   );
END xxce_common_pkg ;
