-- ============================================================================
-- INSURANCE AI HUB - Production Deployment
-- Script 01: Governance (Tags, Masking Policies)
-- ============================================================================
-- Run as: ACCOUNTADMIN
-- Depends on: 00_setup.sql
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE INSURANCE_AI_HUB;
USE SCHEMA ANALYTICS;

-- ############################################################################
-- SECTION 1: TAGS
-- ############################################################################

CREATE TAG IF NOT EXISTS INSURANCE_AI_HUB.ANALYTICS.PII_LEVEL
  ALLOWED_VALUES 'HIGH', 'MEDIUM', 'LOW', 'NONE'
  COMMENT = 'PII sensitivity classification for data governance';

CREATE TAG IF NOT EXISTS INSURANCE_AI_HUB.ANALYTICS.BUSINESS_DOMAIN
  ALLOWED_VALUES 'CUSTOMER', 'POLICY', 'CLAIMS', 'BILLING', 'RISK', 'DOCUMENTS', 'DATA_QUALITY'
  COMMENT = 'Business domain classification for data catalog';


-- ############################################################################
-- SECTION 2: MASKING POLICIES
-- ############################################################################

CREATE OR REPLACE MASKING POLICY INSURANCE_AI_HUB.ANALYTICS.MASK_EMAIL AS (val VARCHAR) RETURNS VARCHAR ->
  CASE
    WHEN IS_DATABASE_ROLE_IN_SESSION('INSURANCE_AI_HUB.INSURANCE_ADMIN_ROLE') THEN val
    ELSE REGEXP_REPLACE(val, '(^[^@]{2})[^@]*(@.*)', '\\1***\\2')
  END;

CREATE OR REPLACE MASKING POLICY INSURANCE_AI_HUB.ANALYTICS.MASK_PHONE AS (val VARCHAR) RETURNS VARCHAR ->
  CASE
    WHEN IS_DATABASE_ROLE_IN_SESSION('INSURANCE_AI_HUB.INSURANCE_ADMIN_ROLE') THEN val
    ELSE '***-****'
  END;

CREATE OR REPLACE MASKING POLICY INSURANCE_AI_HUB.ANALYTICS.MASK_ADDRESS AS (val VARCHAR) RETURNS VARCHAR ->
  CASE
    WHEN IS_DATABASE_ROLE_IN_SESSION('INSURANCE_AI_HUB.INSURANCE_ADMIN_ROLE') THEN val
    ELSE '*** REDACTED ***'
  END;

-- ============================================================================
-- END OF 01_governance.sql
-- ============================================================================
