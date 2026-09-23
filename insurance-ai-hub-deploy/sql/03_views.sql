-- ============================================================================
-- INSURANCE AI HUB - Production Deployment
-- Script 03: Analytical Views
-- ============================================================================
-- Run as: ACCOUNTADMIN
-- Depends on: 02_tables.sql
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE INSURANCE_AI_HUB;

-- ############################################################################
-- View 1: Customer 360
-- ############################################################################

CREATE OR REPLACE VIEW ANALYTICS.VW_CUSTOMER_360 AS
WITH policy_agg AS (
    SELECT CUSTOMER_ID,
           COUNT(DISTINCT POLICY_ID) AS policy_count,
           SUM(PREMIUM_AMOUNT) AS total_premium,
           SUM(COVERAGE_AMOUNT) AS total_coverage
    FROM INSURANCE_AI_HUB.ANALYTICS.POLICIES
    GROUP BY CUSTOMER_ID
),
claim_agg AS (
    SELECT CUSTOMER_ID,
           COUNT(DISTINCT CLAIM_ID) AS claim_count,
           SUM(CLAIM_AMOUNT) AS total_claim_amount,
           SUM(CASE WHEN FRAUD_FLAG THEN 1 ELSE 0 END) AS fraud_flagged_claims,
           AVG(FRAUD_SCORE) AS avg_fraud_score
    FROM INSURANCE_AI_HUB.ANALYTICS.CLAIMS
    GROUP BY CUSTOMER_ID
),
billing_agg AS (
    SELECT CUSTOMER_ID,
           SUM(OUTSTANDING_BALANCE) AS total_outstanding,
           SUM(LATE_FEE) AS total_late_fees
    FROM INSURANCE_AI_HUB.ANALYTICS.BILLING
    GROUP BY CUSTOMER_ID
),
risk_agg AS (
    SELECT CUSTOMER_ID,
           MAX(RISK_SCORE) AS max_risk_score,
           MAX(CHURN_PROBABILITY) AS max_churn_probability,
           SUM(REVENUE_AT_RISK) AS total_revenue_at_risk
    FROM INSURANCE_AI_HUB.ANALYTICS.AT_RISK_POLICIES
    GROUP BY CUSTOMER_ID
)
SELECT
    c.CUSTOMER_ID,
    c.FIRST_NAME,
    c.LAST_NAME,
    c.GENDER,
    c.CITY,
    c.STATE,
    c.RISK_TIER,
    c.CREDIT_SCORE,
    c.SEGMENT,
    c.CUSTOMER_SINCE,
    COALESCE(p.policy_count, 0) AS policy_count,
    COALESCE(p.total_premium, 0) AS total_premium,
    COALESCE(p.total_coverage, 0) AS total_coverage,
    COALESCE(cl.claim_count, 0) AS claim_count,
    COALESCE(cl.total_claim_amount, 0) AS total_claim_amount,
    COALESCE(cl.fraud_flagged_claims, 0) AS fraud_flagged_claims,
    cl.avg_fraud_score,
    COALESCE(b.total_outstanding, 0) AS total_outstanding,
    COALESCE(b.total_late_fees, 0) AS total_late_fees,
    ar.max_risk_score,
    ar.max_churn_probability,
    COALESCE(ar.total_revenue_at_risk, 0) AS total_revenue_at_risk
FROM INSURANCE_AI_HUB.ANALYTICS.CUSTOMERS c
LEFT JOIN policy_agg p ON c.CUSTOMER_ID = p.CUSTOMER_ID
LEFT JOIN claim_agg cl ON c.CUSTOMER_ID = cl.CUSTOMER_ID
LEFT JOIN billing_agg b ON c.CUSTOMER_ID = b.CUSTOMER_ID
LEFT JOIN risk_agg ar ON c.CUSTOMER_ID = ar.CUSTOMER_ID;


-- ############################################################################
-- View 2: Claims Performance
-- ############################################################################

CREATE OR REPLACE VIEW ANALYTICS.VW_CLAIMS_PERFORMANCE AS
SELECT
    cl.CLAIM_ID,
    cl.CLAIM_DATE,
    cl.CLAIM_TYPE,
    cl.CLAIM_STATUS,
    cl.CLAIM_AMOUNT,
    cl.APPROVED_AMOUNT,
    cl.FRAUD_FLAG,
    cl.FRAUD_SCORE,
    cl.ASSIGNED_ADJUSTER,
    cl.DAYS_TO_RESOLVE,
    cl.FRICTION_POINT,
    cl.PRIORITY,
    p.POLICY_TYPE,
    p.PLAN_TIER,
    p.PREMIUM_AMOUNT AS policy_premium,
    p.COVERAGE_AMOUNT AS policy_coverage,
    p.LOSS_RATIO AS policy_loss_ratio,
    c.RISK_TIER AS customer_risk_tier,
    c.SEGMENT AS customer_segment,
    c.STATE AS customer_state,
    a.AGENT_NAME AS adjuster_name,
    a.REGION AS adjuster_region
