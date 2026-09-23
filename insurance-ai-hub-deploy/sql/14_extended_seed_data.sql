-- ============================================================================
-- INSURANCE AI HUB - Enhancement Deployment
-- Script 14: Seed Data for Extended Tables (~400 rows)
-- NOTE: This script is IDEMPOTENT — it truncates before inserting.
-- ============================================================================
-- Run as: ACCOUNTADMIN
-- Depends on: 10_extended_tables.sql
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE INSURANCE_AI_HUB;
USE SCHEMA ANALYTICS;

-- Truncate extended tables in reverse-dependency order
TRUNCATE TABLE IF EXISTS INSURANCE_AI_HUB.ANALYTICS.PRICING_SCENARIOS;
TRUNCATE TABLE IF EXISTS INSURANCE_AI_HUB.ANALYTICS.PRODUCT_MATCH_SCORES;
TRUNCATE TABLE IF EXISTS INSURANCE_AI_HUB.ANALYTICS.MARKET_TRENDS;
TRUNCATE TABLE IF EXISTS INSURANCE_AI_HUB.ANALYTICS.COMPETITOR_PRICING;
TRUNCATE TABLE IF EXISTS INSURANCE_AI_HUB.ANALYTICS.PRODUCT_CATALOG;

-- ############################################################################
-- PRODUCT_CATALOG (20 products)
-- ############################################################################

INSERT INTO PRODUCT_CATALOG
(PRODUCT_ID, PRODUCT_NAME, POLICY_TYPE, PLAN_TIER, BASE_PREMIUM, COVERAGE_LIMIT,
 DEDUCTIBLE_RANGE, MIN_CREDIT_SCORE, MIN_AGE, MAX_AGE, RISK_TIERS_ALLOWED,
 SEGMENTS_TARGETED, FEATURES, ELIGIBILITY_RULES, IS_ACTIVE, LAUNCH_DATE)
SELECT
    'PROD-' || LPAD(SEQ4()::VARCHAR, 4, '0'),
    CASE MOD(SEQ4(), 20)
        WHEN 0 THEN 'Essential Health Basic'      WHEN 1 THEN 'Essential Health Plus'
        WHEN 2 THEN 'Premium Health Gold'          WHEN 3 THEN 'Premium Health Platinum'
        WHEN 4 THEN 'Auto Liability Basic'         WHEN 5 THEN 'Auto Comprehensive Silver'
        WHEN 6 THEN 'Auto Comprehensive Gold'      WHEN 7 THEN 'Auto Premium Platinum'
        WHEN 8 THEN 'Term Life 10-Year'            WHEN 9 THEN 'Term Life 20-Year'
        WHEN 10 THEN 'Whole Life Standard'         WHEN 11 THEN 'Whole Life Premium'
        WHEN 12 THEN 'Home Basic Coverage'         WHEN 13 THEN 'Home Standard Plus'
        WHEN 14 THEN 'Home Premium Shield'         WHEN 15 THEN 'Home Ultimate Platinum'
        WHEN 16 THEN 'Health Family Bundle'        WHEN 17 THEN 'Auto Fleet Corporate'
        WHEN 18 THEN 'Life Corporate Group'        ELSE 'Home Landlord Special'
    END,
    CASE MOD(SEQ4(), 4) WHEN 0 THEN 'Health' WHEN 1 THEN 'Auto' WHEN 2 THEN 'Life' ELSE 'Home' END,
    CASE MOD(SEQ4(), 4) WHEN 0 THEN 'Bronze' WHEN 1 THEN 'Silver' WHEN 2 THEN 'Gold' ELSE 'Platinum' END,
    ROUND(UNIFORM(200, 5000, RANDOM())::FLOAT, 2),
    ROUND(UNIFORM(50000, 2000000, RANDOM())::FLOAT, 2),
    CASE MOD(SEQ4(), 3) WHEN 0 THEN '500-1000' WHEN 1 THEN '1000-2500' ELSE '2500-5000' END,
    CASE MOD(SEQ4(), 4) WHEN 0 THEN 550 WHEN 1 THEN 600 WHEN 2 THEN 650 ELSE 700 END,
    CASE MOD(SEQ4(), 3) WHEN 0 THEN 18 WHEN 1 THEN 21 ELSE 25 END,
    CASE MOD(SEQ4(), 3) WHEN 0 THEN 75 WHEN 1 THEN 70 ELSE 65 END,
    CASE MOD(SEQ4(), 3) WHEN 0 THEN 'Low,Medium,High' WHEN 1 THEN 'Low,Medium' ELSE 'Low' END,
    CASE MOD(SEQ4(), 3) WHEN 0 THEN 'Individual,Family' WHEN 1 THEN 'Individual,Corporate' ELSE 'Corporate' END,
    'Comprehensive coverage with industry-leading benefits and competitive pricing',
    'Standard eligibility: credit score, age range, and risk tier requirements apply',
    TRUE,
    DATEADD(DAY, -UNIFORM(30, 1000, RANDOM()), CURRENT_DATE())
