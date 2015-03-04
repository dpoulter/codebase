--------------------------------------------------------
--  DDL for Package Body XX_BANK_UTIL_PKG
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "XX_BANK_UTIL_PKG" 
AS

/*
+==========================================================================+
|  $Header: /source/iam/oracle/custom/package\040body/XX_BANK_UTIL_PKG.pkb,v 1.4 2015/01/20 09:22:55 deakia10 Exp $
|
|  DESCRIPTION  Bank API utility procedures
|
| Date       Author      Description
| =======    ==========  ================================================
| 17-Mar-14  D Poulter   Initial Creation
| 06-Oct-14  A Deakin    Amended c_debit_auth to add debit_auth_end check
| 18-Dec-14  A Deakin    work package 023 - Amended c_debit_auth to (trunc(sysdate) < trunc(debit_auth_end) or debit_auth_end is null) 
|                        Added assignment and Update_Iban and order by to p_swift_code
|
+==========================================================================+
*/

--------------------------------------------------------------------------------
----- Global Constants
--------------------------------------------------------------------------------
g_pkg           constant varchar2(30) := 'xx_bank_util_pkg';
g_invalid_auth  constant varchar2(30) := 'INVALID_DEBIT_AUTH';

--------------------------------------------------------------------------------
----- Procedures
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
    p_msg  IN VARCHAR2,
    p_conc in boolean default false)
IS
BEGIN
  IF( FND_LOG.LEVEL_statement >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) THEN
    fnd_log.STRING(log_level => fnd_log.level_statement ,module => g_pkg||'.'||p_proc ,MESSAGE => p_msg);
  END IF;

  if p_conc then
   fnd_file.put_line(fnd_file.log, g_pkg||'.'||p_proc||':'|| p_msg);
  end if;

    dbms_output.put_line(g_pkg||'.'||p_proc||':'|| p_msg);

END write_log;
-- ===========================================================================
--
-- PROCEDURE   : get_bank_name
-- Description : Get the Bank Name
--
-- Parameters:   p_bank_id  Bank Id
--
--------------------------------------------------------------------------------

 FUNCTION get_bank_name (p_bank_id IN hz_parties.party_id%type)
      RETURN hz_parties.party_name%type
   IS
      l_bank_name   hz_parties.party_name%type;
      l_proc      VARCHAR2 (30) := 'get_bank_name';

      CURSOR c_bank
      IS
         SELECT bankparty.party_name
           FROM hz_parties bankparty,
                hz_organization_profiles bankorgprofile,
                hz_code_assignments bankca
          WHERE bankparty.party_id = bankorgprofile.party_id
            AND bankca.owner_table_name = 'HZ_PARTIES'
            AND bankca.owner_table_id = bankparty.party_id
            AND bankca.class_category = 'BANK_INSTITUTION_TYPE'
            AND bankca.class_code IN ('BANK', 'CLEARINGHOUSE')
            AND bankparty.party_id = p_bank_id;
   BEGIN
      OPEN c_bank;

      FETCH c_bank
       INTO l_bank_name;

      CLOSE c_bank;

      RETURN l_bank_name;
   EXCEPTION
      WHEN OTHERS
      THEN
        write_log(
                                       l_proc,
                                          'Oracle error in get_bank_id: '
                                       || SQLERRM
                                      );
         RETURN NULL;
   END;

-- ===========================================================================
--
-- PROCEDURE   : get_bank_acc_rec
-- Description : Get the External bank account record
--
-- Parameters:   p_bank_account_id Bank Account Id
--
--------------------------------------------------------------------------------

 FUNCTION get_bank_acc_rec (p_bank_account_id IN iby_ext_bank_accounts.ext_bank_account_id%type)
      RETURN iby_ext_bank_accounts%rowtype
   IS
      l_bank_acc_rec  iby_ext_bank_accounts%rowtype;
      l_proc          VARCHAR2 (30) := 'get_bank_acc_rec';

      CURSOR c_bank_acc(cp_bank_account_id IN iby_ext_bank_accounts.ext_bank_account_id%type)
      IS
         SELECT *
           FROM iby_ext_bank_accounts
           where ext_bank_account_id = cp_bank_account_id;
   BEGIN
      OPEN c_bank_acc(p_bank_account_id);

      FETCH c_bank_acc
       INTO l_bank_acc_rec;

      CLOSE c_bank_acc;

      RETURN l_bank_acc_rec;
   EXCEPTION
      WHEN OTHERS
      THEN
        write_log(l_proc,'Oracle error in '||l_proc||': '||SQLERRM);
        RETURN NULL;
   END;


-- ===========================================================================
--
-- PROCEDURE   : bank_account_exists
-- Description : Check if bank account exists . Function Returns boolean .
--               Bank Account Id returned as output parameter if Bank
--              Account exists.
--
-- Parameters:   p_proc Calling Procedure Name
--
--------------------------------------------------------------------------------

FUNCTION bank_account_exists (
  p_bank_id               IN       NUMBER,
  p_bank_branch_id        IN       NUMBER,
  p_bank_account_number   IN       VARCHAR2,
  p_bank_account_tbl      OUT      tbl_bank_acc
)
  RETURN BOOLEAN
IS
  cursor c_bank_acc is
  SELECT ext_bank_account_id
  FROM iby_ext_bank_accounts
  WHERE ltrim(replace(bank_account_num,' ',''),'0') = ltrim(replace(p_bank_account_number,' ',''),'0')
  AND bank_id = p_bank_id
  AND branch_id = p_bank_branch_id;

  l_proc              VARCHAR2 (30) := 'bank_account_exists';
  l_exists            boolean;

BEGIN

  write_log(l_proc,'p_bank_id => ' || p_bank_id);
  write_log(l_proc, 'p_bank_branch_id => ' || p_bank_branch_id );
  write_log(l_proc, 'p_bank_account_number => ' || p_bank_account_number );

  open c_bank_acc;
  loop
    fetch c_bank_acc into p_bank_account_tbl(p_bank_account_tbl.count+1);
    exit when c_bank_acc%notfound ;
  end loop;
  close c_bank_acc;

  if p_bank_account_tbl.count > 0 then
    l_exists := true;
  else
    l_exists := false;
  end if;

  RETURN l_exists;

EXCEPTION
  WHEN NO_DATA_FOUND
  THEN
     RETURN FALSE;
  WHEN OTHERS THEN
     write_log(l_proc, 'Oracle error in ' || l_proc || ':' || SQLERRM );
     raise;
END bank_account_exists;

