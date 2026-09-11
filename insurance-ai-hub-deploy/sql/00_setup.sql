-- ============================================================================
-- INSURANCE AI HUB - Production Deployment
-- Script 00: Infrastructure Setup (Database, Schemas, Warehouse)
-- ============================================================================
-- Run as: ACCOUNTADMIN (or role with CREATE DATABASE, CREATE WAREHOUSE)
-- ============================================================================

USE ROLE ACCOUNTADMIN;

-- Database
CREATE DATABASE IF NOT EXISTS INSURANCE_AI_HUB;

-- Schemas
CREATE SCHEMA IF NOT EXISTS INSURANCE_AI_HUB.ANALYTICS;
CREATE SCHEMA IF NOT EXISTS INSURANCE_AI_HUB.DOCUMENTS;
CREATE SCHEMA IF NOT EXISTS INSURANCE_AI_HUB.DATA_QUALITY;

-- Warehouse (adjust size/auto-suspend for your workload)
CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH
  WAREHOUSE_SIZE = 'SMALL'
  AUTO_SUSPEND = 300
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = FALSE
  ENABLE_QUERY_ACCELERATION = TRUE;

USE DATABASE INSURANCE_AI_HUB;
USE WAREHOUSE COMPUTE_WH;

-- ============================================================================
-- END OF 00_setup.sql
-- ============================================================================
