-- ============================================================================
-- INSURANCE AI HUB - Production Deployment
-- Script 07: Cortex Agent
-- ============================================================================
-- Run as: ACCOUNTADMIN
-- Depends on: 04_semantic_views.sql, 06_cortex_search.sql
-- NOTE: The agent is defined via YAML in cortex_project/ directory.
--       Deploy using: snow cortex deploy --project-dir cortex_project/
--       Or create via Snowsight Cortex Project UI.
--
--       This SQL file provides the equivalent DDL for reference.
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE INSURANCE_AI_HUB;
USE SCHEMA ANALYTICS;

-- The Cortex Agent YAML (cortex_project/INSURANCE_INTELLIGENCE_AGENT.agent.yaml)
-- defines the agent with 3 tools:
--   1. insurance_operations_analyst (Cortex Analyst → SV_INSURANCE_OPS)
--   2. data_quality_analyst (Cortex Analyst → SV_DATA_QUALITY)
--   3. policy_document_search (Cortex Search → CORTEX_SEARCH_SVC)
--
-- Deploy with:
--   snow cortex deploy --project-dir cortex_project/
--
-- Or manually create via Snowsight:
--   Projects → Cortex Projects → Import → select cortex_project/

-- Verify agent after deployment:
-- SHOW CORTEX AGENTS IN SCHEMA INSURANCE_AI_HUB.ANALYTICS;
-- DESCRIBE CORTEX AGENT INSURANCE_AI_HUB.ANALYTICS.INSURANCE_INTELLIGENCE_AGENT;

-- ============================================================================
-- END OF 07_cortex_agent.sql
-- ============================================================================
