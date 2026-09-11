-- ============================================================================
-- INSURANCE AI HUB - Enhancement Deployment
-- Script 10: Extended Tables (5 new tables for competitive intel, market
--            intelligence, and product matching)
-- ============================================================================
-- Run as: ACCOUNTADMIN
-- Depends on: 00_setup.sql, 01_governance.sql, 02_tables.sql
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE INSURANCE_AI_HUB;
USE SCHEMA ANALYTICS;

-- ############################################################################
-- Table 1: PRODUCT_CATALOG
-- Master product catalog for insurance products offered
-- ############################################################################

CREATE TABLE IF NOT EXISTS PRODUCT_CATALOG (
    PRODUCT_ID          VARCHAR(20)   PRIMARY KEY,
    PRODUCT_NAME        VARCHAR(200)  NOT NULL,
    POLICY_TYPE         VARCHAR(50)   NOT NULL,       -- Health, Auto, Life, Home
    PLAN_TIER           VARCHAR(20)   NOT NULL,       -- Bronze, Silver, Gold, Platinum
    BASE_PREMIUM        NUMBER(12,2)  NOT NULL,
    COVERAGE_LIMIT      NUMBER(14,2),
    DEDUCTIBLE_RANGE    VARCHAR(50),                  -- e.g. '500-2000'
    MIN_CREDIT_SCORE    NUMBER(3,0),
    MIN_AGE             NUMBER(3,0),
    MAX_AGE             NUMBER(3,0),
    RISK_TIERS_ALLOWED  VARCHAR(200),                 -- comma-separated: 'Low,Medium'
    SEGMENTS_TARGETED   VARCHAR(200),                 -- comma-separated: 'Individual,Corporate'
    FEATURES            VARCHAR(2000),                -- product features description
    ELIGIBILITY_RULES   VARCHAR(2000),                -- human-readable eligibility
    IS_ACTIVE           BOOLEAN       DEFAULT TRUE,
    LAUNCH_DATE         DATE,
    CREATED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Master product catalog for insurance offerings'
WITH TAG (ANALYTICS.BUSINESS_DOMAIN = 'POLICY');

-- ############################################################################
-- Table 2: COMPETITOR_PRICING
-- Competitive pricing benchmarks from market data
-- ############################################################################

CREATE TABLE IF NOT EXISTS COMPETITOR_PRICING (
    BENCHMARK_ID        VARCHAR(20)   PRIMARY KEY,
    COMPETITOR_NAME     VARCHAR(100)  NOT NULL,
    POLICY_TYPE         VARCHAR(50)   NOT NULL,
    PLAN_TIER           VARCHAR(20)   NOT NULL,
    REGION              VARCHAR(50)   NOT NULL,
    AVG_PREMIUM         NUMBER(12,2)  NOT NULL,
    MIN_PREMIUM         NUMBER(12,2),
    MAX_PREMIUM         NUMBER(12,2),
    MARKET_SHARE_PCT    NUMBER(5,2),
    CUSTOMER_RATING     NUMBER(3,1),                  -- 1.0 to 5.0
    CLAIMS_RATIO        NUMBER(5,4),                  -- loss ratio
    BENCHMARK_DATE      DATE          NOT NULL,
    DATA_SOURCE         VARCHAR(100)  DEFAULT 'Market Survey',
    CREATED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Competitive pricing benchmarks for market analysis'
WITH TAG (ANALYTICS.BUSINESS_DOMAIN = 'POLICY');

-- ############################################################################
-- Table 3: MARKET_TRENDS
-- Industry-level market trend data
-- ############################################################################

CREATE TABLE IF NOT EXISTS MARKET_TRENDS (
    TREND_ID            VARCHAR(20)   PRIMARY KEY,
    METRIC_NAME         VARCHAR(100)  NOT NULL,       -- e.g. 'PREMIUM_GROWTH_RATE'
    POLICY_TYPE         VARCHAR(50),
    REGION              VARCHAR(50),
    PERIOD_START        DATE          NOT NULL,
    PERIOD_END          DATE          NOT NULL,
    METRIC_VALUE        NUMBER(14,4)  NOT NULL,
    PREVIOUS_VALUE      NUMBER(14,4),
    YOY_CHANGE_PCT      NUMBER(8,4),
    TREND_DIRECTION     VARCHAR(10),                  -- UP, DOWN, STABLE
    INDUSTRY_BENCHMARK  NUMBER(14,4),
    OUR_PERFORMANCE     NUMBER(14,4),
    VARIANCE_TO_MARKET  NUMBER(8,4),                  -- our perf - benchmark
    DATA_SOURCE         VARCHAR(100)  DEFAULT 'Industry Report',
    CONFIDENCE_LEVEL    VARCHAR(20)   DEFAULT 'HIGH', -- HIGH, MEDIUM, LOW
    CREATED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Industry market trends and benchmarks'
WITH TAG (ANALYTICS.BUSINESS_DOMAIN = 'RISK');

-- ############################################################################
-- Table 4: PRODUCT_MATCH_SCORES
-- AI-generated product-customer match recommendations
-- ############################################################################

CREATE TABLE IF NOT EXISTS PRODUCT_MATCH_SCORES (
    MATCH_ID            VARCHAR(20)   PRIMARY KEY,
    CUSTOMER_ID         VARCHAR(20)   NOT NULL REFERENCES CUSTOMERS(CUSTOMER_ID),
    PRODUCT_ID          VARCHAR(20)   NOT NULL REFERENCES PRODUCT_CATALOG(PRODUCT_ID),
    MATCH_STRATEGY      VARCHAR(30)   NOT NULL,       -- RULE_BASED, SIMILARITY, AI_SCORED
    MATCH_SCORE         NUMBER(5,4)   NOT NULL,       -- 0.0 to 1.0
    CONFIDENCE          NUMBER(5,4),
    RANK_WITHIN_CUSTOMER NUMBER(3,0),
    CONTRIBUTING_FACTORS VARCHAR(1000),                -- JSON-like explanation
    RECOMMENDED_PREMIUM NUMBER(12,2),
    PREMIUM_VS_MARKET   NUMBER(8,4),                  -- ratio: recommended / market avg
    ELIGIBLE            BOOLEAN       DEFAULT TRUE,
    INELIGIBILITY_REASON VARCHAR(500),
    SCORED_AT           TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    CREATED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Product-customer match scores from multi-strategy engine'
WITH TAG (ANALYTICS.BUSINESS_DOMAIN = 'CUSTOMER');

-- ############################################################################
-- Table 5: PRICING_SCENARIOS
-- What-if pricing scenario analysis results
-- ############################################################################

CREATE TABLE IF NOT EXISTS PRICING_SCENARIOS (
    SCENARIO_ID         VARCHAR(20)   PRIMARY KEY,
    SCENARIO_NAME       VARCHAR(200)  NOT NULL,
    POLICY_TYPE         VARCHAR(50)   NOT NULL,
    PLAN_TIER           VARCHAR(20),
    REGION              VARCHAR(50),
    CURRENT_AVG_PREMIUM NUMBER(12,2)  NOT NULL,
    PROPOSED_PREMIUM    NUMBER(12,2)  NOT NULL,
    PRICE_CHANGE_PCT    NUMBER(8,4),
    ESTIMATED_RETENTION NUMBER(5,4),                  -- retention rate 0-1
    PROJECTED_REVENUE   NUMBER(14,2),
    REVENUE_IMPACT      NUMBER(14,2),                 -- projected - current
    CUSTOMER_IMPACT     NUMBER(8,0),                  -- # customers affected
    COMPETITIVE_POSITION VARCHAR(50),                 -- BELOW_MARKET, AT_MARKET, ABOVE_MARKET
    RECOMMENDATION      VARCHAR(500),
    CREATED_BY          VARCHAR(100)  DEFAULT 'SYSTEM',
    CREATED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'What-if pricing scenario analysis'
WITH TAG (ANALYTICS.BUSINESS_DOMAIN = 'POLICY');