-- ===========================================================================
--
-- PROCEDURE   : bank_account_exists
-- Description : Check if bank account exists . Function Returns boolean .
--               Bank Account Id returned as output parameter if Bank
--              Account exists.
--
-- Parameters:   p_branch_number IN
--               p_bank_account_number IN
--               p_bank_account_id IN
--               p_bank_id OUT
--               p_branch_id  OUT
--------------------------------------------------------------------------------

FUNCTION bank_account_exists (
  p_country               in       varchar2,
  p_branch_number         in       varchar2,
  p_bank_account_number   IN       VARCHAR2,
  p_bank_account_id       OUT      NUMBER,
  p_bank_id               out      number,
  p_branch_id             out      number
)
  RETURN BOOLEAN
IS
  cursor c_bank_account(cp_branch_id            iby_ext_bank_accounts.branch_id%type
                       ,cp_bank_account_number  iby_ext_bank_accounts.bank_account_num%type) is
    SELECT ext_bank_account_id
    FROM iby_ext_bank_accounts iba
    WHERE iba.branch_id = cp_branch_id
    and nvl(iba.end_date,trunc(sysdate)) >= trunc(sysdate)
    and ltrim(replace(bank_account_num,' ',''),'0') = ltrim(replace(cp_bank_account_number,' ',''),'0');

  l_branches_tbl      xx_bank_util_pkg.branchlist;
  l_bank_account_id   NUMBER;
  l_bank_id           number;
  l_branch_id         number;
  i                   integer       := 1;
  l_proc              VARCHAR2 (30) := 'bank_account_exists';

BEGIN

  write_log(l_proc, 'p_branch_number => ' || p_branch_number );
  write_log(l_proc, 'p_bank_account_number => ' || p_bank_account_number );

  -- Get Bank Branch id
  write_log(l_proc, 'Get Bank Branch id' );
  xx_bank_util_pkg.get_bank_branch (
                             p_country_code => p_country
                           , p_branch_num => p_branch_number
                           , p_swift_code => null
                           , p_branches_tbl => l_branches_tbl);

  while i <= l_branches_tbl.count and (l_bank_account_id is null) loop

    l_bank_id := l_branches_tbl(i).bank_id;
    l_branch_id := l_branches_tbl(i).branch_id;

    write_log(l_proc, 'l_bank_id=> '||l_bank_id||', l_branch_id=>'|| l_branch_id);

    --Get Bank Account Id
    write_log(l_proc, 'Get Bank Account Id');
    open c_bank_account    (cp_branch_id => l_branch_id,
                            cp_bank_account_number => p_bank_account_number);
    fetch c_bank_account into l_bank_account_id;
    close c_bank_account;

    i:= i+1;

  end loop;

  write_log(l_proc, 'l_bank_account_id => ' || l_bank_account_id );

  --Set out parameters
  p_bank_account_id := l_bank_account_id;
  p_bank_id := l_bank_id;
  p_branch_id := l_branch_id;

  --Return result
  if l_bank_account_id is null then
    return false;
  else
    return true;
  end if;

EXCEPTION
  WHEN NO_DATA_FOUND
  THEN
     RETURN FALSE;
  WHEN OTHERS THEN
     write_log(l_proc, 'Oracle error in ' || l_proc || ':' || SQLERRM );
     raise;
END bank_account_exists;

-- ===========================================================================
--
-- FUNCTION   : bank_acc_assign_exists
-- Description : Check if Bank Account Assignmnent exists for the customer
--               Returns true if record is found otherwise returns false.
--
-- Parameters:   IN p_cust_account_id          Customer Account Id
--               IN p_cust_acct_site_use_id    Customer Account Site Use Id
--               IN p_bank_account_id          Bank Account Id
--               OUT p_INSTRUMENT_PAYMENT_USes Payment instrument uses record
--------------------------------------------------------------------------------

FUNCTION bank_acc_assign_exists (
  p_cust_account_id       in      number,
  p_cust_acct_site_use_id in      number,
  p_bank_account_id       IN      NUMBER,
  p_INSTRUMENT_PAYMENT_USes out iby_pmt_instr_uses_all%rowtype
)
  RETURN BOOLEAN
IS

  cursor c_bank_acc_assign_exists( cp_cust_account_id       in      number,
                                   cp_cust_acct_site_use_id in      number,
                                   cp_bank_account_id       IN      NUMBER) is
    SELECT ipiu.*
    FROM iby_pmt_instr_uses_all ipiu,
      iby_ext_bank_accounts ieba,
      iby_external_payers_all iep,
      hz_cust_site_uses_all hcsu
    WHERE ieba.ext_bank_account_id = ipiu.instrument_id
    and ipiu.ext_pmt_party_id   = iep.ext_payer_id
    and iep.org_id = hcsu.org_id
    AND iep.cust_account_id = cp_cust_account_id
    and iep.acct_site_use_id = cp_cust_acct_site_use_id
    and ieba.ext_bank_account_id = cp_bank_account_id;
  l_exists            boolean;
  l_proc              VARCHAR2 (30) := 'bank_acc_assign_exists';

BEGIN

  write_log(l_proc,'p_cust_account_id => ' || p_cust_account_id);
  write_log(l_proc, 'p_cust_acct_site_id => ' || p_cust_acct_site_use_id );
  write_log(l_proc, 'p_bank_account_id => ' || p_bank_account_id );

  open c_bank_acc_assign_exists( cp_cust_account_id => p_cust_account_id,
                                 cp_cust_acct_site_use_id=> p_cust_acct_site_use_id,
                                 cp_bank_account_id => p_bank_account_id);
  fetch c_bank_acc_assign_exists into p_INSTRUMENT_PAYMENT_USes;
  if c_bank_acc_assign_exists%found then
    l_exists := true;
  else
    l_exists:=false;
  end if;
  close c_bank_acc_assign_exists;


  write_log(l_proc, 'INSTRUMENT_PAYMENT_USE_ID => ' || p_INSTRUMENT_PAYMENT_USes.INSTRUMENT_PAYMENT_USE_ID );

  RETURN l_exists;

EXCEPTION
  WHEN NO_DATA_FOUND
  THEN
     RETURN FALSE;
  WHEN OTHERS THEN
     write_log(l_proc, 'Oracle error in ' || l_proc || ':' || SQLERRM );
     RETURN NULL;
END bank_acc_assign_exists;

