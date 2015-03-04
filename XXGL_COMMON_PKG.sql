--------------------------------------------------------
--  DDL for Package XXGL_COMMON_PKG
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE "XXGL_COMMON_PKG" 
AS

/*
+==========================================================================+
|  $Header: /source/iam/oracle/custom/package\040body/XXGL_COMMON_PKG.sql,v 1.1 2014/12/10 14:20:36 poultd10 Exp $
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
-- FUNCTION    : get_exchange_rate
-- Description : Get the exchange rate for from and to currency
--
--------------------------------------------------------------------------------
FUNCTION get_exchange_rate(
                 p_from_currency  in gl_daily_rates.from_currency%TYPE,
                 p_to_currency   in  gl_daily_rates.to_currency%TYPE,
                 p_conversion_date in gl_daily_rates.conversion_date%TYPE,
                 p_conversion_type in gl_daily_rates.conversion_type%TYPE)
                               RETURN gl_daily_rates.conversion_rate%TYPE;

END xxgl_common_pkg ;
