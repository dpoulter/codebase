--------------------------------------------------------
--  DDL for Package Body XX_APPL_COMMON_PKG
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "XX_APPL_COMMON_PKG" 
AS

/*
+==========================================================================+
|  $Header: /source/iam/oracle/custom/package\040body/XX_APPL_COMMON_PKG.pkb,v 1.1 2015/03/10 09:43:56 poultd10 Exp $
|
|  DESCRIPTION  Common Application Functions and Procedures
|
| Date       Author      Description
| =======    ==========  ================================================
| 23-jan-14  Dale Poulter Initial Creation.
| 15-Oct-14  Dale Poulter Modify write_log - added dbms_output
+==========================================================================+
*/

--------------------------------------------------------------------------------
----- Global Variables
--------------------------------------------------------------------------------
g_pkg           varchar2(30) := 'xx_appl_common_pkg';

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
-- PROCEDURE   : write_log
-- Description : Writes log messages to fnd_log_messages for debugging
--
-- Parameters:   p_proc Calling Procedure Name
--
--------------------------------------------------------------------------------

PROCEDURE write_log(
    p_pkg in varchar2,
    p_proc IN VARCHAR2,
    p_msg  IN VARCHAR2,
    p_conc_log in boolean default false)
IS
BEGIN
  IF( FND_LOG.LEVEL_statement >= FND_LOG.G_CURRENT_RUNTIME_LEVEL ) THEN

    fnd_log.STRING(log_level => fnd_log.level_statement ,module => p_pkg||'.'||p_proc ,MESSAGE => p_msg);
  END IF;

  if p_conc_log then
    fnd_file.put_line(fnd_file.log,p_msg);
  end if;

  dbms_output.put_line(g_pkg||'.'||p_proc||':'|| p_msg);
END write_log;


--------------------------------------------------------------------------------
----- Public Procedures
--------------------------------------------------------------------------------

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
   PROCEDURE process_api_messages (
      p_msg_count    IN   NUMBER
     ,p_msg_data     in   varchar2
     ,p_err_msg      out  varchar2
   )
   IS
      l_proc             VARCHAR2 (30)   := 'process_api_messages';

   BEGIN

     p_err_msg := p_msg_data ;

     IF p_msg_count > 0 THEN
        p_err_msg     := SUBSTR(fnd_msg_pub.get(fnd_msg_pub.G_FIRST, fnd_api.G_FALSE),1,512)|| chr(10);
        FOR i IN 1 .. (p_msg_count -1 )
        LOOP
           p_err_msg := p_err_msg || i || '. ' ||SUBSTR(fnd_msg_pub.get(fnd_msg_pub.G_NEXT, fnd_api.G_FALSE),1,512)|| chr(10);
        end loop;
     end if;

   EXCEPTION
      WHEN OTHERS
      THEN
         write_log (l_proc,SQLERRM);
  END process_api_messages;

-- ===========================================================================
--
-- PROCEDURE   : get_error_message
-- Description : Return the message for the exception and token values
--
-- Parameters:   p_appl_short_name Application Short Name
--               p_message  Message internal name
--               p_token1   Token name
--               p_value1   Token value
--               p_token2   Token name
--               p_value2   Token value
--               p_token3   Token name
--               p_value3   Token value
--
--------------------------------------------------------------------------------
   FUNCTION get_error_message (
      p_appl_short_name in varchar2
     ,p_message     IN   VARCHAR2
     ,p_token1      IN   VARCHAR2 DEFAULT NULL
     ,p_value1      IN   VARCHAR2 DEFAULT NULL
     ,p_token2      IN   VARCHAR2 DEFAULT NULL
     ,p_value2      IN   VARCHAR2 DEFAULT NULL
     ,p_token3      IN   VARCHAR2 DEFAULT NULL
     ,p_value3      IN   VARCHAR2 DEFAULT NULL
   )
      RETURN VARCHAR2
   IS
      l_proc         VARCHAR2 (100) := 'get_message';
      l_error_name   VARCHAR2 (100);
   BEGIN
      fnd_message.set_name (p_appl_short_name, p_message);

      IF p_token1 IS NOT NULL
      THEN
         fnd_message.set_token (p_token1, p_value1);
      END IF;

      IF p_token2 IS NOT NULL
      THEN
         fnd_message.set_token (p_token2, p_value2);
      END IF;

      IF p_token3 IS NOT NULL
      THEN
         fnd_message.set_token (p_token3, p_value3);
      END IF;

      RETURN fnd_message.get;
   EXCEPTION
      WHEN OTHERS
      THEN
         write_log ( l_proc, SQLERRM);
   END get_error_message;