-- ===========================================================================
--
-- PROCEDURE   : get_bank_branch_name
-- Description : Get the Bank Branch Name
--
-- Parameters:   p_bank_id  Bank Id
--               p_branch_id Bank branch Id
--
--------------------------------------------------------------------------------
  FUNCTION get_bank_branch_name (p_bank_id IN NUMBER, p_branch_id IN number)
      RETURN NUMBER
   IS
      l_bank_branch_name   hz_parties.party_name%type;
      l_proc               VARCHAR2 (30) := 'get_bank_branch_name';
   BEGIN
      SELECT branchparty.party_name
        INTO l_bank_branch_name
        FROM hz_parties bankparty,
             hz_parties branchparty,
             hz_organization_profiles branchorgprofile,
             ar_lookups arlookup,
             hz_relationships brrel,
             hz_code_assignments branchca,
             hz_code_assignments bankca
       WHERE branchparty.party_type = 'ORGANIZATION'
         AND branchparty.status = 'A'
         AND branchparty.party_id = branchorgprofile.party_id
         AND branchca.class_category = arlookup.lookup_type
         AND branchca.class_code = arlookup.lookup_code
         AND branchca.owner_table_name = 'HZ_PARTIES'
         AND branchca.owner_table_id = branchparty.party_id
         AND branchca.class_category = 'BANK_INSTITUTION_TYPE'
         AND branchca.class_code IN ('BANK_BRANCH', 'CLEARINGHOUSE_BRANCH')
         AND NVL (branchca.status, 'A') = 'A'
         AND brrel.object_id = bankparty.party_id
         AND branchparty.party_id = brrel.subject_id
         AND brrel.relationship_type = 'BANK_AND_BRANCH'
         AND brrel.relationship_code = 'BRANCH_OF'
         AND brrel.status = 'A'
         AND brrel.subject_table_name = 'HZ_PARTIES'
         AND brrel.subject_type = 'ORGANIZATION'
         AND brrel.object_table_name = 'HZ_PARTIES'
         AND brrel.object_type = 'ORGANIZATION'
         AND bankca.owner_table_name = 'HZ_PARTIES'
         AND bankca.owner_table_id = bankparty.party_id
         AND bankca.class_category = 'BANK_INSTITUTION_TYPE'
         AND bankparty.party_id = p_bank_id
         and branchparty.party_id = p_branch_id;

      RETURN l_bank_branch_name;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN NULL;
      WHEN OTHERS
      THEN
         write_log( l_proc, 'Oracle error in ' || l_proc || ':' || SQLERRM );
         RETURN NULL;
   END;

