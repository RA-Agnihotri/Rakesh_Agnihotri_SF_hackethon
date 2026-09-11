-- ============================================================================
-- INSURANCE AI HUB - Enhancement Deployment
-- Script 11: Extended Views (3 new analytical views)
-- ============================================================================
-- Run as: ACCOUNTADMIN
-- Depends on: 10_extended_tables.sql
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE INSURANCE_AI_HUB;
USE SCHEMA ANALYTICS;

-- ############################################################################
-- View 1: VW_COMPETITIVE_PRICING
-- Our pricing vs competitors with market position analysis
-- ############################################################################

CREATE OR REPLACE VIEW VW_COMPETITIVE_PRICING AS
SELECT
    cp.BENCHMARK_ID,
    cp.COMPETITOR_NAME,
    cp.POLICY_TYPE,
    cp.PLAN_TIER,
    cp.REGION,
    cp.AVG_PREMIUM       AS COMPETITOR_AVG_PREMIUM,
    cp.MIN_PREMIUM       AS COMPETITOR_MIN_PREMIUM,
    cp.MAX_PREMIUM       AS COMPETITOR_MAX_PREMIUM,
    cp.MARKET_SHARE_PCT,
    cp.CUSTOMER_RATING   AS COMPETITOR_RATING,
    cp.CLAIMS_RATIO      AS COMPETITOR_LOSS_RATIO,
    our.OUR_AVG_PREMIUM,
    our.OUR_POLICY_COUNT,
    our.OUR_AVG_LOSS_RATIO,
    ROUND(our.OUR_AVG_PREMIUM / NULLIF(cp.AVG_PREMIUM, 0), 4) AS PRICE_RATIO,
    CASE
        WHEN our.OUR_AVG_PREMIUM < cp.AVG_PREMIUM * 0.95 THEN 'BELOW_MARKET'
        WHEN our.OUR_AVG_PREMIUM > cp.AVG_PREMIUM * 1.05 THEN 'ABOVE_MARKET'
        ELSE 'AT_MARKET'
    END AS COMPETITIVE_POSITION,
    ROUND(our.OUR_AVG_PREMIUM - cp.AVG_PREMIUM, 2) AS PREMIUM_DIFFERENCE,
    cp.BENCHMARK_DATE
FROM COMPETITOR_PRICING cp
LEFT JOIN (
    SELECT
        POLICY_TYPE,
        PLAN_TIER,
        AVG(PREMIUM_AMOUNT)  AS OUR_AVG_PREMIUM,
        COUNT(*)             AS OUR_POLICY_COUNT,
        AVG(LOSS_RATIO)      AS OUR_AVG_LOSS_RATIO
    FROM POLICIES
    WHERE POLICY_STATUS = 'Active'
    GROUP BY POLICY_TYPE, PLAN_TIER
) our ON cp.POLICY_TYPE = our.POLICY_TYPE AND cp.PLAN_TIER = our.PLAN_TIER;

-- ############################################################################
-- View 2: VW_MATCH_ACCURACY
-- Product matching performance across strategies
-- ############################################################################

CREATE OR REPLACE VIEW VW_MATCH_ACCURACY AS
SELECT
    ms.MATCH_STRATEGY,
    ms.PRODUCT_ID,
    pc.PRODUCT_NAME,
    pc.POLICY_TYPE,
    pc.PLAN_TIER,
    c.SEGMENT          AS CUSTOMER_SEGMENT,
    c.RISK_TIER        AS CUSTOMER_RISK_TIER,
    COUNT(*)           AS TOTAL_MATCHES,
    AVG(ms.MATCH_SCORE)    AS AVG_MATCH_SCORE,
    AVG(ms.CONFIDENCE)     AS AVG_CONFIDENCE,
    SUM(CASE WHEN ms.ELIGIBLE THEN 1 ELSE 0 END) AS ELIGIBLE_COUNT,
    SUM(CASE WHEN NOT ms.ELIGIBLE THEN 1 ELSE 0 END) AS INELIGIBLE_COUNT,
    ROUND(SUM(CASE WHEN ms.ELIGIBLE THEN 1 ELSE 0 END)::FLOAT / NULLIF(COUNT(*), 0), 4)
        AS ELIGIBILITY_RATE,
    AVG(ms.PREMIUM_VS_MARKET) AS AVG_PREMIUM_VS_MARKET,
    AVG(ms.RECOMMENDED_PREMIUM) AS AVG_RECOMMENDED_PREMIUM
FROM PRODUCT_MATCH_SCORES ms
JOIN PRODUCT_CATALOG pc ON ms.PRODUCT_ID = pc.PRODUCT_ID
JOIN CUSTOMERS c ON ms.CUSTOMER_ID = c.CUSTOMER_ID
GROUP BY ms.MATCH_STRATEGY, ms.PRODUCT_ID, pc.PRODUCT_NAME,
         pc.POLICY_TYPE, pc.PLAN_TIER, c.SEGMENT, c.RISK_TIER;

-- ############################################################################
-- View 3: VW_MARKET_ANALYSIS
-- Market trends with internal performance comparison
-- ############################################################################

CREATE OR REPLACE VIEW VW_MARKET_ANALYSIS AS
SELECT
    mt.TREND_ID,
    mt.METRIC_NAME,
    mt.POLICY_TYPE,
    mt.REGION,
    mt.PERIOD_START,
    mt.PERIOD_END,
    mt.METRIC_VALUE,
    mt.PREVIOUS_VALUE,
    mt.YOY_CHANGE_PCT,
    mt.TREND_DIRECTION,
    mt.INDUSTRY_BENCHMARK,
    mt.OUR_PERFORMANCE,
    mt.VARIANCE_TO_MARKET,
    mt.CONFIDENCE_LEVEL,
    CASE
        WHEN mt.VARIANCE_TO_MARKET > 0.05 THEN 'OUTPERFORMING'
        WHEN mt.VARIANCE_TO_MARKET < -0.05 THEN 'UNDERPERFORMING'
        ELSE 'ON_PAR'
    END AS PERFORMANCE_STATUS,
    CASE
        WHEN mt.TREND_DIRECTION = 'UP' AND mt.YOY_CHANGE_PCT > 10 THEN 'STRONG_GROWTH'
        WHEN mt.TREND_DIRECTION = 'UP' THEN 'MODERATE_GROWTH'
        WHEN mt.TREND_DIRECTION = 'DOWN' AND mt.YOY_CHANGE_PCT < -10 THEN 'SIGNIFICANT_DECLINE'
        WHEN mt.TREND_DIRECTION = 'DOWN' THEN 'SLIGHT_DECLINE'
        ELSE 'STABLE'
    END AS TREND_CATEGORY,
    mt.DATA_SOURCE
FROM MARKET_TRENDS mt;