--------------------------------------------------------------------------------
----- Procedure   : raise_alert
----- Description : Raise Application Error
----- Parameters  : p_proc  Calling Procedure Name
--------------------------------------------------------------------------------
PROCEDURE raise_alert (p_proc in varchar2
                      ,p_error_msg in varchar2) IS
BEGIN

    FND_MESSAGE.SET_NAME('XX', 'XX_ORACLE_ERROR'); -- Seeded Message
    -- Runtime Information
    FND_MESSAGE.SET_TOKEN('MODULE', p_proc);
    FND_MESSAGE.SET_TOKEN('ERROR_MSG', p_error_msg);
    FND_LOG.MESSAGE(FND_LOG.LEVEL_UNEXPECTED, p_proc, TRUE);

END raise_alert;


-- +-------------------------------------------------------------------------+
-- |----< get_flex_value_set_rec >-----------------------------------------------|
-- +-------------------------------------------------------------------------+
--
-- Description: get a flex value record for value set and flex value
--
--
--
-- ---------------------------------------------------------------------------
FUNCTION get_flex_value_set_rec  (
           p_flex_value_set_name IN  fnd_flex_value_sets.flex_value_set_name%TYPE)
  RETURN  fnd_flex_value_sets%ROWTYPE IS

  l_proc VARCHAR2(30) := 'get_flex_value_set_rec';

  CURSOR c_flex_value_set_rec IS
  SELECT ffvs.*
  FROM fnd_flex_value_sets ffvs
  WHERE ffvs.flex_value_set_name = p_flex_value_set_name;

  l_flex_value_set_rec   c_flex_value_set_rec%ROWTYPE;

BEGIN

 OPEN c_flex_value_set_rec;
 FETCH c_flex_value_set_rec INTO l_flex_value_set_rec;
 IF c_flex_value_set_rec%NOTFOUND THEN
   write_log(l_proc,'ERROR: Could not find Flex Value record for value Set: '
                            ||p_flex_value_set_name);
 END IF;
 CLOSE c_flex_value_set_rec;

 RETURN(l_flex_value_set_rec);

EXCEPTION
  WHEN OTHERS THEN
    write_log(l_proc, 'Oracle Error: '||sqlerrm);
    RETURN(NULL);
END get_flex_value_set_rec;

-- ===========================================================================
--
-- Function   : get_org_id
-- Description : Return Org Id for Entity Code
--
-- Parameters:
--------------------------------------------------------------------------------
function get_org_id (p_entity_code hr_all_organization_units.attribute15%type)
              return hr_all_organization_units.organization_id%type IS
  cursor c_org_id(cp_entity_code hr_all_organization_units.attribute15%type) is
  select organization_id
  from hr_all_organization_units
  where attribute6 = cp_entity_code;

  l_org_id hr_all_organization_units.organization_id%type;
  l_proc VARCHAR2(30) := 'get_org_id';

BEgin
  open c_org_id(cp_entity_code => p_entity_code);
  fetch c_org_id into l_org_id;
  close c_org_id;

  return l_org_id;

EXCEPTION
  WHEN OTHERS THEN
   write_log(l_proc, 'Oracle Error: '||sqlerrm);
   RETURN(NULL);
end;

