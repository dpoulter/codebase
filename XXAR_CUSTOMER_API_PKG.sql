--------------------------------------------------------
--  DDL for Package XXAR_CUSTOMER_API_PKG
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE "XXAR_CUSTOMER_API_PKG" 
AS

/*
+==========================================================================+
|  $Header: /source/iam/oracle/custom/package\040body/XXAR_CUSTOMER_API_PKG.sql,v 1.1 2014/12/10 14:20:36 poultd10 Exp $
|
|  DESCRIPTION
|
| Date       Author      Description
| =======    ==========  ================================================
| 09-Sep-13  Dale Poulter Initial Creation
+==========================================================================+
*/

   TYPE api_customer_result_tp IS RECORD (
      cust_account_id               NUMBER,
      account_number                VARCHAR2 ( 50 ),
      party_id                      NUMBER,
      party_number                  VARCHAR2 ( 4000 ),
      profile_id                    NUMBER,
      cust_account_profile_id       NUMBER,
      object_version_number         NUMBER,
      cust_acct_site_id             NUMBER,
      site_use_id                   NUMBER,
      location_id                   NUMBER,
      party_site_id                 NUMBER,
      party_site_number             VARCHAR2 ( 4000 ),
      party_site_use_id             NUMBER,
      tel_contact_point_id          number,
      fax_contact_point_id          number,
      email_contact_point_id        number,
      cust_account_role_id          number,
      err_p                         VARCHAR2 ( 4000 ),
      return_status                 VARCHAR2 ( 4000 ),
      msg_count                     NUMBER,
      msg_data                      VARCHAR2 ( 4000 )
   );



-- ===========================================================================
-- PROCEDURE   : Create_cust
-- Description : Create Customer record
--
-- Parameters:   orig_system_reference_p  Original System reference
--               account_number_p         Customer Account Number
--               customer_type_p          Customer Type
--               customer_class_p         Customer Class
--               organization_name_p      Organization Name
--               tax_reference_p          Tax Reference
--               api_create_cust_result_rc Output result record
--------------------------------------------------------------------------------
PROCEDURE create_cust(orig_system_reference_p   IN hz_cust_accounts.orig_system_reference%TYPE,
                        account_number_p          IN hz_cust_accounts.account_number%TYPE,
                        customer_type_p           IN hz_cust_accounts.customer_type%TYPE,
                        customer_class_p          IN hz_cust_accounts.customer_class_code%TYPE,
                        organization_name_p       IN hz_parties.party_name%TYPE,
                        tax_reference_p           in hz_parties.tax_reference%type,
                        api_create_cust_result_rc OUT api_customer_result_tp);

-- ===========================================================================
-- PROCEDURE   : update_party
-- Description : Create Customer Party
--
-- Parameters:   party_id_p  Original System reference
--               object_version_number_p         Customer Account Number
--               p_organization_name          Customer Type
--               p_tax_reference              Tax Reference
--               api_update_party_result_rc Output result record
--------------------------------------------------------------------------------
  PROCEDURE update_party(party_id_p                 IN hz_parties.party_id%TYPE,
                         object_version_number_p    IN hz_parties.object_version_number%TYPE,
                         p_organization_name        IN hz_parties.party_name%TYPE,
                         p_tax_reference            in hz_parties.tax_reference%type,
                         api_update_party_result_rc OUT api_customer_result_tp);

-- ===========================================================================
-- PROCEDURE   : update_cust
-- Description : Update Customer
--
-- Parameters:   cust_account_id_p          Customer Account ID
--               account_number_p           Customer Account Number
--              orig_system_reference_p     Original System Reference
--               p_object_version_number    Customer Account Number
--               customer_class_p           Customer Class
--               api_update_cust_result_rc Output result record
--------------------------------------------------------------------------------
  PROCEDURE update_cust(cust_account_id_p         IN hz_cust_accounts.cust_account_id%TYPE,
                        account_number_p          IN hz_cust_accounts.account_number%TYPE,
                        orig_system_reference_p   IN hz_cust_accounts.orig_system_reference%TYPE,
                        customer_class_p          IN hz_cust_accounts.customer_class_code%TYPE,
                        object_version_number_p   IN hz_cust_accounts.object_version_number%TYPE,
                        api_update_cust_result_rc OUT api_customer_result_tp);