FROM INSURANCE_AI_HUB.ANALYTICS.CLAIMS cl
LEFT JOIN INSURANCE_AI_HUB.ANALYTICS.POLICIES p ON cl.POLICY_ID = p.POLICY_ID
LEFT JOIN INSURANCE_AI_HUB.ANALYTICS.CUSTOMERS c ON cl.CUSTOMER_ID = c.CUSTOMER_ID
LEFT JOIN INSURANCE_AI_HUB.ANALYTICS.AGENTS a ON p.AGENT_ID = a.AGENT_ID;


-- ############################################################################
-- View 3: At-Risk Portfolio
-- ############################################################################

CREATE OR REPLACE VIEW ANALYTICS.VW_AT_RISK_PORTFOLIO AS
SELECT
    ar.RISK_ID,
    ar.POLICY_ID,
    ar.CUSTOMER_ID,
    ar.RISK_CATEGORY,
    ar.RISK_SCORE,
    ar.REVENUE_AT_RISK,
    ar.CHURN_PROBABILITY,
    ar.DAYS_SINCE_CONTACT,
    ar.COMPLAINTS_COUNT,
    ar.MISSED_PAYMENTS,
    ar.RECOMMENDED_ACTION,
    ar.IDENTIFIED_DATE,
    p.POLICY_TYPE,
    p.PREMIUM_AMOUNT,
    p.COVERAGE_AMOUNT,
    p.POLICY_STATUS,
    c.FIRST_NAME || ' ' || c.LAST_NAME AS customer_name,
    c.RISK_TIER,
    c.CREDIT_SCORE,
    c.SEGMENT,
    c.STATE
FROM INSURANCE_AI_HUB.ANALYTICS.AT_RISK_POLICIES ar
LEFT JOIN INSURANCE_AI_HUB.ANALYTICS.POLICIES p ON ar.POLICY_ID = p.POLICY_ID
LEFT JOIN INSURANCE_AI_HUB.ANALYTICS.CUSTOMERS c ON ar.CUSTOMER_ID = c.CUSTOMER_ID;


-- ############################################################################
-- View 4: DQ Root Cause
-- ############################################################################

CREATE OR REPLACE VIEW DATA_QUALITY.VW_DQ_ROOT_CAUSE AS
SELECT
    r.RESULT_ID,
    r.EXECUTION_DATE,
    r.TARGET_TABLE,
    r.TARGET_COLUMN,
    r.TOTAL_RECORDS,
    r.PASSED_RECORDS,
    r.FAILED_RECORDS,
    r.PASS_RATE,
    r.STATUS AS result_status,
    r.ERROR_SAMPLE,
    rl.RULE_NAME,
    rl.RULE_DESCRIPTION,
    rl.RULE_TYPE,
    rl.SEVERITY,
    rl.IS_CRITICAL,
    rl.THRESHOLD_PCT,
    s.OVERALL_SCORE AS table_score,
    s.COMPLETENESS_SCORE,
    s.ACCURACY_SCORE,
    s.CONSISTENCY_SCORE,
    s.TIMELINESS_SCORE,
    s.TREND AS score_trend,
    ch.NULL_PCT,
    ch.DISTINCT_COUNT,
    ch.OUTLIER_COUNT,
    ch.FORMAT_VIOLATION_COUNT,
    ch.HEALTH_STATUS AS column_health_status,
    ch.SCORE AS column_health_score
FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_RESULTS r
LEFT JOIN INSURANCE_AI_HUB.DATA_QUALITY.DQ_RULES rl ON r.RULE_ID = rl.RULE_ID
LEFT JOIN INSURANCE_AI_HUB.DATA_QUALITY.DQ_SCORES s
    ON r.TARGET_TABLE = s.TABLE_NAME
    AND DATE(r.EXECUTION_DATE) = s.SCORE_DATE
LEFT JOIN INSURANCE_AI_HUB.DATA_QUALITY.DQ_COLUMN_HEALTH ch
    ON r.TARGET_TABLE = ch.TABLE_NAME
    AND r.TARGET_COLUMN = ch.COLUMN_NAME
    AND DATE(r.EXECUTION_DATE) = ch.CHECK_DATE;

-- ============================================================================
-- END OF 03_views.sql
-- ============================================================================