-- ===========================================================================
--
-- Function   : get_entity_code
-- Description : Return Entitu Code for Org Id parameter
--
-- Parameters:
--------------------------------------------------------------------------------
function get_entity_code (p_org_id hr_all_organization_units.organization_id%type)
              return hr_all_organization_units.organization_id%type IS

  cursor c_entity_code(cp_org_id hr_all_organization_units.organization_id%type) is
  select attribute6
  from hr_all_organization_units
  where organization_id = cp_org_id ;

  l_entity_code hr_all_organization_units.attribute15%type;
  l_proc VARCHAR2(30) := 'get_entity_code';

BEgin
  open c_entity_code(cp_org_id  => p_org_id );
  fetch c_entity_code into l_entity_code;
  close c_entity_code;

  return l_entity_code;

EXCEPTION
  WHEN OTHERS THEN
   write_log(l_proc, 'Oracle Error: '||sqlerrm);
   RETURN(NULL);
end get_entity_code;

-- +-------------------------------------------------------------------------+
-- |----< get_org_rec  >-----------------------------------------------------|
-- +-------------------------------------------------------------------------+
--
-- Description: Get an organization record from an org Id
--
--
--
-- ---------------------------------------------------------------------------
FUNCTION get_org_rec(
             p_org_id             IN hr_organization_units.organization_id%TYPE)
RETURN hr_all_organization_units%ROWTYPE IS


CURSOR c_org (cp_org_id             hr_organization_units.organization_id%TYPE) IS
 SELECT *
 FROM  hr_all_organization_units
 WHERE organization_id = cp_org_id;

l_org_rec                 hr_all_organization_units%ROWTYPE;
l_proc                    VARCHAR2(30) := 'get_org_rec';

BEGIN


  OPEN c_org (cp_org_id => p_org_id);
  FETCH c_org INTO l_org_rec;
  CLOSE c_org;


  RETURN(l_org_rec);

EXCEPTION
  WHEN OTHERS THEN
    write_log(l_proc, 'Oracle Error: '||sqlerrm);
    RETURN(NULL);
END get_org_rec;




-- ===========================================================================
--
-- Function   : get_ledger_id
-- Description : Return ledger Id for Organization id
--
-- Parameters:
--------------------------------------------------------------------------------
function get_ledger_id (p_org_id hr_all_organization_units.organization_id%type)
              return gl_ledgers.ledger_id%type is


cursor c_ledger_id (cp_organization_id in hr_all_organization_units.organization_id%type) is

    select gl.ledger_id
    from gl_ledgers gl,
         GL_LEDGER_CONFIG_DETAILS gl_config,
        hr_organization_information hoi,
        hr_all_organization_units legal_entity
    where gl.configuration_id          =gl_config.configuration_id
    AND hoi.org_information_context    ='Operating Unit Information'
    AND hoi.org_information2           = legal_entity.organization_id
    and gl.configuration_id          =gl_config.configuration_id
    AND gl_config.object_type_code     ='LEGAL_ENTITY'
    AND gl_config.object_id            = legal_entity.organization_id
    and gl.ledger_category_code = 'PRIMARY'
    and hoi.organization_id= cp_organization_id;

    l_proc varchar2(30) := 'get_ledger_id';
    l_ledger_id gl_ledgers.ledger_id%type;

begin

  open c_ledger_id(p_org_id);
  fetch c_ledger_id into l_ledger_id;
  close c_ledger_id;

  return l_ledger_id;
end get_ledger_id;


-- ===========================================================================
--
-- Function   : get_chart_of_accounts_id
-- Description : Return Chart Of accounts id for Organization id
--
-- Parameters:
--------------------------------------------------------------------------------
function get_chart_of_accounts_id (p_org_id hr_all_organization_units.organization_id%type)
              return gl_ledgers.chart_of_accounts_id%type is