-- ===========================================================================
-- PROCEDURE   : update_location
-- Description : Update Customer Address
--
-- Parameters:   location_id_p          Location ID
--               country_p              Country Code
--               address1_p             Address Line 1
--               address2_p             Address Line 2
--               address3_p             Address Line 3
--               address4_p             Address Line 4
--               city_p                 City
--               county_p                County
--               postal_code_p           Postal Code
--               orig_system_reference_p Original System Reference
--               object_version_number_p Object Version Number
--               api_update_loc_result_rc Output result record
--------------------------------------------------------------------------------
  PROCEDURE update_location(location_id_p            IN hz_locations.location_id%TYPE,
                            country_p                IN hz_locations.country%TYPE,
                            address1_p               IN hz_locations.address1%TYPE,
                            address2_p               IN hz_locations.address2%TYPE,
                            address3_p               IN hz_locations.address3%TYPE,
                            address4_p               IN hz_locations.address4%TYPE,
                            city_p                   IN hz_locations.city%TYPE,
                            county_p                 IN hz_locations.county%TYPE,
                            postal_code_p            IN hz_locations.postal_code%TYPE,
                            orig_system_reference_p  IN hz_locations.orig_system_reference%TYPE,
                            object_version_number_p  IN hz_locations.object_version_number%TYPE,
                            api_update_loc_result_rc OUT api_customer_result_tp);

-- ===========================================================================
-- PROCEDURE   : update_location
-- Description : Update Customer Address
--
-- Parameters:   country_p              Country Code
--               address1_p             Address Line 1
--               address2_p             Address Line 2
--               address3_p             Address Line 3
--               address4_p             Address Line 4
--               city_p                 City
--               county_p                County
--               postal_code_p           Postal Code
--               orig_system_reference_p Original System Reference
--               object_version_number_p Object Version Number
--               api_create_loc_result_rc Output result record
--------------------------------------------------------------------------------
   PROCEDURE create_location(country_p                IN hz_locations.country%TYPE,
                            address1_p               IN hz_locations.address1%TYPE,
                            address2_p               IN hz_locations.address2%TYPE,
                            address3_p               IN hz_locations.address3%TYPE,
                            address4_p               IN hz_locations.address4%TYPE,
                            city_p                   IN hz_locations.city%TYPE,
                            county_p                 IN hz_locations.county%TYPE,
                            postal_code_p            IN hz_locations.postal_code%TYPE,
                            orig_system_reference_p  IN hz_locations.orig_system_reference%TYPE,
                            api_create_loc_result_rc OUT api_customer_result_tp);

-- ===========================================================================
-- PROCEDURE   : create_party_site
-- Description : Create Party Site
--
-- Parameters:   party_id_p                   Party ID
--               location_id_p                Location ID
--               api_create_partysite_result_rc Output result record
--------------------------------------------------------------------------------
  PROCEDURE create_party_site(party_id_p                     IN hz_parties.party_id%TYPE,
                              location_id_p                  IN hz_locations.location_id%TYPE,
                              api_create_partysite_result_rc OUT api_customer_result_tp);

-- ===========================================================================
-- PROCEDURE   : create_cust_site
-- Description : Create Customer  Site
--
-- Parameters:   cust_account_id_p            Customer Account ID
--               party_site_id_p              Party Site ID
--               org_id_p                     Organization Id
--               api_cr_cust_site_result_rc   Output result record
--------------------------------------------------------------------------------
PROCEDURE create_cust_site(cust_account_id_p          IN hz_cust_acct_sites.cust_account_id%TYPE,
                           party_site_id_p            in hz_cust_acct_sites.party_site_id%type,
                           org_id_p                   in hz_cust_acct_sites.org_id%type,
                           api_cr_cust_site_result_rc out api_customer_result_tp);

-- ===========================================================================
-- PROCEDURE   : create_cust_site_use
-- Description : Create Customer Site use
--
-- Parameters:   party_site_id_p               Party Site ID
--               api_cr_partysiteuse_result_rc Output result record
--------------------------------------------------------------------------------
 PROCEDURE create_cust_site_use(cust_acct_site_id_p            IN hz_cust_site_uses.cust_acct_site_id%TYPE,
                                 gl_id_rec_p                    IN hz_cust_site_uses.gl_id_rec%TYPE,
                                 gl_id_rev_p                    IN hz_cust_site_uses.gl_id_rev%TYPE,
                                 payment_term_id_p              IN hz_cust_site_uses.payment_term_id%TYPE,
                                 org_id_p                       in hz_cust_site_uses.org_id%type,
                                 api_cr_cust_site_use_result_rc OUT api_customer_result_tp);
