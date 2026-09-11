-- ============================================================================
-- INSURANCE AI HUB - Production Deployment
-- Script 04: Semantic Views (with Verified Queries & CA Extensions)
-- ============================================================================
-- Run as: ACCOUNTADMIN
-- Depends on: 02_tables.sql
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE INSURANCE_AI_HUB;

-- ############################################################################
-- Semantic View 1: Insurance Operations (ANALYTICS schema)
-- 6 tables, 2 relationships, 15 facts, 66 dimensions, 10 VQRs
-- ############################################################################

USE SCHEMA ANALYTICS;

create or replace semantic view SV_INSURANCE_OPS
	tables (
		INSURANCE_AI_HUB.ANALYTICS.CUSTOMERS primary key (CUSTOMER_ID),
		INSURANCE_AI_HUB.ANALYTICS.POLICIES primary key (POLICY_ID),
		INSURANCE_AI_HUB.ANALYTICS.CLAIMS primary key (CLAIM_ID),
		INSURANCE_AI_HUB.ANALYTICS.BILLING primary key (BILLING_ID),
		INSURANCE_AI_HUB.ANALYTICS.AT_RISK_POLICIES primary key (RISK_ID),
		INSURANCE_AI_HUB.ANALYTICS.AGENTS primary key (AGENT_ID)
	)
	relationships (
		POLICIES_TO_CUSTOMERS as POLICIES(CUSTOMER_ID) references CUSTOMERS(CUSTOMER_ID),
		CLAIMS_TO_CUSTOMERS as CLAIMS(CUSTOMER_ID) references CUSTOMERS(CUSTOMER_ID)
	)
	facts (
		POLICIES.PREMIUM_AMOUNT as PREMIUM_AMOUNT,
		POLICIES.COVERAGE_AMOUNT as COVERAGE_AMOUNT,
		POLICIES.DEDUCTIBLE as DEDUCTIBLE,
		POLICIES.LOSS_RATIO as LOSS_RATIO,
		CLAIMS.CLAIM_AMOUNT as CLAIM_AMOUNT,
		CLAIMS.APPROVED_AMOUNT as APPROVED_AMOUNT,
		CLAIMS.FRAUD_SCORE as FRAUD_SCORE,
		BILLING.AMOUNT_DUE as AMOUNT_DUE,
		BILLING.AMOUNT_PAID as AMOUNT_PAID,
		BILLING.OUTSTANDING_BALANCE as OUTSTANDING_BALANCE,
		BILLING.LATE_FEE as LATE_FEE,
		AT_RISK_POLICIES.RISK_SCORE as RISK_SCORE,
		AT_RISK_POLICIES.REVENUE_AT_RISK as REVENUE_AT_RISK,
		AT_RISK_POLICIES.CHURN_PROBABILITY as CHURN_PROBABILITY,
		AGENTS.PERFORMANCE_RATING as PERFORMANCE_RATING
	)
	dimensions (
		CUSTOMERS.CUSTOMER_ID as CUSTOMER_ID,
		CUSTOMERS.FIRST_NAME as FIRST_NAME,
		CUSTOMERS.LAST_NAME as LAST_NAME,
		CUSTOMERS.GENDER as GENDER,
		CUSTOMERS.EMAIL as EMAIL,
		CUSTOMERS.PHONE as PHONE,
		CUSTOMERS.ADDRESS as ADDRESS,
		CUSTOMERS.CITY as CITY,
		CUSTOMERS.STATE as STATE,
		CUSTOMERS.ZIP_CODE as ZIP_CODE,
		CUSTOMERS.RISK_TIER as RISK_TIER,
		CUSTOMERS.CREDIT_SCORE as CREDIT_SCORE,
		CUSTOMERS.SEGMENT as SEGMENT,
		CUSTOMERS.DATE_OF_BIRTH as DATE_OF_BIRTH,
		CUSTOMERS.CUSTOMER_SINCE as CUSTOMER_SINCE,
		CUSTOMERS.CREATED_AT as CREATED_AT,
		POLICIES.POLICY_ID as POLICY_ID,
		POLICIES.CUSTOMER_ID as CUSTOMER_ID,
		POLICIES.AGENT_ID as AGENT_ID,
		POLICIES.POLICY_TYPE as POLICY_TYPE,
		POLICIES.POLICY_STATUS as POLICY_STATUS,
		POLICIES.PLAN_TIER as PLAN_TIER,
		POLICIES.PAYMENT_FREQUENCY as PAYMENT_FREQUENCY,
		POLICIES.AUTO_RENEW as AUTO_RENEW,
		POLICIES.START_DATE as START_DATE,
		POLICIES.END_DATE as END_DATE,
		POLICIES.CREATED_AT as CREATED_AT,
		CLAIMS.CLAIM_ID as CLAIM_ID,
		CLAIMS.POLICY_ID as POLICY_ID,
		CLAIMS.CUSTOMER_ID as CUSTOMER_ID,
		CLAIMS.CLAIM_TYPE as CLAIM_TYPE,
		CLAIMS.CLAIM_STATUS as CLAIM_STATUS,
		CLAIMS.FRAUD_FLAG as FRAUD_FLAG,
		CLAIMS.ASSIGNED_ADJUSTER as ASSIGNED_ADJUSTER,
		CLAIMS.DAYS_TO_RESOLVE as DAYS_TO_RESOLVE,
		CLAIMS.FRICTION_POINT as FRICTION_POINT,
		CLAIMS.PRIORITY as PRIORITY,
		CLAIMS.CLAIM_DATE as CLAIM_DATE,
		CLAIMS.RESOLUTION_DATE as RESOLUTION_DATE,
		CLAIMS.CREATED_AT as CREATED_AT,
		BILLING.BILLING_ID as BILLING_ID,
		BILLING.POLICY_ID as POLICY_ID,
		BILLING.CUSTOMER_ID as CUSTOMER_ID,
		BILLING.PAYMENT_STATUS as PAYMENT_STATUS,
		BILLING.PAYMENT_METHOD as PAYMENT_METHOD,
		BILLING.INVOICE_DATE as INVOICE_DATE,
		BILLING.DUE_DATE as DUE_DATE,
		BILLING.PAYMENT_DATE as PAYMENT_DATE,
		BILLING.CREATED_AT as CREATED_AT,
		AT_RISK_POLICIES.RISK_ID as RISK_ID,
		AT_RISK_POLICIES.POLICY_ID as POLICY_ID,
		AT_RISK_POLICIES.CUSTOMER_ID as CUSTOMER_ID,
		AT_RISK_POLICIES.RISK_CATEGORY as RISK_CATEGORY,
		AT_RISK_POLICIES.DAYS_SINCE_CONTACT as DAYS_SINCE_CONTACT,
		AT_RISK_POLICIES.COMPLAINTS_COUNT as COMPLAINTS_COUNT,
		AT_RISK_POLICIES.MISSED_PAYMENTS as MISSED_PAYMENTS,
		AT_RISK_POLICIES.RECOMMENDED_ACTION as RECOMMENDED_ACTION,
		AT_RISK_POLICIES.LAST_INTERACTION_DATE as LAST_INTERACTION_DATE,
		AT_RISK_POLICIES.IDENTIFIED_DATE as IDENTIFIED_DATE,
		AT_RISK_POLICIES.CREATED_AT as CREATED_AT,
		AGENTS.AGENT_ID as AGENT_ID,
		AGENTS.AGENT_NAME as AGENT_NAME,
		AGENTS.AGENT_TYPE as AGENT_TYPE,
		AGENTS.REGION as REGION,
		AGENTS.BRANCH as BRANCH,
		AGENTS.LICENSE_NUMBER as LICENSE_NUMBER,
		AGENTS.SPECIALIZATION as SPECIALIZATION,
		AGENTS.ACTIVE_FLAG as ACTIVE_FLAG,
		AGENTS.HIRE_DATE as HIRE_DATE,
		AGENTS.CREATED_AT as CREATED_AT
	)
	comment='Insurance operations analytics model covering customers, policies, claims, billing, agents, and at-risk policies. Supports natural-language queries for KPI analysis, trend detection, risk assessment, fraud intelligence, and operational reporting across the insurance portfolio.'
	ai_verified_queries (
		"0;1" AS ( 
QUESTION 'What is the total premium revenue by policy type for active policies?' 
VERIFIED_AT 1788433742
VERIFIED_BY 'Semantic Model Generator'
ONBOARDING_QUESTION false
SQL 'SELECT POLICY_TYPE, COUNT(*) AS policy_count, SUM(PREMIUM_AMOUNT) AS total_premium FROM policies WHERE POLICY_STATUS = ''Active'' GROUP BY POLICY_TYPE ORDER BY total_premium DESC'),
		"1;1" AS ( 
QUESTION 'What is the breakdown of claims by type and status, including both volume and total amounts?' 
VERIFIED_AT 1788433742
VERIFIED_BY 'Semantic Model Generator'
ONBOARDING_QUESTION false
SQL 'SELECT CLAIM_TYPE, CLAIM_STATUS, COUNT(*) AS claim_count, SUM(CLAIM_AMOUNT) AS total_claim_amount FROM claims GROUP BY CLAIM_TYPE, CLAIM_STATUS ORDER BY total_claim_amount DESC'),
		"2;1" AS ( 
QUESTION 'What is the total revenue at risk and average churn probability across all at-risk policies?' 
VERIFIED_AT 1788433742
VERIFIED_BY 'Semantic Model Generator'
ONBOARDING_QUESTION false
SQL 'SELECT SUM(REVENUE_AT_RISK) AS total_revenue_at_risk, AVG(CHURN_PROBABILITY) AS avg_churn_prob, COUNT(*) AS at_risk_count FROM at_risk_policies'),
		"3;1" AS ( 
QUESTION 'What are the total claims by customer state?' 
VERIFIED_AT 1788433742
VERIFIED_BY 'Semantic Model Generator'
ONBOARDING_QUESTION false
SQL 'SELECT c.STATE, COUNT(DISTINCT cl.CLAIM_ID) AS claim_count, SUM(cl.CLAIM_AMOUNT) AS total_claims FROM claims AS cl JOIN customers AS c ON cl.CUSTOMER_ID = c.CUSTOMER_ID GROUP BY c.STATE ORDER BY total_claims DESC'),
		"4;1" AS ( 
QUESTION 'What is the revenue at risk breakdown by risk category?' 
VERIFIED_AT 1788433742
VERIFIED_BY 'Semantic Model Generator'
ONBOARDING_QUESTION false
SQL 'SELECT RISK_CATEGORY, COUNT(*) AS policy_count, SUM(REVENUE_AT_RISK) AS total_revenue_at_risk, AVG(RISK_SCORE) AS avg_risk_score FROM at_risk_policies GROUP BY RISK_CATEGORY ORDER BY total_revenue_at_risk DESC'),
		"5;1" AS ( 
QUESTION 'What is the claims workload and average resolution time by adjuster?' 
VERIFIED_AT 1788433742
VERIFIED_BY 'Semantic Model Generator'
ONBOARDING_QUESTION false
SQL 'SELECT ASSIGNED_ADJUSTER, COUNT(*) AS claim_count, AVG(DAYS_TO_RESOLVE) AS avg_resolution_days, SUM(CLAIM_AMOUNT) AS total_claim_amount FROM claims WHERE NOT DAYS_TO_RESOLVE IS NULL GROUP BY ASSIGNED_ADJUSTER ORDER BY claim_count DESC'),
		"6;1" AS ( 
QUESTION 'What is the billing summary by payment status?' 
VERIFIED_AT 1788433742
VERIFIED_BY 'Semantic Model Generator'
ONBOARDING_QUESTION false
SQL 'SELECT PAYMENT_STATUS, COUNT(*) AS invoice_count, SUM(AMOUNT_DUE) AS total_due, SUM(AMOUNT_PAID) AS total_paid, SUM(OUTSTANDING_BALANCE) AS total_outstanding FROM billing GROUP BY PAYMENT_STATUS'),
		"7;1" AS ( 
QUESTION 'How many high fraud risk claims are there and what is the total fraud risk exposure?' 
VERIFIED_AT 1788433742
VERIFIED_BY 'Semantic Model Generator'
ONBOARDING_QUESTION false
SQL 'SELECT COUNT(DISTINCT CASE WHEN FRAUD_SCORE > 0.7 THEN CLAIM_ID END) AS high_risk_claims, SUM(CASE WHEN FRAUD_SCORE > 0.7 THEN CLAIM_AMOUNT ELSE 0 END) AS fraud_risk_exposure FROM claims'),
		"8;1" AS ( 
QUESTION 'What is the active policy portfolio summary by type including loss ratio?' 
VERIFIED_AT 1788433742
VERIFIED_BY 'Semantic Model Generator'
ONBOARDING_QUESTION false
SQL 'SELECT p.POLICY_TYPE, COUNT(DISTINCT p.POLICY_ID) AS active_policies, SUM(p.PREMIUM_AMOUNT) AS total_premium, AVG(p.LOSS_RATIO) AS avg_loss_ratio FROM policies AS p WHERE p.POLICY_STATUS = ''Active'' GROUP BY p.POLICY_TYPE'),
		"9;1" AS ( 
QUESTION 'What is the customer and policy distribution by customer segment?' 
VERIFIED_AT 1788433742
VERIFIED_BY 'Semantic Model Generator'
ONBOARDING_QUESTION false
SQL 'SELECT c.SEGMENT, COUNT(DISTINCT c.CUSTOMER_ID) AS customer_count, COUNT(DISTINCT p.POLICY_ID) AS policy_count, SUM(p.PREMIUM_AMOUNT) AS total_premium FROM customers AS c LEFT JOIN policies AS p ON c.CUSTOMER_ID = p.CUSTOMER_ID GROUP BY c.SEGMENT')
	)
	with extension (CA='{"tables":[{"name":"CUSTOMERS","dimensions":[{"name":"CUSTOMER_ID"},{"name":"FIRST_NAME"},{"name":"LAST_NAME"},{"name":"GENDER"},{"name":"EMAIL"},{"name":"PHONE"},{"name":"ADDRESS"},{"name":"CITY"},{"name":"STATE"},{"name":"ZIP_CODE"},{"name":"RISK_TIER"},{"name":"CREDIT_SCORE"},{"name":"SEGMENT"}],"time_dimensions":[{"name":"DATE_OF_BIRTH"},{"name":"CUSTOMER_SINCE"},{"name":"CREATED_AT"}]},{"name":"POLICIES","dimensions":[{"name":"POLICY_ID"},{"name":"CUSTOMER_ID"},{"name":"AGENT_ID"},{"name":"POLICY_TYPE"},{"name":"POLICY_STATUS"},{"name":"PLAN_TIER"},{"name":"PAYMENT_FREQUENCY"},{"name":"AUTO_RENEW"}],"facts":[{"name":"PREMIUM_AMOUNT"},{"name":"COVERAGE_AMOUNT"},{"name":"DEDUCTIBLE"},{"name":"LOSS_RATIO"}],"time_dimensions":[{"name":"START_DATE"},{"name":"END_DATE"},{"name":"CREATED_AT"}]},{"name":"CLAIMS","dimensions":[{"name":"CLAIM_ID"},{"name":"POLICY_ID"},{"name":"CUSTOMER_ID"},{"name":"CLAIM_TYPE"},{"name":"CLAIM_STATUS"},{"name":"FRAUD_FLAG"},{"name":"ASSIGNED_ADJUSTER"},{"name":"DAYS_TO_RESOLVE"},{"name":"FRICTION_POINT"},{"name":"PRIORITY"}],"facts":[{"name":"CLAIM_AMOUNT"},{"name":"APPROVED_AMOUNT"},{"name":"FRAUD_SCORE"}],"time_dimensions":[{"name":"CLAIM_DATE"},{"name":"RESOLUTION_DATE"},{"name":"CREATED_AT"}]},{"name":"BILLING","dimensions":[{"name":"BILLING_ID"},{"name":"POLICY_ID"},{"name":"CUSTOMER_ID"},{"name":"PAYMENT_STATUS"},{"name":"PAYMENT_METHOD"}],"facts":[{"name":"AMOUNT_DUE"},{"name":"AMOUNT_PAID"},{"name":"OUTSTANDING_BALANCE"},{"name":"LATE_FEE"}],"time_dimensions":[{"name":"INVOICE_DATE"},{"name":"DUE_DATE"},{"name":"PAYMENT_DATE"},{"name":"CREATED_AT"}]},{"name":"AT_RISK_POLICIES","dimensions":[{"name":"RISK_ID"},{"name":"POLICY_ID"},{"name":"CUSTOMER_ID"},{"name":"RISK_CATEGORY"},{"name":"DAYS_SINCE_CONTACT"},{"name":"COMPLAINTS_COUNT"},{"name":"MISSED_PAYMENTS"},{"name":"RECOMMENDED_ACTION"}],"facts":[{"name":"RISK_SCORE"},{"name":"REVENUE_AT_RISK"},{"name":"CHURN_PROBABILITY"}],"time_dimensions":[{"name":"LAST_INTERACTION_DATE"},{"name":"IDENTIFIED_DATE"},{"name":"CREATED_AT"}]},{"name":"AGENTS","dimensions":[{"name":"AGENT_ID"},{"name":"AGENT_NAME"},{"name":"AGENT_TYPE"},{"name":"REGION"},{"name":"BRANCH"},{"name":"LICENSE_NUMBER"},{"name":"SPECIALIZATION"},{"name":"ACTIVE_FLAG"}],"facts":[{"name":"PERFORMANCE_RATING"}],"time_dimensions":[{"name":"HIRE_DATE"},{"name":"CREATED_AT"}]}],"relationships":[{"name":"CLAIMS_TO_CUSTOMERS","relationship_type":"many_to_one","join_type":"inner"},{"name":"POLICIES_TO_CUSTOMERS","relationship_type":"many_to_one","join_type":"inner"}]}');