cursor c_coa (cp_organization_id in hr_all_organization_units.organization_id%type) is

    select gl.chart_of_accounts_id
    from gl_ledgers gl,
         GL_LEDGER_CONFIG_DETAILS gl_config,
        hr_organization_information hoi,
        hr_all_organization_units legal_entity
    where gl.configuration_id          =gl_config.configuration_id
    AND hoi.org_information_context    ='Operating Unit Information'
    AND hoi.org_information2           = legal_entity.organization_id
    and gl.configuration_id          =gl_config.configuration_id
    AND gl_config.object_type_code     ='LEGAL_ENTITY'
    and gl_config.object_id            = legal_entity.organization_id
    and gl.ledger_category_code = 'PRIMARY'
    and hoi.organization_id= cp_organization_id;

    l_proc varchar2(30) := 'get_chart_of_accounts_id';
    l_coa_id gl_ledgers.chart_of_accounts_id%type;

begin

  open c_coa(p_org_id);
  fetch c_coa into l_coa_id;
  close c_coa;

  return l_coa_id;

 EXCEPTION
  WHEN OTHERS THEN
    write_log(l_proc, 'Oracle Error '|| sqlerrm);
    return null;

end get_chart_of_accounts_id;

-- This procedure is simply a central place to get an employee id
-- given a user id.
--
/*4090833: Added 'IN' for parameter of function*/
FUNCTION get_employee_id (p_user_id IN NUMBER) RETURN NUMBER IS
    CURSOR c IS
        SELECT employee_id
        FROM   fnd_user
        WHERE  user_id = p_user_id;

  lv_employee_id NUMBER;
BEGIN
  ----------------------------------------------------------
 -- g_debug_mesg := 'Entered GET_EMPLOYEE_ID';
 -- IF PG_DEBUG in ('Y', 'C') THEN
 --    arp_standard.debug('get_employee_id: ' || g_debug_mesg);
 -- END IF;
 ----------------------------------------------------------
  OPEN c;
  FETCH c INTO lv_employee_id;
  CLOSE c;
  RETURN lv_employee_id;

END get_employee_id;
-- This procedure is simply a central place to get a user id
-- given an employee id.
--
/*4090833: Added 'IN' for parameter of function*/
FUNCTION get_user_id (p_employee_id IN NUMBER)
RETURN NUMBER
IS
    CURSOR c
    IS SELECT user_id
       FROM   fnd_user
       WHERE  employee_id = p_employee_id
       AND    NVL(end_date,sysdate) >= sysdate ;  /*3973471 */
  lv_user_id NUMBER;
BEGIN
    OPEN c;
    FETCH c INTO lv_user_id;
    CLOSE c;
    RETURN lv_user_id;

END get_user_id;
-- This procedure is simply a central place to get a user name
-- given an user id.
--
FUNCTION get_user_name (p_user_id IN NUMBER)
RETURN varchar2
IS
CURSOR c
IS
  SELECT user_name
  FROM   fnd_user
  WHERE  user_id = p_user_id
  AND    NVL(end_date,sysdate) >= sysdate ;  /*3973471 */
lv_user_name fnd_user.user_name%type;
BEGIN
    OPEN c;
    FETCH c INTO lv_user_name;
    CLOSE c;
    RETURN lv_user_name;

END get_user_name;

--------------------------------------------------------------------------------
----- Procedure   : set_context
----- Description : Sets the Application Context. Returns T if context
--                  was set successfully. Returns F if context could not be set
--
----- Parameters  : i_user_name  User name
--                  i_resp_name  Responsibility Name
--                  i_org_id     Organization Id
--------------------------------------------------------------------------------

FUNCTION set_context( i_user_name    IN  VARCHAR2
                     ,i_resp_name    IN  VARCHAR2
                     ,i_org_id       IN  NUMBER)
RETURN VARCHAR2
IS
v_user_id             NUMBER;
v_resp_id             NUMBER;
v_resp_appl_id NUMBER;
v_appl_short_name  varchar2(30);
v_lang                   VARCHAR2(100);
v_session_lang VARCHAR2(100):=fnd_global.current_language;
v_return              VARCHAR2(10):='T';
v_nls_lang          VARCHAR2(100);
v_org_id              NUMBER:=i_org_id;
/* Cursor to get the user id information based on the input user name */
CURSOR cur_user
IS
    SELECT     user_id
    FROM       fnd_user
    WHERE      user_name  =  i_user_name;