--------------------------------------------------------------------------------
-- PROCEDURE   : create_site_phone
-- Description : Create Telephone Number for Customer site.
--
-- Parameters:   party_site_id_p               Party Site ID
--               p_phone_number                Telephone Number
--               api_phone_point_result_rc Output result record
--------------------------------------------------------------------------------
  PROCEDURE create_site_phone(p_party_site_id IN NUMBER,
                             p_phone_number  IN VARCHAR2,
                             p_fax_number    IN VARCHAR2,
                             p_email_id      IN VARCHAR2,
                             api_phone_point_result_rc OUT api_customer_result_tp);

  --------------------------------------------------------------------------------
-- PROCEDURE   : create_site_fax
-- Description : Create Fax number for Customer site
--
-- Parameters:   party_site_id_p               Party Site ID
--               p_fax_number                  Fax Number
--               api_fax_cont_point_result_rc Output result record
--------------------------------------------------------------------------------
  PROCEDURE create_site_fax(p_party_site_id IN NUMBER,
                             p_fax_number    IN VARCHAR2,
                             p_email_id      IN VARCHAR2,
                             api_fax_cont_point_result_rc OUT api_customer_result_tp);

--------------------------------------------------------------------------------
-- PROCEDURE   : create_site_email
-- Description : Create Email address for Customer Site
--
-- Parameters:   party_site_id_p               Party Site ID
--               p_email_id                    Email Address
--               api_email_cont_point_result_rc Output result record
--------------------------------------------------------------------------------
  PROCEDURE create_site_email(p_party_site_id IN NUMBER,
                             p_phone_number  IN VARCHAR2,
                             p_fax_number    IN VARCHAR2,
                             p_email_id      IN VARCHAR2,
                             api_email_cont_point_result_rc OUT api_customer_result_tp);

--------------------------------------------------------------------------------
-- PROCEDURE   : create_site_contact
-- Description : Create Contact person for Customer Site
--
-- Parameters:   party_site_id_p               Party Site ID
--               p_email_id                    Email Address
--               api_email_cont_point_result_rc Output result record
--------------------------------------------------------------------------------

  PROCEDURE create_site_contact(p_first_name    IN VARCHAR2,
                           P_last_name     IN VARCHAR2,
                           p_party_site_id IN NUMBER,
                           P_party_id      IN NUMBER,
                           api_contact_result_rc OUT api_customer_result_tp
                           );

-- ===========================================================================
--
-- FUNCTION    : valid_cust_acct
-- Description : Valid Customer Account
--
-- Parameters:  cust_acct_p    Account Number
--              company_name_p Company Name
--
--------------------------------------------------------------------------------
  FUNCTION valid_cust_acct(cust_acct_p IN VARCHAR2, company_name_p in varchar2)
  RETURN VARCHAR2;

 -- ===========================================================================
--
-- FUNCTION    : get_rev_ccid
-- Description : Get the Revenue Account to be used for default on Bill-To site
--
-- Parameters:  x_org_id  Organization Id
--
--------------------------------------------------------------------------------
 FUNCTION get_rev_ccid(org_id_p  in number,
                        coa_id_p   IN NUMBER,
                        customer_p IN VARCHAR2,
                        trx_type_p in varchar2) RETURN NUMBER;

-- ===========================================================================
--
-- FUNCTION    : get_rec_ccid
-- Description : Get the Receivable Account from the IBS Invoice Transaction Type
--
-- Parameters:  x_org_id  Organization Id
--
--------------------------------------------------------------------------------
function get_rec_ccid(  p_trx_type in ra_cust_trx_types_all.name%type
                      ,p_org_id      IN ra_cust_trx_types_all.org_id%type)
                       RETURN INTEGER;

--------------------------------------------------------------------------------
-- PROCEDURE   : get_bill_to_site_use_rec
-- Description : Get bill to site use details for a customer site
--
-- Parameters:   p_cust_acct_site_id           Customer Account Site Id

--------------------------------------------------------------------------------
FUNCTION get_bill_to_site_use_rec (
            p_cust_acct_site_id         IN  hz_cust_acct_sites_all.cust_acct_site_id%TYPE)
  RETURN hz_cust_site_uses_all%ROWTYPE;

--------------------------------------------------------------------------------
-- PROCEDURE   : get_cust_account_rec
-- Description : Get Customer Account  Record
--
-- Parameters:   p_cust_account_id           Customer Account Id

--------------------------------------------------------------------------------
FUNCTION get_cust_account_rec (
            p_cust_account_id         IN  hz_cust_accounts.cust_account_id%TYPE)
  RETURN hz_cust_accounts%ROWTYPE;

END XXAR_CUSTOMER_API_PKG ;