-- ############################################################################
-- Semantic View 2: Data Quality (DATA_QUALITY schema)
-- 4 tables, 1 relationship, 10 facts, 40 dimensions, 5 VQRs
-- ############################################################################

USE SCHEMA DATA_QUALITY;

create or replace semantic view SV_DATA_QUALITY
	tables (
		INSURANCE_AI_HUB.DATA_QUALITY.DQ_RULES primary key (RULE_ID),
		INSURANCE_AI_HUB.DATA_QUALITY.DQ_RESULTS primary key (RESULT_ID),
		INSURANCE_AI_HUB.DATA_QUALITY.DQ_SCORES primary key (SCORE_ID),
		INSURANCE_AI_HUB.DATA_QUALITY.DQ_COLUMN_HEALTH primary key (HEALTH_ID)
	)
	relationships (
		DQ_RESULTS_TO_DQ_RULES as DQ_RESULTS(RULE_ID) references DQ_RULES(RULE_ID)
	)
	facts (
		DQ_RULES.THRESHOLD_PCT as THRESHOLD_PCT,
		DQ_RESULTS.PASS_RATE as PASS_RATE,
		DQ_SCORES.OVERALL_SCORE as OVERALL_SCORE,
		DQ_SCORES.COMPLETENESS_SCORE as COMPLETENESS_SCORE,
		DQ_SCORES.ACCURACY_SCORE as ACCURACY_SCORE,
		DQ_SCORES.CONSISTENCY_SCORE as CONSISTENCY_SCORE,
		DQ_SCORES.TIMELINESS_SCORE as TIMELINESS_SCORE,
		DQ_COLUMN_HEALTH.NULL_PCT as NULL_PCT,
		DQ_COLUMN_HEALTH.DUPLICATE_PCT as DUPLICATE_PCT,
		DQ_COLUMN_HEALTH.SCORE as SCORE
	)
	dimensions (
		DQ_RULES.RULE_ID as RULE_ID,
		DQ_RULES.RULE_NAME as RULE_NAME,
		DQ_RULES.RULE_DESCRIPTION as RULE_DESCRIPTION,
		DQ_RULES.TARGET_TABLE as TARGET_TABLE,
		DQ_RULES.TARGET_COLUMN as TARGET_COLUMN,
		DQ_RULES.RULE_TYPE as RULE_TYPE,
		DQ_RULES.RULE_EXPRESSION as RULE_EXPRESSION,
		DQ_RULES.SEVERITY as SEVERITY,
		DQ_RULES.IS_CRITICAL as IS_CRITICAL,
		DQ_RULES.ACTIVE_FLAG as ACTIVE_FLAG,
		DQ_RULES.CREATED_AT as CREATED_AT,
		DQ_RESULTS.RESULT_ID as RESULT_ID,
		DQ_RESULTS.RULE_ID as RULE_ID,
		DQ_RESULTS.TARGET_TABLE as TARGET_TABLE,
		DQ_RESULTS.TARGET_COLUMN as TARGET_COLUMN,
		DQ_RESULTS.TOTAL_RECORDS as TOTAL_RECORDS,
		DQ_RESULTS.PASSED_RECORDS as PASSED_RECORDS,
		DQ_RESULTS.FAILED_RECORDS as FAILED_RECORDS,
		DQ_RESULTS.STATUS as STATUS,
		DQ_RESULTS.ERROR_SAMPLE as ERROR_SAMPLE,
		DQ_RESULTS.EXECUTION_DATE as EXECUTION_DATE,
		DQ_RESULTS.CREATED_AT as CREATED_AT,
		DQ_SCORES.SCORE_ID as SCORE_ID,
		DQ_SCORES.TABLE_NAME as TABLE_NAME,
		DQ_SCORES.SCHEMA_NAME as SCHEMA_NAME,
		DQ_SCORES.RULES_PASSED as RULES_PASSED,
		DQ_SCORES.RULES_FAILED as RULES_FAILED,
		DQ_SCORES.TOTAL_RULES as TOTAL_RULES,
		DQ_SCORES.TREND as TREND,
		DQ_SCORES.SCORE_DATE as SCORE_DATE,
		DQ_SCORES.CREATED_AT as CREATED_AT,
		DQ_COLUMN_HEALTH.HEALTH_ID as HEALTH_ID,
		DQ_COLUMN_HEALTH.TABLE_NAME as TABLE_NAME,
		DQ_COLUMN_HEALTH.COLUMN_NAME as COLUMN_NAME,
		DQ_COLUMN_HEALTH.DISTINCT_COUNT as DISTINCT_COUNT,
		DQ_COLUMN_HEALTH.OUTLIER_COUNT as OUTLIER_COUNT,
		DQ_COLUMN_HEALTH.FORMAT_VIOLATION_COUNT as FORMAT_VIOLATION_COUNT,
		DQ_COLUMN_HEALTH.HEALTH_STATUS as HEALTH_STATUS,
		DQ_COLUMN_HEALTH.IS_CRITICAL as IS_CRITICAL,
		DQ_COLUMN_HEALTH.CHECK_DATE as CHECK_DATE,
		DQ_COLUMN_HEALTH.CREATED_AT as CREATED_AT
	)
	comment='Data quality monitoring model covering quality rules, execution results, table-level scores, and column-level health. Supports conversational data quality investigation, root-cause analysis, trend monitoring, and remediation tracking.'
	ai_verified_queries (
		"0;1" AS ( 
QUESTION 'Which tables have the lowest data quality scores?' 
VERIFIED_AT 1788433817
VERIFIED_BY 'Semantic Model Generator'
ONBOARDING_QUESTION false
SQL 'SELECT TABLE_NAME, OVERALL_SCORE, COMPLETENESS_SCORE, ACCURACY_SCORE, CONSISTENCY_SCORE, TIMELINESS_SCORE, TREND FROM dq_scores WHERE SCORE_DATE = (SELECT MAX(SCORE_DATE) FROM dq_scores) ORDER BY OVERALL_SCORE ASC'),
		"1;1" AS ( 
QUESTION 'What are the failed data quality rules and their details?' 
VERIFIED_AT 1788433817
VERIFIED_BY 'Semantic Model Generator'
ONBOARDING_QUESTION false
SQL 'SELECT r.TARGET_TABLE, r.TARGET_COLUMN, rl.RULE_NAME, rl.SEVERITY, r.PASS_RATE, r.FAILED_RECORDS, r.ERROR_SAMPLE FROM dq_results AS r JOIN dq_rules AS rl ON r.RULE_ID = rl.RULE_ID WHERE r.STATUS = ''FAIL'' ORDER BY r.PASS_RATE ASC'),
		"2;1" AS ( 
QUESTION 'Which columns have critical or warning health status?' 
VERIFIED_AT 1788433817
VERIFIED_BY 'Semantic Model Generator'
ONBOARDING_QUESTION false
SQL 'SELECT TABLE_NAME, COLUMN_NAME, HEALTH_STATUS, SCORE, NULL_PCT, OUTLIER_COUNT, FORMAT_VIOLATION_COUNT FROM dq_column_health WHERE HEALTH_STATUS IN (''Critical'', ''Warning'') ORDER BY SCORE ASC'),
		"3;1" AS ( 
QUESTION 'What is the data quality score trend over time by table?' 
VERIFIED_AT 1788433817
VERIFIED_BY 'Semantic Model Generator'
ONBOARDING_QUESTION false
SQL 'SELECT TABLE_NAME, SCORE_DATE, OVERALL_SCORE, TREND FROM dq_scores ORDER BY TABLE_NAME, SCORE_DATE'),
		"4;1" AS ( 
QUESTION 'How many active data quality rules are there by type, and how many of those are critical?' 
VERIFIED_AT 1788433817
VERIFIED_BY 'Semantic Model Generator'
ONBOARDING_QUESTION false
SQL 'SELECT RULE_TYPE, COUNT(*) AS rule_count, SUM(CASE WHEN IS_CRITICAL THEN 1 ELSE 0 END) AS critical_count FROM dq_rules WHERE ACTIVE_FLAG = TRUE GROUP BY RULE_TYPE ORDER BY rule_count DESC')
	)
	with extension (CA='{"tables":[{"name":"DQ_RULES","dimensions":[{"name":"RULE_ID"},{"name":"RULE_NAME"},{"name":"RULE_DESCRIPTION"},{"name":"TARGET_TABLE"},{"name":"TARGET_COLUMN"},{"name":"RULE_TYPE"},{"name":"RULE_EXPRESSION"},{"name":"SEVERITY"},{"name":"IS_CRITICAL"},{"name":"ACTIVE_FLAG"}],"facts":[{"name":"THRESHOLD_PCT"}],"time_dimensions":[{"name":"CREATED_AT"}]},{"name":"DQ_RESULTS","dimensions":[{"name":"RESULT_ID"},{"name":"RULE_ID"},{"name":"TARGET_TABLE"},{"name":"TARGET_COLUMN"},{"name":"TOTAL_RECORDS"},{"name":"PASSED_RECORDS"},{"name":"FAILED_RECORDS"},{"name":"STATUS"},{"name":"ERROR_SAMPLE"}],"facts":[{"name":"PASS_RATE"}],"time_dimensions":[{"name":"EXECUTION_DATE"},{"name":"CREATED_AT"}]},{"name":"DQ_SCORES","dimensions":[{"name":"SCORE_ID"},{"name":"TABLE_NAME"},{"name":"SCHEMA_NAME"},{"name":"RULES_PASSED"},{"name":"RULES_FAILED"},{"name":"TOTAL_RULES"},{"name":"TREND"}],"facts":[{"name":"OVERALL_SCORE"},{"name":"COMPLETENESS_SCORE"},{"name":"ACCURACY_SCORE"},{"name":"CONSISTENCY_SCORE"},{"name":"TIMELINESS_SCORE"}],"time_dimensions":[{"name":"SCORE_DATE"},{"name":"CREATED_AT"}]},{"name":"DQ_COLUMN_HEALTH","dimensions":[{"name":"HEALTH_ID"},{"name":"TABLE_NAME"},{"name":"COLUMN_NAME"},{"name":"DISTINCT_COUNT"},{"name":"OUTLIER_COUNT"},{"name":"FORMAT_VIOLATION_COUNT"},{"name":"HEALTH_STATUS"},{"name":"IS_CRITICAL"}],"facts":[{"name":"NULL_PCT"},{"name":"DUPLICATE_PCT"},{"name":"SCORE"}],"time_dimensions":[{"name":"CHECK_DATE"},{"name":"CREATED_AT"}]}],"relationships":[{"name":"DQ_RESULTS_TO_DQ_RULES","relationship_type":"many_to_one","join_type":"inner"}]}');

-- ============================================================================
-- END OF 04_semantic_views.sql
-- ============================================================================