FROM TABLE(GENERATOR(ROWCOUNT => 20));


-- ############################################################################
-- COMPETITOR_PRICING (60 benchmarks)
-- ############################################################################

INSERT INTO COMPETITOR_PRICING
(BENCHMARK_ID, COMPETITOR_NAME, POLICY_TYPE, PLAN_TIER, REGION, AVG_PREMIUM,
 MIN_PREMIUM, MAX_PREMIUM, MARKET_SHARE_PCT, CUSTOMER_RATING, CLAIMS_RATIO,
 BENCHMARK_DATE, DATA_SOURCE)
SELECT
    'BM-' || LPAD(SEQ4()::VARCHAR, 5, '0'),
    CASE MOD(SEQ4(), 6)
        WHEN 0 THEN 'BlueCross Shield'     WHEN 1 THEN 'StateFarm Insurance'
        WHEN 2 THEN 'Progressive Direct'   WHEN 3 THEN 'Allstate Financial'
        WHEN 4 THEN 'MetLife Group'         ELSE 'Liberty Mutual'
    END,
    CASE MOD(SEQ4(), 4) WHEN 0 THEN 'Health' WHEN 1 THEN 'Auto' WHEN 2 THEN 'Life' ELSE 'Home' END,
    CASE MOD(SEQ4(), 4) WHEN 0 THEN 'Bronze' WHEN 1 THEN 'Silver' WHEN 2 THEN 'Gold' ELSE 'Platinum' END,
    CASE MOD(SEQ4(), 5) WHEN 0 THEN 'Northeast' WHEN 1 THEN 'Southeast' WHEN 2 THEN 'Midwest' WHEN 3 THEN 'Southwest' ELSE 'West' END,
    ROUND(UNIFORM(300, 4500, RANDOM())::FLOAT, 2),
    ROUND(UNIFORM(150, 2000, RANDOM())::FLOAT, 2),
    ROUND(UNIFORM(3000, 8000, RANDOM())::FLOAT, 2),
    ROUND(UNIFORM(3.0, 25.0, RANDOM())::FLOAT, 2),
    ROUND(UNIFORM(3.0, 4.9, RANDOM())::FLOAT, 1),
    ROUND(UNIFORM(0.55, 0.85, RANDOM())::FLOAT, 4),
    DATEADD(DAY, -UNIFORM(0, 90, RANDOM()), CURRENT_DATE()),
    CASE MOD(SEQ4(), 3) WHEN 0 THEN 'Market Survey' WHEN 1 THEN 'Industry Report' ELSE 'Public Filings' END
FROM TABLE(GENERATOR(ROWCOUNT => 60));


-- ############################################################################
-- MARKET_TRENDS (80 trend data points)
-- ############################################################################

INSERT INTO MARKET_TRENDS
(TREND_ID, METRIC_NAME, POLICY_TYPE, REGION, PERIOD_START, PERIOD_END,
 METRIC_VALUE, PREVIOUS_VALUE, YOY_CHANGE_PCT, TREND_DIRECTION,
 INDUSTRY_BENCHMARK, OUR_PERFORMANCE, VARIANCE_TO_MARKET,
 DATA_SOURCE, CONFIDENCE_LEVEL)
