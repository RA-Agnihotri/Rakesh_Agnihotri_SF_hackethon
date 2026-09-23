-- ============================================================================
-- INSURANCE AI HUB - Rollback / Teardown Script
-- Script 20: Reverse all deployed objects
-- ============================================================================
-- Run as: ACCOUNTADMIN
-- WARNING: This script DROPS all Insurance AI Hub objects permanently.
--          Time Travel allows recovery within the retention period (default 1 day).
--          Review each section before executing. Comment out sections to keep
--          specific objects.
-- ============================================================================

USE ROLE ACCOUNTADMIN;

-- ############################################################################
-- SECTION 1: Remove CoWork registrations (must be done before dropping agents)
-- ############################################################################

ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
  REMOVE AGENT INSURANCE_AI_HUB.ANALYTICS.PRODUCT_MATCHING_AGENT;

ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
  REMOVE AGENT INSURANCE_AI_HUB.ANALYTICS.PRICE_OPTIMIZATION_AGENT;

ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
  REMOVE AGENT INSURANCE_AI_HUB.ANALYTICS.MARKET_INTELLIGENCE_AGENT;

ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
  REMOVE AGENT INSURANCE_AI_HUB.ANALYTICS.UNIFIED_ENTERPRISE_AGENT;

ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
  REMOVE AGENT INSURANCE_AI_HUB.ANALYTICS.INSURANCE_INTELLIGENCE_AGENT;


-- ############################################################################
-- SECTION 2: Drop MCP connector and API integration
-- ############################################################################

DROP EXTERNAL MCP SERVER IF EXISTS INSURANCE_AI_HUB.ANALYTICS.ATLASSIAN_MCP_SERVER;
DROP API INTEGRATION IF EXISTS JIRA_MCP_API_INTEGRATION;


-- ############################################################################
-- SECTION 3: Drop Cortex Agents
-- ############################################################################

DROP AGENT IF EXISTS INSURANCE_AI_HUB.ANALYTICS.UNIFIED_ENTERPRISE_AGENT;
DROP AGENT IF EXISTS INSURANCE_AI_HUB.ANALYTICS.PRODUCT_MATCHING_AGENT;
DROP AGENT IF EXISTS INSURANCE_AI_HUB.ANALYTICS.PRICE_OPTIMIZATION_AGENT;
DROP AGENT IF EXISTS INSURANCE_AI_HUB.ANALYTICS.MARKET_INTELLIGENCE_AGENT;
DROP AGENT IF EXISTS INSURANCE_AI_HUB.ANALYTICS.INSURANCE_INTELLIGENCE_AGENT;


-- ############################################################################
-- SECTION 4: Drop Cortex Search Service
-- ############################################################################

DROP CORTEX SEARCH SERVICE IF EXISTS INSURANCE_AI_HUB.DOCUMENTS.CORTEX_SEARCH_SVC;


-- ############################################################################
-- SECTION 5: Drop Stored Procedures
-- ############################################################################

DROP PROCEDURE IF EXISTS INSURANCE_AI_HUB.ANALYTICS.SP_CLAIM_RISK_SCORE(VARCHAR);
DROP PROCEDURE IF EXISTS INSURANCE_AI_HUB.ANALYTICS.SP_TREND_DETECTOR(VARCHAR, VARCHAR, FLOAT);
DROP PROCEDURE IF EXISTS INSURANCE_AI_HUB.ANALYTICS.SP_PRODUCT_MATCH(VARCHAR);
DROP PROCEDURE IF EXISTS INSURANCE_AI_HUB.ANALYTICS.SP_PRICE_OPTIMIZER(VARCHAR, VARCHAR);
DROP PROCEDURE IF EXISTS INSURANCE_AI_HUB.ANALYTICS.SP_MARKET_FORECAST(VARCHAR, VARCHAR);
DROP PROCEDURE IF EXISTS INSURANCE_AI_HUB.DATA_QUALITY.SP_DQ_ROOT_CAUSE(VARCHAR, VARCHAR);


-- ############################################################################
-- SECTION 6: Drop Semantic Views
-- ############################################################################

DROP SEMANTIC VIEW IF EXISTS INSURANCE_AI_HUB.ANALYTICS.SV_INSURANCE_OPS;
DROP SEMANTIC VIEW IF EXISTS INSURANCE_AI_HUB.DATA_QUALITY.SV_DATA_QUALITY;
DROP SEMANTIC VIEW IF EXISTS INSURANCE_AI_HUB.ANALYTICS.SV_COMPETITIVE_INTEL;
DROP SEMANTIC VIEW IF EXISTS INSURANCE_AI_HUB.ANALYTICS.SV_MARKET_INTELLIGENCE;
DROP SEMANTIC VIEW IF EXISTS INSURANCE_AI_HUB.ANALYTICS.SV_PRODUCT_MATCHING;


