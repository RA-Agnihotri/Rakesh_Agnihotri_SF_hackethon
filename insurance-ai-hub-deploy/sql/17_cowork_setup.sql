-- ============================================================================
-- INSURANCE AI HUB - Enhancement Deployment
-- Script 17: Snowflake CoWork (Intelligence) Setup
-- ============================================================================
-- Run as: ACCOUNTADMIN
-- Depends on: All agent scripts (07, 15, 16)
-- Note: The Snowflake Intelligence object controls which agents are visible
--       in Snowflake CoWork. If you don't create this object, all agents
--       with USAGE grants are visible by default.
-- ============================================================================

USE ROLE ACCOUNTADMIN;

-- ############################################################################
-- Enable cross-region inference for Cortex AI
-- ############################################################################

ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';

-- ############################################################################
-- Create the Snowflake Intelligence (CoWork) object
-- This is an account-level object that manages agent visibility in CoWork
-- Only ONE can exist per account
-- ############################################################################

CREATE SNOWFLAKE INTELLIGENCE IF NOT EXISTS SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT;

-- ############################################################################
-- Register all agents with CoWork
-- Agents must be added here to appear in the CoWork interface
-- ############################################################################

-- Core agent (original — used by React dashboard)
ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
  ADD AGENT INSURANCE_AI_HUB.ANALYTICS.INSURANCE_INTELLIGENCE_AGENT;

-- Unified enterprise agent (all 7 tools + MCP)
ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
  ADD AGENT INSURANCE_AI_HUB.ANALYTICS.UNIFIED_ENTERPRISE_AGENT;

-- Domain-specific agents
ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
  ADD AGENT INSURANCE_AI_HUB.ANALYTICS.MARKET_INTELLIGENCE_AGENT;

ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
  ADD AGENT INSURANCE_AI_HUB.ANALYTICS.PRICE_OPTIMIZATION_AGENT;

ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
  ADD AGENT INSURANCE_AI_HUB.ANALYTICS.PRODUCT_MATCHING_AGENT;

-- ############################################################################
-- Grant USAGE on CoWork object to roles
-- Without USAGE, roles cannot see agents in CoWork even if they have
-- USAGE on the agents themselves
-- ############################################################################

GRANT USAGE ON SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT TO ROLE ACCOUNTADMIN;
GRANT USAGE ON SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT TO ROLE SYSADMIN;
GRANT USAGE ON SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT TO ROLE PUBLIC;

-- ############################################################################
-- Verification
-- ############################################################################

-- List agents registered in CoWork
SHOW AGENTS IN SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT;

-- Describe the CoWork object
DESCRIBE SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT;