SELECT
    'TRD-' || LPAD(SEQ4()::VARCHAR, 5, '0'),
    CASE MOD(SEQ4(), 5)
        WHEN 0 THEN 'PREMIUM_GROWTH_RATE'
        WHEN 1 THEN 'LOSS_RATIO'
        WHEN 2 THEN 'CLAIM_FREQUENCY'
        WHEN 3 THEN 'CUSTOMER_RETENTION'
        ELSE 'MARKET_PENETRATION'
    END,
    CASE MOD(SEQ4(), 4) WHEN 0 THEN 'Health' WHEN 1 THEN 'Auto' WHEN 2 THEN 'Life' ELSE 'Home' END,
    CASE MOD(SEQ4(), 5) WHEN 0 THEN 'Northeast' WHEN 1 THEN 'Southeast' WHEN 2 THEN 'Midwest' WHEN 3 THEN 'Southwest' ELSE 'West' END,
    DATEADD(MONTH, -UNIFORM(0, 12, RANDOM()), DATE_TRUNC('MONTH', CURRENT_DATE())),
    DATEADD(MONTH, -UNIFORM(0, 12, RANDOM()) + 1, DATE_TRUNC('MONTH', CURRENT_DATE())),
    ROUND(UNIFORM(1.0, 100.0, RANDOM())::FLOAT, 4),
    ROUND(UNIFORM(1.0, 100.0, RANDOM())::FLOAT, 4),
    ROUND(UNIFORM(-15.0, 25.0, RANDOM())::FLOAT, 4),
    CASE
        WHEN UNIFORM(-15.0, 25.0, RANDOM()) > 2 THEN 'UP'
        WHEN UNIFORM(-15.0, 25.0, RANDOM()) < -2 THEN 'DOWN'
        ELSE 'STABLE'
    END,
    ROUND(UNIFORM(1.0, 100.0, RANDOM())::FLOAT, 4),
    ROUND(UNIFORM(1.0, 100.0, RANDOM())::FLOAT, 4),
    ROUND(UNIFORM(-10.0, 10.0, RANDOM())::FLOAT, 4),
    CASE MOD(SEQ4(), 3) WHEN 0 THEN 'Industry Report' WHEN 1 THEN 'NAIC Data' ELSE 'AM Best' END,
    CASE MOD(SEQ4(), 3) WHEN 0 THEN 'HIGH' WHEN 1 THEN 'MEDIUM' ELSE 'HIGH' END
FROM TABLE(GENERATOR(ROWCOUNT => 80));


-- ############################################################################
-- PRODUCT_MATCH_SCORES (200 matches)
-- ############################################################################

INSERT INTO PRODUCT_MATCH_SCORES
(MATCH_ID, CUSTOMER_ID, PRODUCT_ID, MATCH_STRATEGY, MATCH_SCORE, CONFIDENCE,
 RANK_WITHIN_CUSTOMER, CONTRIBUTING_FACTORS, RECOMMENDED_PREMIUM,
 PREMIUM_VS_MARKET, ELIGIBLE, INELIGIBILITY_REASON, SCORED_AT)
SELECT
    'MS-' || LPAD(SEQ4()::VARCHAR, 5, '0'),
    'CUST-' || LPAD(UNIFORM(0, 199, RANDOM())::VARCHAR, 5, '0'),
    'PROD-' || LPAD(UNIFORM(0, 19, RANDOM())::VARCHAR, 4, '0'),
    CASE MOD(SEQ4(), 3) WHEN 0 THEN 'RULE_BASED' WHEN 1 THEN 'SIMILARITY' ELSE 'AI_SCORED' END,
    ROUND(UNIFORM(0.20, 0.98, RANDOM())::FLOAT, 4),
    ROUND(UNIFORM(0.50, 0.99, RANDOM())::FLOAT, 4),
    MOD(SEQ4(), 5) + 1,
    CASE MOD(SEQ4(), 4)
        WHEN 0 THEN 'Credit score: +0.15, Segment match: +0.10, Risk tier: +0.05'
        WHEN 1 THEN 'Age fit: +0.20, Coverage need: +0.15'
        WHEN 2 THEN 'AI confidence: HIGH, Profile similarity: 0.87'
        ELSE 'Rule match: 4/5 criteria met, Eligibility: PASS'
    END,
    ROUND(UNIFORM(200, 5000, RANDOM())::FLOAT, 2),
    ROUND(UNIFORM(0.80, 1.20, RANDOM())::FLOAT, 4),
    CASE WHEN UNIFORM(0, 10, RANDOM()) > 2 THEN TRUE ELSE FALSE END,
    CASE WHEN UNIFORM(0, 10, RANDOM()) <= 2 THEN 'Credit score below minimum' ELSE NULL END,
    DATEADD(HOUR, -UNIFORM(0, 720, RANDOM()), CURRENT_TIMESTAMP())