-- ############################################################################
-- SECTION 7: Drop Views
-- ############################################################################

DROP VIEW IF EXISTS INSURANCE_AI_HUB.ANALYTICS.VW_CUSTOMER_360;
DROP VIEW IF EXISTS INSURANCE_AI_HUB.ANALYTICS.VW_CLAIMS_PERFORMANCE;
DROP VIEW IF EXISTS INSURANCE_AI_HUB.ANALYTICS.VW_AT_RISK_PORTFOLIO;
DROP VIEW IF EXISTS INSURANCE_AI_HUB.ANALYTICS.VW_COMPETITIVE_PRICING;
DROP VIEW IF EXISTS INSURANCE_AI_HUB.ANALYTICS.VW_MARKET_ANALYSIS;
DROP VIEW IF EXISTS INSURANCE_AI_HUB.ANALYTICS.VW_MATCH_ACCURACY;
DROP VIEW IF EXISTS INSURANCE_AI_HUB.DATA_QUALITY.VW_DQ_ROOT_CAUSE;


-- ############################################################################
-- SECTION 8: Drop Masking Policies (must be unset before dropping)
-- ############################################################################

ALTER TABLE IF EXISTS INSURANCE_AI_HUB.ANALYTICS.CUSTOMERS
  MODIFY COLUMN EMAIL UNSET MASKING POLICY;
ALTER TABLE IF EXISTS INSURANCE_AI_HUB.ANALYTICS.CUSTOMERS
  MODIFY COLUMN PHONE UNSET MASKING POLICY;
ALTER TABLE IF EXISTS INSURANCE_AI_HUB.ANALYTICS.CUSTOMERS
  MODIFY COLUMN ADDRESS UNSET MASKING POLICY;

DROP MASKING POLICY IF EXISTS INSURANCE_AI_HUB.ANALYTICS.MASK_EMAIL;
DROP MASKING POLICY IF EXISTS INSURANCE_AI_HUB.ANALYTICS.MASK_PHONE;
DROP MASKING POLICY IF EXISTS INSURANCE_AI_HUB.ANALYTICS.MASK_ADDRESS;


-- ############################################################################
-- SECTION 9: Drop Tags
-- ############################################################################

DROP TAG IF EXISTS INSURANCE_AI_HUB.ANALYTICS.PII_LEVEL;
DROP TAG IF EXISTS INSURANCE_AI_HUB.ANALYTICS.BUSINESS_DOMAIN;


-- ############################################################################
-- SECTION 10: Drop Database Roles
-- ############################################################################

DROP DATABASE ROLE IF EXISTS INSURANCE_AI_HUB.INSURANCE_ADMIN_ROLE;
DROP DATABASE ROLE IF EXISTS INSURANCE_AI_HUB.INSURANCE_ANALYST_ROLE;
DROP DATABASE ROLE IF EXISTS INSURANCE_AI_HUB.INSURANCE_EXEC_ROLE;
DROP DATABASE ROLE IF EXISTS INSURANCE_AI_HUB.INSURANCE_UW_ROLE;
DROP DATABASE ROLE IF EXISTS INSURANCE_AI_HUB.INSURANCE_CLAIMS_ROLE;
DROP DATABASE ROLE IF EXISTS INSURANCE_AI_HUB.INSURANCE_DATA_STEWARD_ROLE;


-- ############################################################################
-- SECTION 11: Drop Database (cascades all tables, schemas)
-- This is the nuclear option. Comment out if you want to keep the database
-- and only drop individual objects above.
-- ############################################################################

-- DROP DATABASE IF EXISTS INSURANCE_AI_HUB;


-- ############################################################################
-- SECTION 12: Drop Account-level objects
-- Only run these if fully removing the solution from the account.
-- ############################################################################

-- DROP RESOURCE MONITOR IF EXISTS INSURANCE_AI_HUB_MONITOR;
-- DROP WAREHOUSE IF EXISTS COMPUTE_WH;
-- DROP ROLE IF EXISTS INSURANCE_SERVICE_ROLE;
-- DROP ROLE IF EXISTS INSURANCE_DEPLOY_ROLE;

-- ============================================================================
-- END OF 20_rollback.sql
-- ============================================================================
