-- ============================================================================
-- INSURANCE AI HUB - Production Deployment
-- Script 06: Cortex Search Service
-- ============================================================================
-- Run as: ACCOUNTADMIN
-- Depends on: 02_tables.sql, 09_seed_data.sql (data must exist first)
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE INSURANCE_AI_HUB;
USE SCHEMA DOCUMENTS;

-- Create Cortex Search Service for document RAG
CREATE OR REPLACE CORTEX SEARCH SERVICE CORTEX_SEARCH_SVC
  ON CHUNK_TEXT
  ATTRIBUTES SECTION_TITLE, DOCUMENT_ID
  WAREHOUSE = COMPUTE_WH
  TARGET_LAG = '1 hour'
  EMBEDDING_MODEL = 'snowflake-arctic-embed-m-v1.5'
  AS (
    SELECT
      CHUNK_ID,
      CHUNK_TEXT,
      SECTION_TITLE,
      DOCUMENT_ID,
      CHUNK_INDEX,
      TOKEN_COUNT
    FROM INSURANCE_AI_HUB.DOCUMENTS.DOCUMENT_CHUNKS
  );

-- ============================================================================
-- END OF 06_cortex_search.sql
-- ============================================================================