FROM TABLE(GENERATOR(ROWCOUNT => 200));


-- ############################################################################
-- PRICING_SCENARIOS (40 scenarios)
-- ############################################################################

INSERT INTO PRICING_SCENARIOS
(SCENARIO_ID, SCENARIO_NAME, POLICY_TYPE, PLAN_TIER, REGION,
 CURRENT_AVG_PREMIUM, PROPOSED_PREMIUM, PRICE_CHANGE_PCT,
 ESTIMATED_RETENTION, PROJECTED_REVENUE, REVENUE_IMPACT,
 CUSTOMER_IMPACT, COMPETITIVE_POSITION, RECOMMENDATION, CREATED_BY)
SELECT
    'SC-' || LPAD(SEQ4()::VARCHAR, 4, '0'),
    CASE MOD(SEQ4(), 5)
        WHEN 0 THEN 'Match Market Average'
        WHEN 1 THEN 'Undercut by 5%'
        WHEN 2 THEN 'Premium Position +10%'
        WHEN 3 THEN 'Aggressive Growth -15%'
        ELSE 'Retention Focus -3%'
    END || ' - ' ||
    CASE MOD(SEQ4(), 4) WHEN 0 THEN 'Health' WHEN 1 THEN 'Auto' WHEN 2 THEN 'Life' ELSE 'Home' END,
    CASE MOD(SEQ4(), 4) WHEN 0 THEN 'Health' WHEN 1 THEN 'Auto' WHEN 2 THEN 'Life' ELSE 'Home' END,
    CASE MOD(SEQ4(), 4) WHEN 0 THEN 'Bronze' WHEN 1 THEN 'Silver' WHEN 2 THEN 'Gold' ELSE 'Platinum' END,
    CASE MOD(SEQ4(), 5) WHEN 0 THEN 'Northeast' WHEN 1 THEN 'Southeast' WHEN 2 THEN 'Midwest' WHEN 3 THEN 'Southwest' ELSE 'West' END,
    ROUND(UNIFORM(500, 4000, RANDOM())::FLOAT, 2),
    ROUND(UNIFORM(400, 4500, RANDOM())::FLOAT, 2),
    ROUND(UNIFORM(-15.0, 15.0, RANDOM())::FLOAT, 2),
    ROUND(UNIFORM(0.80, 0.98, RANDOM())::FLOAT, 4),
    ROUND(UNIFORM(100000, 5000000, RANDOM())::FLOAT, 2),
    ROUND(UNIFORM(-500000, 1000000, RANDOM())::FLOAT, 2),
    UNIFORM(50, 500, RANDOM()),
    CASE MOD(SEQ4(), 3) WHEN 0 THEN 'BELOW_MARKET' WHEN 1 THEN 'AT_MARKET' ELSE 'ABOVE_MARKET' END,
    CASE MOD(SEQ4(), 4)
        WHEN 0 THEN 'Recommended: aligns with market while maintaining margin'
        WHEN 1 THEN 'Aggressive: monitor retention closely for 90 days'
        WHEN 2 THEN 'Premium: justify with enhanced benefits package'
        ELSE 'Conservative: low risk, stable revenue expected'
    END,
    'SYSTEM'
FROM TABLE(GENERATOR(ROWCOUNT => 40));