/* Cursor to get the responsibility information */
CURSOR cur_resp
IS
    SELECT     responsibility_id
                     ,application_id
                    ,language
    FROM       fnd_responsibility_tl
    WHERE      responsibility_name  =  i_resp_name;
/* Cursor to get the nls language information for setting the language context */
CURSOR cur_lang(p_lang_code VARCHAR2)
IS
    SELECT    nls_language
    FROM      fnd_languages
    WHERE     language_code  = p_lang_code;
 /* Cursor to get the responsibility application short code */
cursor cur_appl(cp_resp_appl_id in fnd_responsibility.application_id%type) is
select application_short_name
from fnd_application
where application_id=cp_resp_appl_id;

BEGIN
    /* To get the user id details */
    OPEN cur_user;
    FETCH cur_user INTO v_user_id;
    IF cur_user%NOTFOUND
    THEN
        v_return:='F';

    END IF; --IF cur_user%NOTFOUND
    CLOSE cur_user;

    /* To get the responsibility and responsibility application id */
    OPEN cur_resp;
    FETCH cur_resp INTO v_resp_id, v_resp_appl_id,v_lang;
    IF cur_resp%NOTFOUND
    THEN
        v_return:='F';

    END IF; --IF cur_resp%NOTFOUND
    CLOSE cur_resp;

    /* To get the application short name */
    OPEN cur_appl(v_resp_appl_id);
    FETCH cur_appl INTO v_appl_short_name;
    IF cur_appl%NOTFOUND
    THEN
        v_return:='F';

    END IF; --IF cur_resp%NOTFOUND
    CLOSE cur_appl;

    /* Setting the oracle applications context for the particular session */
    fnd_global.apps_initialize ( user_id      => v_user_id
                                ,resp_id      => v_resp_id
                                ,resp_appl_id => v_resp_appl_id);

    /* Setting the org context for the particular session */
    IF v_org_id is null then
      MO_GLOBAL.INIT(v_appl_short_name);
    else
      mo_global.set_policy_context('S',v_org_id);
    end if;

    /* setting the nls context for the particular session */
    IF v_session_lang != v_lang
    THEN
        OPEN cur_lang(v_lang);
        FETCH cur_lang INTO v_nls_lang;
        CLOSE cur_lang;
        fnd_global.set_nls_context(v_nls_lang);
    END IF; --IF v_session_lang != v_lang

    RETURN v_return;
EXCEPTION
WHEN OTHERS THEN
    RETURN 'F';
END set_context;

---------------------------------------------------------------
-- Creates a concatenated address in the address style of the
-- country.
---------------------------------------------------------------
function format_address  (
  P_TO_LANGUAGE_CODE VARCHAR2,
  P_FROM_TERRITORY_CODE VARCHAR2,
  P_ADDRESS_LINE_1 VARCHAR2,
  P_ADDRESS_LINE_2 VARCHAR2,
  P_ADDRESS_LINE_3 VARCHAR2,
  P_ADDRESS_LINE_4 VARCHAR2,
  P_CITY VARCHAR2,
  P_POSTAL_CODE VARCHAR2,
  P_STATE VARCHAR2,
  P_PROVINCE VARCHAR2,
  P_COUNTY VARCHAR2,
  P_COUNTRY VARCHAR2) return varchar2
  as

  P_COUNTRY_NAME_LANG VARCHAR2(200) := 'US';
  P_LINE_BREAK VARCHAR2 (200):= chr(10);
  X_RETURN_STATUS VARCHAR2(200);
  X_MSG_COUNT NUMBER;
  X_MSG_DATA VARCHAR2(200);
  X_FORMATTED_ADDRESS VARCHAR2(200);
  X_FORMATTED_LINES_CNT NUMBER;
  X_FORMATTED_ADDRESS_TBL APPS.HZ_FORMAT_PUB.STRING_TBL_TYPE;
  X_STYLE_FORMAT_CODE VARCHAR2(200);
 -- x_to_territory_code varchar2(200);
 -- lv_format_country   varchar2(200);

 /* cursor c_territory_code_siebel (p_country_name varchar2) is
  select oracle_country_code
  from xxicl_ibs_countries
  where siebel_country_name=p_country_name;
*/
 /* cursor c_territory_code_oracle (p_country_name varchar2) is
  select territory_code
  from fnd_territories_tl
  where territory_short_name = p_country_name;
 */