-- ===========================================================================
--
-- PROCEDURE   : get_bank_branch
-- Description : Get the Bank Branch. Returns Bank_id and Branch_id.
--               If the Branch number is null then checks only on SWIFT.
--               if the Swift Cod is null then use only Branch number.
--
-- Parameters:   p_country_code  Country Code
--               p_branch_num    Branch number
--               p_swift_code    SWIFT/BIC Code
--
--------------------------------------------------------------------------------
  PROCEDURE get_bank_branch (p_country_code IN varchar2
                           , p_branch_num IN varchar2 DEFAULT NULL
                           , p_swift_code IN varchar2 DEFAULT NULL
                           , p_branches_tbl out xx_bank_util_pkg.branchlist)
   IS

      l_bank_id            hz_parties.party_id%type;
      l_branch_id          hz_parties.party_id%type;
      l_sql_str            varchar2(4000);
      l_proc               VARCHAR2 (30) := 'get_bank_branch';

   BEGIN

 /*  l_sql_str := 'SELECT bankparty.party_id bank_id,
                 branchparty.party_id branch_id,
                 bankorgprofile.home_country,
                 branchorgprofile.bank_or_branch_number,
                 hcp.eft_swift_Code
            FROM hz_parties bankparty,
                 hz_parties branchparty,
                 hz_organization_profiles branchorgprofile,
                 hz_organization_profiles bankorgprofile,
                 ar_lookups arlookup,
                 hz_relationships brrel,
                 hz_code_assignments branchca,
                 hz_code_assignments bankca,
                 hz_contact_points hcp
           WHERE branchparty.party_type = ''ORGANIZATION''
             AND branchparty.status = ''A''
             AND branchparty.party_id = branchorgprofile.party_id
             AND branchca.class_category = arlookup.lookup_type
             AND branchca.class_code = arlookup.lookup_code
             AND branchca.owner_table_name = ''HZ_PARTIES''
             AND branchca.owner_table_id = branchparty.party_id
             AND branchca.class_category = ''BANK_INSTITUTION_TYPE''
             AND branchca.class_code IN (''BANK_BRANCH'', ''CLEARINGHOUSE_BRANCH'')
             AND NVL (branchca.status, ''A'') = ''A''
             and bankparty.party_id = bankorgprofile.party_id
             AND brrel.object_id = bankparty.party_id
             AND branchparty.party_id = brrel.subject_id
             AND brrel.relationship_type = ''BANK_AND_BRANCH''
             AND brrel.relationship_code = ''BRANCH_OF''
             AND brrel.status = ''A''
             AND brrel.subject_table_name = ''HZ_PARTIES''
             AND brrel.subject_type = ''ORGANIZATION''
             AND brrel.object_table_name = ''HZ_PARTIES''
             AND brrel.object_type = ''ORGANIZATION''
             AND bankca.owner_table_name = ''HZ_PARTIES''
             AND bankca.owner_table_id = bankparty.party_id
             AND bankca.class_category = ''BANK_INSTITUTION_TYPE''
             and branchparty.party_id = hcp.owner_table_id (+)
             and hcp.owner_table_name (+) = ''HZ_PARTIES''
             and hcp.contact_point_type (+) =''EFT''
             AND  SYSDATE between TRUNC(bankorgprofile.effective_start_date)
             and NVL(TRUNC(bankorgprofile.effective_end_date), SYSDATE+1)
             and bankorgprofile.home_country = '''|| p_country_code||'''';
   */

     l_sql_str :='SELECT bank_party_id,
                 branch_party_id,
                 country,
                 branch_number,
                 eft_swift_Code
            FROM ce_bank_branches_v
            where country = '''|| p_country_code||'''';

    if p_branch_num is not null then
      l_sql_str := l_sql_str || ' AND branch_number = '''|| p_branch_num||'''';
    end if;

 /*   if p_branch_num is not null then
      l_sql_str := l_sql_str || ' AND branchorgprofile.bank_or_branch_number = '''|| p_branch_num||'''';
    end if;
 */
   /* if p_swift_code is not null then
      l_sql_str := l_sql_str || ' and hcp.eft_swift_Code= '''|| p_swift_code||'''';
    end if;
    */
    if p_swift_code is not null then
      l_sql_str := l_sql_str || ' and eft_swift_Code= '''|| p_swift_code||'''';
    end if;

    l_sql_str := l_sql_str || ' order by bank_party_id ';
		  
   -- dbms_output.put_line(l_sql_str);
    execute immediate l_sql_str  bulk collect into p_branches_tbl;

    exception WHEN OTHERS then
       write_log( l_proc, 'Oracle error in ' || l_proc || ':' || SQLERRM );
       raise;
  END;


-- ===========================================================================
--
-- PROCEDURE   : get_bank_branch_swift
-- Description : Get the Bank Branch Swift Code
--
-- Parameters:   p_bank_id  Bank Id
--               p_branch_id Bank branch Id
--
--------------------------------------------------------------------------------
  FUNCTION get_bank_branch_swift (p_bank_id IN NUMBER, p_branch_id IN number)
      RETURN hz_contact_points.eft_swift_code%type
   IS
  cursor c_swift (cp_bank_id in number, cp_branch_id in number) is
    SELECT hcp.eft_swift_Code
    FROM hz_parties bankparty,
         hz_parties branchparty,
         hz_organization_profiles branchorgprofile,
         ar_lookups arlookup,
         hz_relationships brrel,
         hz_code_assignments branchca,
         hz_code_assignments bankca,
         hz_contact_points hcp
   WHERE branchparty.party_type = 'ORGANIZATION'
     AND branchparty.status = 'A'
     AND branchparty.party_id = branchorgprofile.party_id
     AND branchca.class_category = arlookup.lookup_type
     AND branchca.class_code = arlookup.lookup_code
     AND branchca.owner_table_name = 'HZ_PARTIES'
     AND branchca.owner_table_id = branchparty.party_id
     AND branchca.class_category = 'BANK_INSTITUTION_TYPE'
     AND branchca.class_code IN ('BANK_BRANCH', 'CLEARINGHOUSE_BRANCH')
     AND NVL (branchca.status, 'A') = 'A'
     AND brrel.object_id = bankparty.party_id
     AND branchparty.party_id = brrel.subject_id
     AND brrel.relationship_type = 'BANK_AND_BRANCH'
     AND brrel.relationship_code = 'BRANCH_OF'
     AND brrel.status = 'A'
     AND brrel.subject_table_name = 'HZ_PARTIES'
     AND brrel.subject_type = 'ORGANIZATION'
     AND brrel.object_table_name = 'HZ_PARTIES'
     AND brrel.object_type = 'ORGANIZATION'
     AND bankca.owner_table_name = 'HZ_PARTIES'
     AND bankca.owner_table_id = bankparty.party_id
     AND bankca.class_category = 'BANK_INSTITUTION_TYPE'
     and branchparty.party_id = hcp.owner_table_id
     and hcp.owner_table_name = 'HZ_PARTIES'
     and hcp.contact_point_type='EFT'
     AND bankparty.party_id = cp_bank_id
     and branchparty.party_id = cp_branch_id;

    l_swift_code         hz_contact_points.eft_swift_code%type;
    l_proc               VARCHAR2 (30) := 'get_bank_branch_swift';

   BEGIN
      write_log( l_proc, 'p_bank_id:' || p_bank_id || ', p_branch_id: ' || p_branch_id );

      open c_swift(p_bank_id, p_branch_id);
      fetch c_swift into l_swift_code;
      close c_swift;

      write_log( l_proc, 'l_swift_code:' || l_swift_code  );

      RETURN l_swift_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN NULL;
      WHEN OTHERS
      THEN
         write_log( l_proc, 'Oracle error in ' || l_proc || ':' || SQLERRM );
         RETURN NULL;
   END;

-- +-------------------------------------------------------------------------+
-- |----< create_bank_acc_assign>--------------------------------------------|
-- +-------------------------------------------------------------------------+
--
-- Description: Create Bank Account Assignment. First checks that the Bank
--              account is owned by the customer and creates customer as owner
--              before creating the assignment.
--
-- ---------------------------------------------------------------------------
procedure create_bank_acc_assign (
      p_acct_owner_party_id in iby_account_owners.ACCOUNT_OWNER_PARTY_ID%TYPE
     ,p_org_id              in hr_all_organization_units.organization_id%type
     ,p_cust_account_id     in hz_cust_accounts.cust_account_id%type
     ,p_bill_site_use_id    in hz_cust_site_uses_all.site_use_id%type
     ,p_bank_account_id     in hz_cust_accounts.cust_account_id%type
     ,p_start_date          in date
     ,p_assign_id           out number
     ,p_return_status       OUT VARCHAR2
     ,p_err_msg             OUT VARCHAR2)
 is

      v_payer_context_rec IBY_FNDCPT_COMMON_PUB.PayerContext_rec_type;
      v_assignment_attribs IBY_FNDCPT_SETUP_PUB.PmtInstrAssignment_rec_type;
      v_response IBY_FNDCPT_COMMON_PUB.Result_rec_type;

      --Add Joint Account owner API variables
      x_response IBY_FNDCPT_COMMON_PUB.Result_rec_type;
      X_JOINT_ACCT_OWNER_ID IBY_ACCOUNT_OWNERS.account_owner_id%type;
      x_msg_count   NUMBER;
      x_msg_data    VARCHAR2 (200);
      x_msg_dummy    VARCHAR2 (200);

      l_owner_count number;
      l_proc        VARCHAR2 (30) := 'create_bank_acc_assign';

BEGIN
   write_log( l_proc, 'Entering '||l_proc );
    --
    -- Check that the customer owns the account
    SELECT count(account_owner_id)
    INTO l_owner_count
    FROM IBY_ACCOUNT_OWNERS
    WHERE EXT_BANK_ACCOUNT_ID = p_bank_account_id
    AND account_owner_party_id = p_acct_owner_party_id;

    if l_owner_count=0 then
          IBY_EXT_BANKACCT_PUB.ADD_JOINT_ACCOUNT_OWNER(
              P_API_VERSION => 1.0,
              P_INIT_MSG_LIST => fnd_api.g_true,
              P_BANK_ACCOUNT_ID => P_BANK_ACCOUNT_ID,
              P_ACCT_OWNER_PARTY_ID => P_ACCT_OWNER_PARTY_ID,
              X_JOINT_ACCT_OWNER_ID => X_JOINT_ACCT_OWNER_ID,
              X_RETURN_STATUS => P_RETURN_STATUS,
              X_MSG_COUNT => X_MSG_COUNT,
              X_MSG_DATA => X_MSG_DATA,
              X_RESPONSE => X_RESPONSE
        );
        write_log( l_proc, 'X_JOINT_ACCT_OWNER_ID ' || X_JOINT_ACCT_OWNER_ID ,true);
        write_log( l_proc, 'X_RETURN_STATUS: '||P_RETURN_STATUS, true );

        -- debug section for Message Stack
        IF P_RETURN_STATUS != 'S' THEN
          IF x_msg_count    > 0 THEN
            FOR j IN 1 .. x_msg_count
            LOOP
              fnd_msg_pub.get ( j , FND_API.G_FALSE , x_msg_data , x_msg_dummy );
              p_err_msg := p_err_msg||( 'Msg' || TO_CHAR ( j ) || ': ' || x_msg_data );
            END LOOP;
          END IF;
        END IF;

        --Get response message
        if x_response.Result_code is not null then
          p_err_msg:= p_err_msg||', Response Code:'|| v_response.Result_code;
        end if;

       write_log( l_proc, 'Error Message: '||p_err_msg, true );
    end if;

    if l_owner_count > 0 or p_return_status = 'S' then
       --
       --
       --Payer Context
       --
        v_payer_context_rec.payment_function := 'CUSTOMER_PAYMENT';
        v_payer_context_rec.party_id         := p_acct_owner_party_id;
        v_payer_context_rec.org_type         := 'OPERATING_UNIT';
        v_payer_context_rec.org_id           := p_org_id;
        v_payer_context_rec.cust_account_id  := p_cust_account_id;
        v_payer_context_rec.account_site_id := p_bill_site_use_id;
        --
        -- assignment attributes
        --
        v_assignment_attribs.instrument.instrument_type := 'BANKACCOUNT';
        -- the external bank account id
        v_assignment_attribs.instrument.instrument_id := p_bank_account_id;
        v_assignment_attribs.start_date := p_start_date;
        v_assignment_attribs.end_date := null;
        v_assignment_attribs.priority := 1;
        -- map account to customer
        write_log( l_proc, 'map account to customer' );
        IBY_FNDCPT_SETUP_PUB.Set_Payer_Instr_Assignment (
                            p_api_version => 1.0
                          , p_init_msg_list => fnd_api.g_true
                          , p_commit => fnd_api.g_false
                          , x_return_status => p_return_status
                          , x_msg_count => x_msg_count
                          , x_msg_data => x_msg_data
                          , p_payer => v_payer_context_rec
                          , p_assignment_attribs => v_assignment_attribs
                          , x_assign_id => p_assign_id
                          , x_response => v_response );

        write_log( l_proc, 'p_assign_id ' || p_assign_id ,true);
        write_log( l_proc, 'p_return_status: '||p_return_status, true );

        -- debug section for Message Stack
        IF p_return_status != 'S' THEN
          IF x_msg_count    > 0 THEN
            FOR j IN 1 .. x_msg_count
            LOOP
              fnd_msg_pub.get ( j , FND_API.G_FALSE , x_msg_data , x_msg_dummy );
              p_err_msg := p_err_msg||( 'Msg' || TO_CHAR ( j ) || ': ' || x_msg_data );
            END LOOP;
          END IF;
        END IF;

        --Get response message
        if v_response.Result_code is not null then
          p_err_msg:= p_err_msg||', Response Code:'|| v_response.Result_code;
        end if;

        write_log( l_proc, 'Error Message: '||p_err_msg, true );

    end if;  --p_return_status = S

   EXCEPTION
      WHEN OTHERS
      THEN
         p_return_status := 'E';
         p_err_msg := 'Oracle error in ' || l_proc || ': ' || SQLERRM;
         write_log( l_proc, p_err_msg, true );

end create_bank_acc_assign;


-- +-------------------------------------------------------------------------+
-- |----< Update_Iban>-----------------------------------------------|
-- +-------------------------------------------------------------------------+
--
-- Description: update Iban
--
--
--
-- ---------------------------------------------------------------------------
    PROCEDURE Update_Iban ( p_bank_account_id IN NUMBER,
	                        p_iban            IN  VARCHAR2,     
		                    p_return_status   OUT VARCHAR2,
                            p_err_msg         OUT VARCHAR2
          )
   IS
    l_account_rec           iby_ext_bankacct_pub.extbankacct_rec_type;
    x_msg_count     NUMBER;
    x_msg_data      VARCHAR2 (200);
    x_return_status varchar2(1);
	x_msg_dummy    VARCHAR2 (200);
    x_response         iby_fndcpt_common_pub.result_rec_type;
	l_proc        VARCHAR2 (30)                    := 'update_iban';
    l_iby_ext_bank_accounts iby_ext_bank_accounts%rowtype;

BEGIN
        l_iby_ext_bank_accounts             := xx_bank_util_pkg.get_bank_acc_rec (p_bank_account_id => p_bank_account_id);
        l_account_rec.bank_account_id       := p_bank_account_id;
        l_account_rec.iban                  := p_iban;
        l_account_rec.bank_account_num      := l_iby_ext_bank_accounts.bank_account_num;
        l_account_rec.object_version_number := l_iby_ext_bank_accounts.object_version_number;
        l_account_rec.country_code          := l_iby_ext_bank_accounts.country_code;
        l_account_rec.branch_id             := l_iby_ext_bank_accounts.branch_id;
        l_account_rec.bank_id               := l_iby_ext_bank_accounts.bank_id;
        l_account_rec.bank_account_name     := l_iby_ext_bank_accounts.bank_account_name;
        l_account_rec.currency              := l_iby_ext_bank_accounts.currency_code;
        l_account_rec.start_date            := l_iby_ext_bank_accounts.start_date;
        l_account_rec.end_date              := l_iby_ext_bank_accounts.end_date;

        
		iby_ext_bankacct_pub.update_ext_bank_acct(
                      p_api_version            => '1.0',
                      p_init_msg_list          => 'T',
                      p_ext_bank_acct_rec      => l_account_rec,
                      x_return_status          => p_return_status,
                      x_msg_count              => x_msg_count,
                      x_msg_data               => x_msg_data,
                      x_response               => x_response
					  
                    );
      write_log(l_proc,'Bank account id And IBAN = ' || TO_CHAR (p_bank_account_id)||' , '||p_iban,true);
      write_log(l_proc,'X_RETURN_STATUS = ' || p_return_status,true);
      write_log(l_proc,'X_MSG_COUNT = ' || TO_CHAR (x_msg_count));
      write_log(l_proc,'X_MSG_DATA = ' || x_msg_data);
      write_log(l_proc,'ERROR' || fnd_msg_pub.get (1, 'T'));
      write_log(l_proc,'');

      --Set error message if one exists
     -- p_err_msg := fnd_msg_pub.get (1, 'F');

      if p_return_status != 'S' then

        IF x_msg_count    > 0 THEN
          FOR j IN 1 .. x_msg_count
          LOOP
            fnd_msg_pub.get ( j , FND_API.G_FALSE , x_msg_data , x_msg_dummy );
            p_err_msg := ( 'Msg' || TO_CHAR ( j ) || ': ' || x_msg_data );
            write_log(l_proc,'p_err_msg = ' || p_err_msg,true);
          END LOOP;
        END IF;
	  END IF;
 EXCEPTION
      WHEN OTHERS
      THEN
         p_return_status := 'E';
         p_err_msg := 'Oracle error in ' || l_proc || ': ' || SQLERRM;				
				
				
END update_iban;
   
   
-- +-------------------------------------------------------------------------+
-- |----< create_bank_account>-----------------------------------------------|
-- +-------------------------------------------------------------------------+
--
-- Description: Create Bank Account
--
--
--
-- ---------------------------------------------------------------------------
    PROCEDURE create_bank_account (
      p_acct_owner_party_id in iby_account_owners.ACCOUNT_OWNER_PARTY_ID%TYPE,
      p_org_id              in hr_all_organization_units.organization_id%type,
      p_cust_account_id     in hz_cust_accounts.cust_account_id%type,
      p_bill_site_use_id    in hz_cust_site_uses_all.site_use_id%type,
      p_BANK_ID           in       iby_ext_bank_accounts.BANK_ID%TYPE,
      P_branch_id         in       iby_ext_bank_accounts.BRANCH_ID%TYPE,
      P_currency            in     iby_ext_bank_accounts.CURRENCY_CODE%TYPE,
      P_bank_account_num    in     iby_ext_bank_accounts.BANK_ACCOUNT_NUM%TYPE,
      p_bank_account_name   in     iby_ext_bank_accounts.BANK_ACCOUNT_NAME%TYPE,
      P_country_code       in      iby_ext_bank_accounts.COUNTRY_CODE%TYPE,
      p_iban               in      iby_ext_bank_accounts.iban%TYPE,
      p_start_date         in      iby_ext_bank_accounts.start_date%TYPE,
      p_bank_account_id   OUT      NUMBER,
      p_return_status     OUT      VARCHAR2,
      p_err_msg           OUT      VARCHAR2
   )
   IS
      l_proc        VARCHAR2 (30)                    := 'create_bank_account';

      x_msg_count   NUMBER;
      x_msg_data    VARCHAR2 (200);
      x_msg_dummy    VARCHAR2 (200);
      x_return_status VARCHAR2(5000);
      x_response IBY_FNDCPT_COMMON_PUB.Result_rec_type;
      l_account_rec IBY_EXT_BANKACCT_PUB.EXTBANKACCT_REC_TYPE;
      l_assign_id   number;

   BEGIN

       write_log(l_proc,'Entering '||l_proc);

       -- Set Account Rec values
       l_account_rec.country_code	        := p_country_code;
       l_account_rec.branch_id			      := p_branch_id;
       l_account_rec.bank_id			        := p_bank_id;
       l_account_rec.acct_owner_party_id  := p_acct_owner_party_id;
       l_account_rec.bank_account_name	  := p_bank_account_name;
       l_account_rec.bank_account_num		  := p_bank_account_num;
       l_account_rec.currency			        := p_currency;
       l_account_rec.iban	                := p_iban;
       l_account_rec.start_date           := p_start_date;
      --
      --Create the Bank account
      iby_ext_bankacct_pub.create_ext_bank_acct
                                       (p_api_version            => '1.0',
                                        p_init_msg_list          => 'T',
                                        p_ext_bank_acct_rec      => l_account_rec,
                                        x_acct_id                => p_bank_account_id,
                                        x_return_status          => p_return_status,
                                        x_msg_count              => x_msg_count,
                                        x_msg_data               => x_msg_data,
                                        x_response               => x_response
                                       );
      write_log(l_proc,'X_ACCT_ID = ' || TO_CHAR (p_bank_account_id),true);
      write_log(l_proc,'X_RETURN_STATUS = ' || p_return_status,true);
      write_log(l_proc,'X_MSG_COUNT = ' || TO_CHAR (x_msg_count));
      write_log(l_proc,'X_MSG_DATA = ' || x_msg_data);
      write_log(l_proc,'ERROR' || fnd_msg_pub.get (1, 'T'));
      write_log(l_proc,'');

      --Set error message if one exists
     -- p_err_msg := fnd_msg_pub.get (1, 'F');

      if nvl(p_return_status,'X') != 'S' then

        IF x_msg_count    > 0 THEN
          FOR j IN 1 .. x_msg_count
          LOOP
            fnd_msg_pub.get ( j , FND_API.G_FALSE , x_msg_data , x_msg_dummy );
            p_err_msg := ( 'Msg' || TO_CHAR ( j ) || ': ' || x_msg_data );
            write_log(l_proc,'p_err_msg = ' || p_err_msg,true);
          END LOOP;
        END IF;

      else
        --
        --Create bank Account assignment
        --
        -- work package 023 - added assignment
		
        write_log( l_proc,'Create bank Account assignment',true );
        create_bank_acc_assign (
                      p_acct_owner_party_id => p_acct_owner_party_id
                     ,p_org_id              => p_org_id
                     ,p_cust_account_id     => p_cust_account_id
                     ,p_bill_site_use_id    => p_bill_site_use_id
                     ,p_bank_account_id     => p_bank_account_id
                     ,p_start_date          => p_start_date
                     ,p_assign_id           => l_assign_id
                     ,p_return_status       => p_return_status
                     ,p_err_msg             => p_err_msg);

        write_log( l_proc,'p_return_status: '||p_return_status||', p_err_msg: '||p_err_msg,true );
      
     end if;   --p_return_status !='S'

   EXCEPTION
      WHEN OTHERS
      THEN
         p_return_status := 'E';
         p_err_msg := 'Oracle error in ' || l_proc || ': ' || SQLERRM;
   END create_bank_account;



-- +-------------------------------------------------------------------------+
-- |----< debit_auth_exists  >-----------------------------------------------|
-- +-------------------------------------------------------------------------+
--
-- Description: Check if a Debit Authorization exists
--
-- ---------------------------------------------------------------------------
Function debit_auth_exists (p_bank_account_id in iby_debit_authorizations.external_bank_account_id%type
                           ,p_party_id in iby_debit_authorizations.debtor_party_id%type) return boolean is

      cursor c_debit_auth (cp_bank_account_id in iby_debit_authorizations.external_bank_account_id%type
                          ,cp_party_id in iby_debit_authorizations.debtor_party_id%type) is
      select debit_authorization_id
      from   iby_debit_authorizations
      where  external_bank_account_id = cp_bank_account_id
      and   (trunc(sysdate)           < trunc(debit_auth_end) or debit_auth_end is null) -- inactive date check (date is in the future or null)
      and    debtor_party_id          = p_party_id;

      l_proc        VARCHAR2 (30)                    := 'debit_auth_exists';

      --API parameters
 --     x_msg_count   NUMBER;
   --   x_msg_data    VARCHAR2 (200);
     -- x_return_status    VARCHAR2(5000);
      --x_response    iby_fndcpt_common_pub.result_rec_type;
      l_debit_auth_id iby_debit_authorizations.debit_authorization_id%type;
      l_exists boolean;
     -- l_active_status varchar2(30);
     -- l_bank_acct_id iby_ext_bank_accounts.EXT_BANK_ACCOUNT_ID%type;

    --  l_err_msg  varchar2(2000);

begin

   write_log(l_proc, 'c_debit_auth:  bank acct id: '|| p_bank_account_id || ' party: ' || p_party_id );

   open c_debit_auth(cp_bank_account_id => p_bank_account_id
                    ,cp_party_id => p_party_id);
   fetch c_debit_auth into l_debit_auth_id;
   if c_debit_auth%notfound then
      l_exists := false;
         write_log(l_proc, 'c_debit_auth is false ' );
   else
      l_exists := true;
       write_log(l_proc, 'c_debit_auth is true ' );
   end if;
   close c_debit_auth;
  /*
   write_log(l_proc, 'Call API IBY_FNDCPT_SETUP_PUB.Debit_Auth_Exists ' );
    --Call API
   IBY_FNDCPT_SETUP_PUB.Debit_Auth_Exists  (
      p_api_version      => '1.0',
      p_init_msg_list    => FND_API.G_TRUE,
      p_auth_ref_number  => p_auth_ref_number,
      x_debit_auth_id    => l_debit_auth_id,
      x_bank_acct_id     => l_bank_acct_id,
      x_active_status   =>  l_active_status,
      x_return_status    => x_return_status,
      x_msg_count        => x_msg_count,
      x_msg_data         => x_msg_data,
      x_response         => x_response);
  --
  -- Return status = S
  --
   if x_return_status = 'S' then
     --Debit Auth ID exists then return true othewise return False
      write_log(l_proc, 'Return Status: '||x_return_status);
     if l_debit_auth_id is not null then
       write_log(l_proc, 'l_debit_auth_id: '||l_debit_auth_id);
       return true;
    end if;
  --
  --Return Status = E
  --
  elsif x_return_status = 'E' and x_response.Result_Code = g_invalid_auth then
     --Write reponse record to log
    write_log(l_proc, 'Return Status: '||x_return_status||', Response Result Code: '||x_response.Result_Code);
    return false;
  --
  --Unkown issue
  --
  else
    --Write reponse record to log
    write_log(l_proc, 'Return Status: '||x_return_status||', Response Result Code: '||x_response.Result_Code);

    --Get error messages and write to log
    xx_appl_common_pkg.process_api_messages (
      p_msg_count   => x_msg_count
     ,p_msg_data    => x_msg_data
     ,p_err_msg     => l_err_msg);

    write_log( l_proc,'Api error message: '||l_err_msg);

    return null;
  end if;*/

  return l_exists;

EXCEPTION WHEN OTHERS
    THEN
      write_log( l_proc, 'Oracle error in ' || l_proc || ':' || SQLERRM );
      raise;
end debit_auth_exists;


-- +-------------------------------------------------------------------------+
-- |----< create_debit_auth  >-----------------------------------------------|
-- +-------------------------------------------------------------------------+
--
-- Description: Create Debit Authorization for Bank Account
--
-- ---------------------------------------------------------------------------
procedure create_debit_auth (p_auth_ref_number in IBY_DEBIT_AUTHORIZATIONS.authorization_reference_number%type
                            ,p_auth_sign_date in IBY_DEBIT_AUTHORIZATIONS.AUTH_SIGN_DATE%type
                            ,p_payment_type_code in IBY_DEBIT_AUTHORIZATIONS.PAYMENT_TYPE_CODE%type
                            ,p_auth_end_date in IBY_DEBIT_AUTHORIZATIONS.DEBIT_AUTH_END%type
                            ,p_org_id in IBY_DEBIT_AUTHORIZATIONS.CREDITOR_LEGAL_ENTITY_ID%type
                            ,p_creditor_id in IBY_DEBIT_AUTHORIZATIONS.CREDITOR_IDENTIFIER%type
                            ,p_bank_account_id in IBY_DEBIT_AUTHORIZATIONS.external_bank_account_id%type
                            ,P_party_id in IBY_DEBIT_AUTHORIZATIONS.debtor_party_id%type
                            ,p_return_status out varchar2
                            ,p_debit_auth_id out IBY_DEBIT_AUTHORIZATIONS.debit_authorization_id%type
                            ,p_err_msg out varchar2
                          ) as

  l_proc        VARCHAR2 (30)                    := 'create_debit_auth';

  --API input variables
  l_debit_auth_rec   IBY_FNDCPT_SETUP_PUB.DebitAuth_rec_type;
  l_payer            IBY_FNDCPT_COMMON_PUB.PayerContext_rec_type;

  --Api output variables
  x_debit_auth_id NUMBER;
  x_msg_count     NUMBER;
  x_msg_data      VARCHAR2 (200);
  x_return_status VARCHAR2(1);
  x_response      iby_fndcpt_common_pub.result_rec_type;

begin
  write_log( l_proc,'Setup record values');
  --Setup record values
  l_debit_auth_rec.DEBIT_AUTH_FLAG := 'Y';
  l_debit_auth_rec.AUTHORIZATION_REFERENCE_NUMBER := p_auth_ref_number;
  l_debit_auth_rec.AUTH_SIGN_DATE := p_auth_sign_date;
  l_debit_auth_rec.PAYMENT_TYPE_CODE := p_payment_type_code;
  l_debit_auth_rec.DEBIT_AUTH_BEGIN := p_auth_sign_date;
  l_debit_auth_rec.DEBIT_AUTH_END := p_auth_end_date;
  l_debit_auth_rec.CREDITOR_LEGAL_ENTITY_ID := p_org_id;
  l_debit_auth_rec.CREDITOR_IDENTIFIER := p_creditor_id;
  l_debit_auth_rec.EXTERNAL_BANK_ACCOUNT_ID := p_bank_account_id;
  l_debit_auth_rec.PRIORITY := 1;
  l_payer.party_id := p_party_id;


 --Call API
  write_log( l_proc,'Call API Create_Debit_Authorization');
  IBY_FNDCPT_SETUP_PUB.Create_Debit_Authorization
            (
            p_api_version    => 1,
            p_init_msg_list  => 'T',
            p_commit         => 'F',
            p_debit_auth_rec => l_debit_auth_rec,
	          p_payer          => l_payer,
            x_debit_auth_id  => x_debit_auth_id,
            x_return_status => x_return_status,
            x_msg_count      => x_msg_count,
            x_msg_data       => x_msg_data,
	          x_response       => x_response
            );

       if x_return_status = 'S' then

         write_log(l_proc, 'Return Status: '||x_return_status);
         p_return_status := x_return_status;

         write_log(l_proc, 'l_debit_auth_id: '||x_debit_auth_id);
         p_debit_auth_id := x_debit_auth_id;

      else
        --Write response record to log
        write_log(l_proc, 'Return Status: '||x_return_status||', Response Result Code: '||x_response.Result_Code);
        p_return_status := x_return_status;

        --Get error messages and write to log
        xx_appl_common_pkg.process_api_messages (
          p_msg_count   => x_msg_count
         ,p_msg_data    => x_msg_data
         ,p_err_msg     => p_err_msg);

        write_log( l_proc,'Api error message: '||p_err_msg);

        --Set p_err_msg to Result Code
        p_err_msg := x_response.Result_Code;

      end if;

EXCEPTION WHEN OTHERS
    THEN
      write_log( l_proc, 'Oracle error in ' || l_proc || ':' || SQLERRM );
      p_return_status := 'U';
      p_err_msg := 'Oracle error: ' || SQLERRM ;
end create_debit_auth;

-- ===========================================================================
--
-- PROCEDURE: end_active_bank_accounts
-- Description : End date all active customer bank accounts for the Customer.
--
-- Parameters: p_party_id  Customer Party ID
--             p_return_status Return Status
--             p_msg_data Error Message
--
--------------------------------------------------------------------------------
procedure end_active_bank_accounts (p_party_id in hz_parties.party_id%type
                                   ,p_return_status out varchar2
                                   ,p_msg_data out varchar2)  is

cursor c_bank_acc (cp_party_id in hz_parties.party_id%type) is
    SELECt iby_account_owners.ext_bank_account_id,
           hz_cust_accounts.cust_account_id,
          iby_external_payers_all.org_type,
          iby_external_payers_all.org_id,
          iby_external_payers_all.acct_site_use_id
    FROM iby_ext_bank_accounts,
      iby_account_owners,
      iby_external_payers_all,
      hz_parties,
      hz_cust_accounts
    WHERE iby_ext_bank_accounts.ext_bank_account_id   = iby_account_owners.ext_bank_account_id
    AND iby_account_owners.account_owner_party_id   = hz_parties.party_id
    and iby_external_payers_all.party_id = hz_parties.party_id
    and hz_parties.party_id = hz_cust_accounts.party_id
    AND hz_parties.party_id  = cp_party_id
    AND nvl(iby_ext_bank_accounts.end_date,sysdate-1) <= sysdate
    and iby_external_payers_all.object_version_number=(select max(object_version_number) from iby_external_payers_all iep1 where iep1.party_id = iby_external_payers_all.party_id);

l_msg_count           number;
l_err_msg             varchar2(500);
l_response            IBY_FNDCPT_COMMON_PUB.Result_rec_type ;
l_payer              iby_fndcpt_common_pub.PayerContext_rec_type;
l_pmt_inst_ass_tbl IBY_FNDCPT_SETUP_PUB.PmtInstrAssignment_tbl_type ;
l_assign_id  number;
l_proc                varchar2(30):='end_active_bank_account';

begin

  write_log(l_proc,'p_party_id: '||p_party_id);

  for bank_acc_rec in c_bank_acc(p_party_id) loop

      l_payer.Payment_Function    := 'CUSTOMER_PAYMENT';
      l_payer.Party_Id  := p_party_id;
      l_payer.Cust_Account_Id := bank_acc_rec.cust_account_id;
      l_payer.Account_site_id := bank_acc_rec.acct_site_use_id;
      l_payer.org_id := bank_acc_rec.org_id;
      l_payer.org_type := bank_acc_rec.org_type;

     --get existing bank account record
     write_log(l_proc,'Call API IBY_FNDCPT_SETUP_PUB.Get_payer_instr_assignment');
     IBY_FNDCPT_SETUP_PUB.Get_Payer_Instr_Assignments
            (
            p_api_version    =>  '1.0',
            p_init_msg_list  => FND_API.G_TRUE,
            x_return_status  => p_return_status,
            x_msg_count      => l_msg_count,
            x_msg_data       => p_msg_data,
            p_payer          => l_payer,
            x_assignments    => l_pmt_inst_ass_tbl,
            x_response       => l_response
            );

     write_log(l_proc,'x_return_status: '||p_return_status||', x_msg_data'||p_msg_data);

     if p_return_status = 'S' then
       --Loop through each bank account and update end date if its not null
       -- or after current date
       write_log(l_proc,'l_pmt_inst_ass_tbl.count : '||l_pmt_inst_ass_tbl.count );

       for i in 1..l_pmt_inst_ass_tbl.count loop

         write_log(l_proc,'l_pmt_inst_ass_tbl(i).end_date: '||l_pmt_inst_ass_tbl(i).end_date);
         -- update bank account record end date
		 -- work package 023 - change "< trunc(sysdate)" to ">= trunc(sysdate)"
         if l_pmt_inst_ass_tbl(i).end_date is null or l_pmt_inst_ass_tbl(i).end_date >= trunc(sysdate) then
             --Set end date
             l_pmt_inst_ass_tbl(i).end_date := trunc(sysdate);
             --
             --Call API
             --
             write_log(l_proc,'Call API IBY_FNDCPT_SETUP_PUB.set_payer_instr_assignment');

             IBY_FNDCPT_SETUP_PUB.set_payer_instr_assignment (
             p_api_version  => 1.0,
             p_init_msg_list  => FND_API.G_TRUE,
             x_return_status  => p_return_status  ,
             x_msg_count  => l_msg_count  ,
             x_msg_data  => p_msg_data ,
             p_payer   => l_payer      ,
             p_assignment_attribs => l_pmt_inst_ass_tbl(i) ,
             x_assign_id  => l_assign_id  ,
             x_response    => l_response );

             write_log(l_proc,'l_assign_id:'||l_assign_id||' ,p_return_status:'||p_return_status||', p_msg_data:'||p_msg_data);
         end if;
       end loop;
      end if;
  end loop;


exception when others then
  l_err_msg := 'Oracle Error in '||l_proc||':'||sqlerrm;
  write_log(l_proc,l_err_msg);
  p_return_status := 'E';
  p_msg_data := l_err_msg;

end end_active_bank_accounts;


END xx_bank_util_pkg;
