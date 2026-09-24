-- ============================================================================
-- INSURANCE AI HUB - Complete DDL & DML Script
-- Database: INSURANCE_AI_HUB
-- Purpose: Supports 3 Snowflake Cortex AI Agents for Insurance Management
--   Agent 1: Self-Service Analytics (Structured Data)
--   Agent 2: Document Q&A (RAG for Unstructured Data)
--   Agent 3: Data Quality (Self-Service Data Trust & Root Cause)
-- ============================================================================
-- Author: Snowflake Architect
-- Created: 2025-01-28
-- Suffix Convention: All objects suffixed with 46233011
-- ============================================================================


-- ############################################################################
-- SECTION 1: DATABASE CREATION
-- ############################################################################

CREATE DATABASE IF NOT EXISTS INSURANCE_AI_HUB;


-- ############################################################################
-- SECTION 2: SCHEMA CREATION
-- ############################################################################

CREATE SCHEMA IF NOT EXISTS INSURANCE_AI_HUB.ANALYTICS;
CREATE SCHEMA IF NOT EXISTS INSURANCE_AI_HUB.DOCUMENTS;
CREATE SCHEMA IF NOT EXISTS INSURANCE_AI_HUB.DATA_QUALITY;


-- ############################################################################
-- SECTION 3: TABLE CREATION - ANALYTICS (Agent 1)
-- ############################################################################