BEGIN

 /* open c_territory_code_oracle(p_country);
  fetch c_territory_code_oracle into x_to_territory_code;
  CLOSE c_territory_code_oracle;

  if x_to_territory_code is null then
    open c_territory_code_siebel(p_country);
    fetch c_territory_code_siebel into x_to_territory_code;
    CLOSE c_territory_code_siebel;
  end if;
*/
  -- AD 30/10/13 - add extra quotes for any country which contains a quote
 --lv_format_country   := REPLACE(P_COUNTRY, '''', ''''''); -- handle countries with 1 quote

 hz_format_pub.get_style_format (
	  p_style_code		=>	'POSTAL_ADDR',
	  p_territory_code	=>	p_country,
	  p_language_code	=>	null,
	  x_return_status	=>	x_return_status,
	  x_msg_count		=>	x_msg_count,
	  x_msg_data		=>	x_msg_data,
	  x_style_format_code	=>	x_style_format_code
      );


  HZ_FORMAT_PUB.FORMAT_ADDRESS(
    P_STYLE_CODE             => NULL,
    P_STYLE_FORMAT_CODE      => x_style_format_code,
    P_LINE_BREAK             => P_LINE_BREAK,
    P_SPACE_REPLACE          => NULL,
    P_TO_LANGUAGE_CODE       => P_TO_LANGUAGE_CODE,
    P_COUNTRY_NAME_LANG      => P_COUNTRY_NAME_LANG,
    P_FROM_TERRITORY_CODE    => P_FROM_TERRITORY_CODE,
    P_ADDRESS_LINE_1         => P_ADDRESS_LINE_1,
    P_ADDRESS_LINE_2         => P_ADDRESS_LINE_2,
    P_ADDRESS_LINE_3         => P_ADDRESS_LINE_3,
    P_ADDRESS_LINE_4         => P_ADDRESS_LINE_4,
    P_CITY                   => P_CITY,
    P_POSTAL_CODE            => P_POSTAL_CODE,
    P_STATE                  => P_STATE,
    P_PROVINCE               => P_PROVINCE,
    P_COUNTY                 => P_COUNTY,
    P_COUNTRY                => p_COUNTRY,
    P_ADDRESS_LINES_PHONETIC => null,
    X_RETURN_STATUS          => X_RETURN_STATUS,
    X_MSG_COUNT              => X_MSG_COUNT,
    X_MSG_DATA               => X_MSG_DATA,
    X_FORMATTED_ADDRESS      => X_FORMATTED_ADDRESS,
    X_FORMATTED_LINES_CNT    => X_FORMATTED_LINES_CNT,
    X_FORMATTED_ADDRESS_TBL  => X_FORMATTED_ADDRESS_TBL
  );
  DBMS_OUTPUT.PUT_LINE('X_RETURN_STATUS = ' || X_RETURN_STATUS);
  DBMS_OUTPUT.PUT_LINE('X_MSG_COUNT = ' || X_MSG_COUNT);
  DBMS_OUTPUT.PUT_LINE('X_MSG_DATA = ' || X_MSG_DATA);
  DBMS_OUTPUT.PUT_LINE('X_FORMATTED_ADDRESS = ' || X_FORMATTED_ADDRESS);
  DBMS_OUTPUT.PUT_LINE('X_FORMATTED_LINES_CNT = ' || X_FORMATTED_LINES_CNT);

  return x_formatted_address;
  -- Modify the code to output the variable
  -- DBMS_OUTPUT.PUT_LINE('X_FORMATTED_ADDRESS_TBL = ' || X_FORMATTED_ADDRESS_TBL);
END;

END xx_appl_common_pkg;
