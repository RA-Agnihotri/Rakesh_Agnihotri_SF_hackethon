-- ============================================================================
-- INSURANCE AI HUB - Production Deployment
-- Script 00: Infrastructure Setup (Database, Schemas, Warehouse, Roles, Monitor)
-- ============================================================================
-- Run as: ACCOUNTADMIN (or role with CREATE DATABASE, CREATE WAREHOUSE, CREATE ROLE)
-- ============================================================================

USE ROLE ACCOUNTADMIN;

-- ############################################################################
-- SECTION 1: Account Roles for Deployment & Runtime
-- ############################################################################

-- INSURANCE_DEPLOY_ROLE: Used to run deployment scripts (DDL).
-- After deployment, object ownership is transferred to this role so that
-- ACCOUNTADMIN is no longer the owner of solution objects.
CREATE ROLE IF NOT EXISTS INSURANCE_DEPLOY_ROLE
  COMMENT = 'Deployment role for Insurance AI Hub DDL operations';

-- INSURANCE_SERVICE_ROLE: Runtime role for agent execution, tasks, and
-- application-level access. Agents and tasks should run under this role,
-- not ACCOUNTADMIN.
CREATE ROLE IF NOT EXISTS INSURANCE_SERVICE_ROLE
  COMMENT = 'Service role for Insurance AI Hub runtime operations (agents, tasks)';

-- Grant deploy role to SYSADMIN (standard hierarchy)
GRANT ROLE INSURANCE_DEPLOY_ROLE TO ROLE SYSADMIN;
GRANT ROLE INSURANCE_SERVICE_ROLE TO ROLE SYSADMIN;

-- Deploy role needs CREATE privileges
GRANT CREATE DATABASE ON ACCOUNT TO ROLE INSURANCE_DEPLOY_ROLE;
GRANT CREATE WAREHOUSE ON ACCOUNT TO ROLE INSURANCE_DEPLOY_ROLE;

-- ############################################################################
-- SECTION 2: Database & Schemas
-- ############################################################################

-- Database
CREATE DATABASE IF NOT EXISTS INSURANCE_AI_HUB;

-- Transfer ownership to deploy role
GRANT OWNERSHIP ON DATABASE INSURANCE_AI_HUB TO ROLE INSURANCE_DEPLOY_ROLE COPY CURRENT GRANTS;

-- Schemas
CREATE SCHEMA IF NOT EXISTS INSURANCE_AI_HUB.ANALYTICS;
CREATE SCHEMA IF NOT EXISTS INSURANCE_AI_HUB.DOCUMENTS;
CREATE SCHEMA IF NOT EXISTS INSURANCE_AI_HUB.DATA_QUALITY;

-- ############################################################################
-- SECTION 3: Warehouse
-- ############################################################################

-- Warehouse (adjust size/auto-suspend for your workload)
CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH
  WAREHOUSE_SIZE = 'SMALL'
  AUTO_SUSPEND = 300
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = FALSE
  ENABLE_QUERY_ACCELERATION = TRUE;

-- Grant warehouse usage to service role (agents + tasks need this)
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE INSURANCE_SERVICE_ROLE;
GRANT OPERATE ON WAREHOUSE COMPUTE_WH TO ROLE INSURANCE_SERVICE_ROLE;
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE INSURANCE_DEPLOY_ROLE;

-- ############################################################################
-- SECTION 4: Resource Monitor (AI cost guardrail)
-- Caps total credit consumption to prevent runaway Cortex AI costs,
-- especially with CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION'.
-- Adjust CREDIT_QUOTA to your budget. 500 credits/month is a starting point.
-- ############################################################################

CREATE RESOURCE MONITOR IF NOT EXISTS INSURANCE_AI_HUB_MONITOR
  WITH
    CREDIT_QUOTA = 500
    FREQUENCY = MONTHLY
    START_TIMESTAMP = IMMEDIATELY
    TRIGGERS
      ON 75 PERCENT DO NOTIFY
      ON 90 PERCENT DO NOTIFY
      ON 100 PERCENT DO SUSPEND;

ALTER WAREHOUSE COMPUTE_WH SET RESOURCE_MONITOR = INSURANCE_AI_HUB_MONITOR;

-- ############################################################################
-- SECTION 4b: Budget (Serverless AI cost guardrail)
-- Resource monitors only cover warehouse credits. Cortex AI inference,
-- Cortex Search, and serverless tasks are billed as serverless credits
-- outside of warehouses. A budget caps ALL credit types.
-- Adjust spending_limit to your monthly AI budget.
-- ############################################################################

-- Budget requires a database+schema context for the instance object.
-- We use INSURANCE_AI_HUB.ANALYTICS as the home schema.
USE DATABASE INSURANCE_AI_HUB;
USE SCHEMA ANALYTICS;

CREATE SNOWFLAKE.CORE.BUDGET IF NOT EXISTS INSURANCE_AI_HUB_BUDGET();
CALL INSURANCE_AI_HUB.ANALYTICS.INSURANCE_AI_HUB_BUDGET!SET_SPENDING_LIMIT(1000);

-- ADD_RESOURCE requires APPLYBUDGET privilege on the warehouse.
GRANT APPLYBUDGET ON WAREHOUSE COMPUTE_WH TO ROLE ACCOUNTADMIN;

-- Adds the warehouse to the budget so BOTH warehouse + serverless are tracked.
-- SYSTEM$REFERENCE needs the APPLYBUDGET privilege qualifier to resolve.
CALL INSURANCE_AI_HUB.ANALYTICS.INSURANCE_AI_HUB_BUDGET!ADD_RESOURCE(
  SYSTEM$REFERENCE('WAREHOUSE', 'COMPUTE_WH', 'SESSION', 'APPLYBUDGET')
);

-- ############################################################################
-- SECTION 5: Grant database access to service role
-- ############################################################################

GRANT USAGE ON DATABASE INSURANCE_AI_HUB TO ROLE INSURANCE_SERVICE_ROLE;
GRANT USAGE ON SCHEMA INSURANCE_AI_HUB.ANALYTICS TO ROLE INSURANCE_SERVICE_ROLE;
GRANT USAGE ON SCHEMA INSURANCE_AI_HUB.DOCUMENTS TO ROLE INSURANCE_SERVICE_ROLE;
GRANT USAGE ON SCHEMA INSURANCE_AI_HUB.DATA_QUALITY TO ROLE INSURANCE_SERVICE_ROLE;

USE DATABASE INSURANCE_AI_HUB;
USE WAREHOUSE COMPUTE_WH;

-- ============================================================================
-- END OF 00_setup.sql
-- ============================================================================
