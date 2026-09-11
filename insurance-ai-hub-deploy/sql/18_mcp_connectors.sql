-- ============================================================================
-- INSURANCE AI HUB - Enhancement Deployment
-- Script 18: MCP Connectors (Atlassian Jira + Confluence)
-- ============================================================================
-- Run as: ACCOUNTADMIN
-- Prerequisites:
--   1. Navigate to admin.atlassian.com
--   2. Apps > AI Settings > Rovo MCP Server
--   3. Under "Your domains", add: https://identity.snowflake.com/oauth2/callback
--
-- This script uses Dynamic Client Registration (DCR) OAuth, which means
-- Snowflake auto-registers with Atlassian. No client_id/secret needed.
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE INSURANCE_AI_HUB;
USE SCHEMA ANALYTICS;

-- ############################################################################
-- Step 1: Create the API Integration for Atlassian
-- Uses OAUTH_DYNAMIC_CLIENT (DCR) — no pre-registered credentials needed
-- ############################################################################

CREATE API INTEGRATION IF NOT EXISTS JIRA_MCP_API_INTEGRATION
  API_PROVIDER = external_mcp
  API_ALLOWED_PREFIXES = ('https://mcp.atlassian.com')
  API_USER_AUTHENTICATION = (
    TYPE = OAUTH_DYNAMIC_CLIENT,
    OAUTH_RESOURCE_URL = 'https://mcp.atlassian.com/v1/mcp'
  )
  ENABLED = TRUE;

-- ############################################################################
-- Step 2: Create the External MCP Server
-- This is the object that Cortex Agents reference in their mcp_servers spec
-- ############################################################################

CREATE EXTERNAL MCP SERVER IF NOT EXISTS ATLASSIAN_MCP_SERVER
  WITH DISPLAY_NAME = 'Atlassian (Jira & Confluence)'
  URL = 'https://mcp.atlassian.com/v1/mcp'
  API_INTEGRATION = JIRA_MCP_API_INTEGRATION;

-- ############################################################################
-- Step 3: Grant USAGE to roles
-- Both the MCP server AND its API integration need USAGE grants
-- ############################################################################

GRANT USAGE ON EXTERNAL MCP SERVER ATLASSIAN_MCP_SERVER TO ROLE ACCOUNTADMIN;
GRANT USAGE ON INTEGRATION JIRA_MCP_API_INTEGRATION TO ROLE ACCOUNTADMIN;

-- Optionally grant to broader roles for multi-user access
GRANT USAGE ON EXTERNAL MCP SERVER ATLASSIAN_MCP_SERVER TO ROLE PUBLIC;
GRANT USAGE ON INTEGRATION JIRA_MCP_API_INTEGRATION TO ROLE PUBLIC;

-- ############################################################################
-- Step 4: Verification
-- ############################################################################

-- List all external MCP servers
SHOW EXTERNAL MCP SERVERS;

-- Describe the MCP server and its integration
DESCRIBE EXTERNAL MCP SERVER ATLASSIAN_MCP_SERVER;
DESCRIBE INTEGRATION JIRA_MCP_API_INTEGRATION;

-- ############################################################################
-- Post-Deployment Steps (Manual):
--
-- 1. Go to Snowsight > AI & ML > Agents > Settings > Tools and Connectors
--    - Verify ATLASSIAN_MCP_SERVER appears as "Enabled"
--
-- 2. Go to Snowflake CoWork
--    - Open an agent that has MCP attached (e.g., Insurance Enterprise Hub)
--    - Click "+" > Connectors > Atlassian
--    - Complete the OAuth popup to authenticate your Atlassian account
--
-- 3. Test: Ask the agent "Create a Jira ticket to review Health pricing"
--
-- Note: Each user must independently complete the OAuth flow.
-- One user's authentication does not carry over to another.
-- ############################################################################