CREATE TABLE IF NOT EXISTS INSURANCE_AI_HUB.ANALYTICS.AGENTS (
    AGENT_ID            VARCHAR(20)     PRIMARY KEY,
    AGENT_NAME          VARCHAR(100),
    AGENT_TYPE          VARCHAR(30),
    REGION              VARCHAR(50),
    BRANCH              VARCHAR(50),
    HIRE_DATE           DATE,
    LICENSE_NUMBER      VARCHAR(30),
    SPECIALIZATION      VARCHAR(50),
    PERFORMANCE_RATING  FLOAT,
    ACTIVE_FLAG         BOOLEAN         DEFAULT TRUE,
    CREATED_AT          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS INSURANCE_AI_HUB.ANALYTICS.CUSTOMERS (
    CUSTOMER_ID     VARCHAR(20)     PRIMARY KEY,
    FIRST_NAME      VARCHAR(50),
    LAST_NAME       VARCHAR(50),
    DATE_OF_BIRTH   DATE,
    GENDER          VARCHAR(10),
    EMAIL           VARCHAR(100),
    PHONE           VARCHAR(20),
    ADDRESS         VARCHAR(200),
    CITY            VARCHAR(50),
    STATE           VARCHAR(2),
    ZIP_CODE        VARCHAR(10),
    RISK_TIER       VARCHAR(20),
    CREDIT_SCORE    INT,
    CUSTOMER_SINCE  DATE,
    SEGMENT         VARCHAR(30),
    CREATED_AT      TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS INSURANCE_AI_HUB.ANALYTICS.POLICIES (
    POLICY_ID           VARCHAR(20)     PRIMARY KEY,
    CUSTOMER_ID         VARCHAR(20),
    AGENT_ID            VARCHAR(20),
    POLICY_TYPE         VARCHAR(20),
    POLICY_STATUS       VARCHAR(20),
    START_DATE          DATE,
    END_DATE            DATE,
    PREMIUM_AMOUNT      DECIMAL(12,2),
    COVERAGE_AMOUNT     DECIMAL(14,2),
    DEDUCTIBLE          DECIMAL(10,2),
    LOSS_RATIO          FLOAT,
    PLAN_TIER           VARCHAR(20),
    PAYMENT_FREQUENCY   VARCHAR(20),
    AUTO_RENEW          BOOLEAN,
    CREATED_AT          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS INSURANCE_AI_HUB.ANALYTICS.CLAIMS (
    CLAIM_ID            VARCHAR(20)     PRIMARY KEY,
    POLICY_ID           VARCHAR(20),
    CUSTOMER_ID         VARCHAR(20),
    CLAIM_DATE          DATE,
    CLAIM_TYPE          VARCHAR(30),
    CLAIM_STATUS        VARCHAR(30),
    CLAIM_AMOUNT        DECIMAL(12,2),
    APPROVED_AMOUNT     DECIMAL(12,2),
    FRAUD_FLAG          BOOLEAN         DEFAULT FALSE,
    FRAUD_SCORE         FLOAT,
    ASSIGNED_ADJUSTER   VARCHAR(50),
    RESOLUTION_DATE     DATE,
    DAYS_TO_RESOLVE     INT,
    FRICTION_POINT      VARCHAR(100),
    PRIORITY            VARCHAR(10),
    CREATED_AT          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS INSURANCE_AI_HUB.ANALYTICS.BILLING (
    BILLING_ID          VARCHAR(20)     PRIMARY KEY,
    POLICY_ID           VARCHAR(20),
    CUSTOMER_ID         VARCHAR(20),
    INVOICE_DATE        DATE,
    DUE_DATE            DATE,
    AMOUNT_DUE          DECIMAL(12,2),
    AMOUNT_PAID         DECIMAL(12,2),
    OUTSTANDING_BALANCE DECIMAL(12,2),
    PAYMENT_STATUS      VARCHAR(20),
    PAYMENT_METHOD      VARCHAR(30),
    PAYMENT_DATE        DATE,
    LATE_FEE            DECIMAL(8,2),
    CREATED_AT          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS INSURANCE_AI_HUB.ANALYTICS.AT_RISK_POLICIES (
    RISK_ID                 VARCHAR(20)     PRIMARY KEY,
    POLICY_ID               VARCHAR(20),
    CUSTOMER_ID             VARCHAR(20),
    RISK_CATEGORY           VARCHAR(30),
    RISK_SCORE              FLOAT,
    REVENUE_AT_RISK         DECIMAL(12,2),
    CHURN_PROBABILITY       FLOAT,
    LAST_INTERACTION_DATE   DATE,
    DAYS_SINCE_CONTACT      INT,
    COMPLAINTS_COUNT        INT,
    MISSED_PAYMENTS         INT,
    RECOMMENDED_ACTION      VARCHAR(200),
    IDENTIFIED_DATE         DATE,
    CREATED_AT              TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP()
);


-- ############################################################################
-- SECTION 4: TABLE CREATION - DOCUMENTS (Agent 2)
-- ############################################################################

CREATE TABLE IF NOT EXISTS INSURANCE_AI_HUB.DOCUMENTS.POLICY_DOCUMENTS (
    DOCUMENT_ID         VARCHAR(20)     PRIMARY KEY,
    POLICY_ID           VARCHAR(20),
    DOCUMENT_TYPE       VARCHAR(50),
    DOCUMENT_TITLE      VARCHAR(200),
    FILE_NAME           VARCHAR(200),
    FILE_FORMAT         VARCHAR(10),
    UPLOAD_DATE         DATE,
    CONTENT_TEXT        TEXT,
    EXCLUSION_CLAUSES   TEXT,
    COVERAGE_SUMMARY    TEXT,
    PAGE_COUNT          INT,
    DOCUMENT_STATUS     VARCHAR(20),
    CREATED_AT          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS INSURANCE_AI_HUB.DOCUMENTS.DOCUMENT_CHUNKS (
    CHUNK_ID        VARCHAR(20)     PRIMARY KEY,
    DOCUMENT_ID     VARCHAR(20),
    CHUNK_INDEX     INT,
    CHUNK_TEXT      TEXT,
    SECTION_TITLE   VARCHAR(200),
    TOKEN_COUNT     INT,
    EMBEDDING       VECTOR(FLOAT, 768),
    CREATED_AT      TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP()
);


-- ############################################################################
-- SECTION 5: TABLE CREATION - DATA_QUALITY (Agent 3)
-- ############################################################################

CREATE TABLE IF NOT EXISTS INSURANCE_AI_HUB.DATA_QUALITY.DQ_RULES (
    RULE_ID             VARCHAR(20)     PRIMARY KEY,
    RULE_NAME           VARCHAR(100),
    RULE_DESCRIPTION    VARCHAR(500),
    TARGET_TABLE        VARCHAR(100),
    TARGET_COLUMN       VARCHAR(100),
    RULE_TYPE           VARCHAR(30),
    RULE_EXPRESSION     VARCHAR(500),
    SEVERITY            VARCHAR(20),
    IS_CRITICAL         BOOLEAN         DEFAULT FALSE,
    THRESHOLD_PCT       FLOAT,
    ACTIVE_FLAG         BOOLEAN         DEFAULT TRUE,
    CREATED_AT          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS INSURANCE_AI_HUB.DATA_QUALITY.DQ_RESULTS (
    RESULT_ID           VARCHAR(20)     PRIMARY KEY,
    RULE_ID             VARCHAR(20),
    EXECUTION_DATE      TIMESTAMP_NTZ,
    TARGET_TABLE        VARCHAR(100),
    TARGET_COLUMN       VARCHAR(100),
    TOTAL_RECORDS       INT,
    PASSED_RECORDS      INT,
    FAILED_RECORDS      INT,
    PASS_RATE           FLOAT,
    STATUS              VARCHAR(20),
    ERROR_SAMPLE        TEXT,
    CREATED_AT          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS INSURANCE_AI_HUB.DATA_QUALITY.DQ_SCORES (
    SCORE_ID            VARCHAR(20)     PRIMARY KEY,
    TABLE_NAME          VARCHAR(100),
    SCHEMA_NAME         VARCHAR(100),
    SCORE_DATE          DATE,
    OVERALL_SCORE       FLOAT,
    COMPLETENESS_SCORE  FLOAT,
    ACCURACY_SCORE      FLOAT,
    CONSISTENCY_SCORE   FLOAT,
    TIMELINESS_SCORE    FLOAT,
    RULES_PASSED        INT,
    RULES_FAILED        INT,
    TOTAL_RULES         INT,
    TREND               VARCHAR(10),
    CREATED_AT          TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS INSURANCE_AI_HUB.DATA_QUALITY.DQ_COLUMN_HEALTH (
    HEALTH_ID               VARCHAR(20)     PRIMARY KEY,
    TABLE_NAME              VARCHAR(100),
    COLUMN_NAME             VARCHAR(100),
    CHECK_DATE              DATE,
    NULL_PCT                FLOAT,
    DISTINCT_COUNT          INT,
    DUPLICATE_PCT           FLOAT,
    OUTLIER_COUNT           INT,
    FORMAT_VIOLATION_COUNT  INT,
    HEALTH_STATUS           VARCHAR(20),
    SCORE                   FLOAT,
    IS_CRITICAL             BOOLEAN         DEFAULT FALSE,
    CREATED_AT              TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP()
);


-- ############################################################################
-- SECTION 6: DML - INSERT SAMPLE DATA
-- Note: Due to file size, the DML INSERT statements use Snowflake GENERATOR()
-- functions and are identical to what was executed to populate the database.
-- See companion file: INSURANCE_AI_HUB_DML.sql
-- ############################################################################

-- See INSURANCE_AI_HUB_DML.sql for all INSERT statements.

-- ============================================================================
-- END OF DDL SCRIPT
-- ============================================================================
