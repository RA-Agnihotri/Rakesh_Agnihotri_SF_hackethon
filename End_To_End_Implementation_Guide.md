# End-to-End Implementation Guide

## Insurance Intelligence Platform — Phase-by-Phase Build Guide

---

## Phase 1: Data Preparation

### Step 1.1: Create Database and Schemas

```sql
-- Execute the DDL script to create the database, schemas, and all 12 tables
-- Source: INSURANCE_AI_HUB_DDL_DML.sql

CREATE DATABASE IF NOT EXISTS INSURANCE_AI_HUB;

CREATE SCHEMA IF NOT EXISTS INSURANCE_AI_HUB.ANALYTICS;
CREATE SCHEMA IF NOT EXISTS INSURANCE_AI_HUB.DOCUMENTS;
CREATE SCHEMA IF NOT EXISTS INSURANCE_AI_HUB.DATA_QUALITY;
```

### Step 1.2: Load Sample Data

```sql
-- Execute DML scripts in order:
-- 1. INSURANCE_AI_HUB_DML.sql        → ANALYTICS tables (1,585 rows)
-- 2. INSURANCE_AI_HUB_DML_PART2.sql  → DOCUMENTS + DQ rules/scores (93 rows)
-- 3. INSURANCE_AI_HUB_DML_DQ_RESULTS.sql → DQ results + column health (68 rows)

-- Verify row counts after loading
SELECT 'AGENTS' AS tbl, COUNT(*) AS cnt FROM INSURANCE_AI_HUB.ANALYTICS.AGENTS
UNION ALL SELECT 'CUSTOMERS', COUNT(*) FROM INSURANCE_AI_HUB.ANALYTICS.CUSTOMERS
UNION ALL SELECT 'POLICIES', COUNT(*) FROM INSURANCE_AI_HUB.ANALYTICS.POLICIES
UNION ALL SELECT 'CLAIMS', COUNT(*) FROM INSURANCE_AI_HUB.ANALYTICS.CLAIMS
UNION ALL SELECT 'BILLING', COUNT(*) FROM INSURANCE_AI_HUB.ANALYTICS.BILLING
UNION ALL SELECT 'AT_RISK_POLICIES', COUNT(*) FROM INSURANCE_AI_HUB.ANALYTICS.AT_RISK_POLICIES
UNION ALL SELECT 'POLICY_DOCUMENTS', COUNT(*) FROM INSURANCE_AI_HUB.DOCUMENTS.POLICY_DOCUMENTS
UNION ALL SELECT 'DOCUMENT_CHUNKS', COUNT(*) FROM INSURANCE_AI_HUB.DOCUMENTS.DOCUMENT_CHUNKS
UNION ALL SELECT 'DQ_RULES', COUNT(*) FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_RULES
UNION ALL SELECT 'DQ_RESULTS', COUNT(*) FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_RESULTS
UNION ALL SELECT 'DQ_SCORES', COUNT(*) FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_SCORES
UNION ALL SELECT 'DQ_COLUMN_HEALTH', COUNT(*) FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_COLUMN_HEALTH;

-- Expected: 20, 200, 300, 400, 500, 165, 10, 25, 50, 40, 28, 28 = 1,766 total
```

### Step 1.3: Validate Referential Integrity

```sql
-- Check for orphan POLICY_IDs in CLAIMS
SELECT COUNT(*) AS orphan_claims
FROM INSURANCE_AI_HUB.ANALYTICS.CLAIMS c
LEFT JOIN INSURANCE_AI_HUB.ANALYTICS.POLICIES p ON c.POLICY_ID = p.POLICY_ID
WHERE p.POLICY_ID IS NULL;

-- Check for orphan CUSTOMER_IDs in POLICIES
SELECT COUNT(*) AS orphan_policies
FROM INSURANCE_AI_HUB.ANALYTICS.POLICIES p
LEFT JOIN INSURANCE_AI_HUB.ANALYTICS.CUSTOMERS c ON p.CUSTOMER_ID = c.CUSTOMER_ID
WHERE c.CUSTOMER_ID IS NULL;
```

### Step 1.4: Create Curated Views

```sql
-- Customer 360 View
CREATE OR REPLACE VIEW INSURANCE_AI_HUB.ANALYTICS.VW_CUSTOMER_360 AS
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
    COUNT(DISTINCT p.POLICY_ID) AS policy_count,
    SUM(p.PREMIUM_AMOUNT) AS total_premium,
    SUM(p.COVERAGE_AMOUNT) AS total_coverage,
    COUNT(DISTINCT cl.CLAIM_ID) AS claim_count,
    SUM(cl.CLAIM_AMOUNT) AS total_claim_amount,
    SUM(CASE WHEN cl.FRAUD_FLAG THEN 1 ELSE 0 END) AS fraud_flagged_claims,
    AVG(cl.FRAUD_SCORE) AS avg_fraud_score,
    SUM(b.OUTSTANDING_BALANCE) AS total_outstanding,
    SUM(b.LATE_FEE) AS total_late_fees,
    MAX(ar.RISK_SCORE) AS max_risk_score,
    MAX(ar.CHURN_PROBABILITY) AS max_churn_probability,
    SUM(ar.REVENUE_AT_RISK) AS total_revenue_at_risk
FROM INSURANCE_AI_HUB.ANALYTICS.CUSTOMERS c
LEFT JOIN INSURANCE_AI_HUB.ANALYTICS.POLICIES p ON c.CUSTOMER_ID = p.CUSTOMER_ID
LEFT JOIN INSURANCE_AI_HUB.ANALYTICS.CLAIMS cl ON c.CUSTOMER_ID = cl.CUSTOMER_ID
LEFT JOIN INSURANCE_AI_HUB.ANALYTICS.BILLING b ON c.CUSTOMER_ID = b.CUSTOMER_ID
LEFT JOIN INSURANCE_AI_HUB.ANALYTICS.AT_RISK_POLICIES ar ON c.CUSTOMER_ID = ar.CUSTOMER_ID
GROUP BY 1,2,3,4,5,6,7,8,9,10;

-- Claims Performance View
CREATE OR REPLACE VIEW INSURANCE_AI_HUB.ANALYTICS.VW_CLAIMS_PERFORMANCE AS
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

-- DQ Root Cause View
CREATE OR REPLACE VIEW INSURANCE_AI_HUB.DATA_QUALITY.VW_DQ_ROOT_CAUSE AS
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

-- At-Risk Portfolio View
CREATE OR REPLACE VIEW INSURANCE_AI_HUB.ANALYTICS.VW_AT_RISK_PORTFOLIO AS
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
```

### Step 1.5: Create Audit Log Table

```sql
CREATE TABLE IF NOT EXISTS INSURANCE_AI_HUB.ANALYTICS.AGENT_AUDIT_LOG (
    LOG_ID              VARCHAR(36)     DEFAULT UUID_STRING(),
    SESSION_ID          VARCHAR(36),
    TIMESTAMP           TIMESTAMP_NTZ   DEFAULT CURRENT_TIMESTAMP(),
    USER_NAME           VARCHAR(100),
    USER_ROLE           VARCHAR(50),
    QUESTION            TEXT,
    DETECTED_INTENT     VARCHAR(50),
    AGENT_SELECTED      VARCHAR(50),
    TOOLS_CALLED        VARIANT,
    SQL_EXECUTED        TEXT,
    DATA_SOURCES        VARIANT,
    RESPONSE_TEXT       TEXT,
    CONFIDENCE_SCORE    FLOAT,
    CITATIONS           VARIANT,
    RESPONSE_TIME_MS    INT,
    TOKEN_COUNT         INT,
    ESTIMATED_COST      FLOAT,
    HUMAN_ESCALATION    BOOLEAN         DEFAULT FALSE,
    USER_FEEDBACK       VARCHAR(10),
    ERROR_MESSAGE       TEXT,
    PRIMARY KEY (LOG_ID)
);
```

---

## Phase 2: Semantic Layer Creation

### Step 2.1: Insurance Operations Semantic View

```yaml
# SV_INSURANCE_OPS — Semantic View Definition
# File: sv_insurance_ops.yaml

name: SV_INSURANCE_OPS
description: >
  Semantic model for insurance operations analytics covering customers,
  policies, claims, billing, agents, and at-risk policies. Supports
  natural-language queries for KPI analysis, trend detection, risk
  assessment, and operational reporting.

tables:
  - name: CUSTOMERS
    base_table:
      database: INSURANCE_AI_HUB
      schema: ANALYTICS
      table: CUSTOMERS
    description: Insurance policyholders with demographics and risk profile
    dimensions:
      - name: customer_id
        expr: CUSTOMER_ID
        description: Unique customer identifier
        unique: true
      - name: customer_name
        expr: FIRST_NAME || ' ' || LAST_NAME
        description: Full customer name
      - name: gender
        expr: GENDER
        description: Customer gender
      - name: city
        expr: CITY
        description: Customer city
      - name: state
        expr: STATE
        description: Customer state (2-letter code)
      - name: risk_tier
        expr: RISK_TIER
        description: Customer risk classification (Low, Medium, High, Very High)
      - name: segment
        expr: SEGMENT
        description: Customer segment (Individual, Family, Corporate, Senior)
      - name: customer_since
        expr: CUSTOMER_SINCE
        description: Date customer relationship started
    measures:
      - name: total_customers
        expr: COUNT(DISTINCT CUSTOMER_ID)
        description: Total number of unique customers
      - name: avg_credit_score
        expr: AVG(CREDIT_SCORE)
        description: Average customer credit score

  - name: POLICIES
    base_table:
      database: INSURANCE_AI_HUB
      schema: ANALYTICS
      table: POLICIES
    description: Insurance policies across Health, Auto, Life, and Home lines
    dimensions:
      - name: policy_id
        expr: POLICY_ID
        description: Unique policy identifier
        unique: true
      - name: policy_type
        expr: POLICY_TYPE
        description: Insurance product type (Health, Auto, Life, Home)
      - name: policy_status
        expr: POLICY_STATUS
        description: Current policy status (Active, Expired, Cancelled)
      - name: plan_tier
        expr: PLAN_TIER
        description: Plan tier (Bronze, Silver, Gold, Platinum)
      - name: payment_frequency
        expr: PAYMENT_FREQUENCY
        description: Payment schedule (Monthly, Quarterly, Annual)
      - name: start_date
        expr: START_DATE
        description: Policy start date
      - name: end_date
        expr: END_DATE
        description: Policy end date
    measures:
      - name: total_policies
        expr: COUNT(DISTINCT POLICY_ID)
        description: Total number of policies
      - name: active_policies
        expr: COUNT(DISTINCT CASE WHEN POLICY_STATUS = 'Active' THEN POLICY_ID END)
        description: Count of active policies
      - name: total_premium_revenue
        expr: SUM(PREMIUM_AMOUNT)
        description: Total premium revenue
      - name: avg_premium
        expr: AVG(PREMIUM_AMOUNT)
        description: Average premium amount per policy
      - name: total_coverage_exposure
        expr: SUM(COVERAGE_AMOUNT)
        description: Total insured coverage amount
      - name: avg_loss_ratio
        expr: AVG(LOSS_RATIO)
        description: Average loss ratio across policies

  - name: CLAIMS
    base_table:
      database: INSURANCE_AI_HUB
      schema: ANALYTICS
      table: CLAIMS
    description: Insurance claims with fraud scoring and resolution tracking
    dimensions:
      - name: claim_id
        expr: CLAIM_ID
        description: Unique claim identifier
        unique: true
      - name: claim_type
        expr: CLAIM_TYPE
        description: Type of claim (Accident, Theft, Medical, Property Damage, Liability, Natural Disaster)
      - name: claim_status
        expr: CLAIM_STATUS
        description: Current claim status (Open, Under Investigation, Approved, Closed, Denied, Escalated)
      - name: priority
        expr: PRIORITY
        description: Claim priority (High, Medium, Low)
      - name: friction_point
        expr: FRICTION_POINT
        description: Processing friction or delay reason
      - name: assigned_adjuster
        expr: ASSIGNED_ADJUSTER
        description: Name of assigned claims adjuster
      - name: claim_date
        expr: CLAIM_DATE
        description: Date claim was filed
    measures:
      - name: total_claims
        expr: COUNT(DISTINCT CLAIM_ID)
        description: Total number of claims
      - name: open_claims
        expr: COUNT(DISTINCT CASE WHEN CLAIM_STATUS IN ('Open', 'Under Investigation', 'Escalated') THEN CLAIM_ID END)
        description: Count of open/active claims
      - name: total_claim_amount
        expr: SUM(CLAIM_AMOUNT)
        description: Total claimed amount
      - name: total_approved_amount
        expr: SUM(APPROVED_AMOUNT)
        description: Total approved claim amount
      - name: claims_approval_rate
        expr: COUNT(CASE WHEN CLAIM_STATUS = 'Approved' THEN 1 END) * 100.0 / NULLIF(COUNT(CASE WHEN CLAIM_STATUS IN ('Approved','Denied','Closed') THEN 1 END), 0)
        description: Percentage of decided claims that were approved
      - name: avg_resolution_days
        expr: AVG(DAYS_TO_RESOLVE)
        description: Average days to resolve a claim
      - name: fraud_flagged_claims
        expr: COUNT(CASE WHEN FRAUD_FLAG = TRUE THEN 1 END)
        description: Number of claims flagged for fraud
      - name: avg_fraud_score
        expr: AVG(FRAUD_SCORE)
        description: Average fraud risk score
      - name: fraud_risk_exposure
        expr: SUM(CASE WHEN FRAUD_SCORE > 0.7 THEN CLAIM_AMOUNT ELSE 0 END)
        description: Total claim amount for high fraud-risk claims

  - name: BILLING
    base_table:
      database: INSURANCE_AI_HUB
      schema: ANALYTICS
      table: BILLING
    description: Policy billing, invoices, and payment tracking
    dimensions:
      - name: billing_id
        expr: BILLING_ID
        description: Unique billing record identifier
        unique: true
      - name: payment_status
        expr: PAYMENT_STATUS
        description: Payment status (Paid, Overdue, Pending)
      - name: payment_method
        expr: PAYMENT_METHOD
        description: Payment method (Credit Card, Bank Transfer, Auto-Debit, Check)
      - name: invoice_date
        expr: INVOICE_DATE
        description: Date invoice was issued
    measures:
      - name: total_invoiced
        expr: SUM(AMOUNT_DUE)
        description: Total amount invoiced
      - name: total_collected
        expr: SUM(AMOUNT_PAID)
        description: Total amount collected
      - name: total_outstanding
        expr: SUM(OUTSTANDING_BALANCE)
        description: Total outstanding balance
      - name: collection_rate
        expr: SUM(AMOUNT_PAID) * 100.0 / NULLIF(SUM(AMOUNT_DUE), 0)
        description: Payment collection rate percentage
      - name: total_late_fees
        expr: SUM(LATE_FEE)
        description: Total late fees assessed

  - name: AT_RISK_POLICIES
    base_table:
      database: INSURANCE_AI_HUB
      schema: ANALYTICS
      table: AT_RISK_POLICIES
    description: Policies identified as at-risk for churn, payment default, or claims frequency
    dimensions:
      - name: risk_id
        expr: RISK_ID
        description: Unique risk record identifier
        unique: true
      - name: risk_category
        expr: RISK_CATEGORY
        description: Category of risk (Payment Default, High Claims Frequency, Customer Complaint, Policy Lapse Risk, Competitive Switch)
      - name: recommended_action
        expr: RECOMMENDED_ACTION
        description: Recommended retention or intervention action
      - name: identified_date
        expr: IDENTIFIED_DATE
        description: Date risk was identified
    measures:
      - name: at_risk_policy_count
        expr: COUNT(DISTINCT POLICY_ID)
        description: Number of at-risk policies
      - name: total_revenue_at_risk
        expr: SUM(REVENUE_AT_RISK)
        description: Total revenue at risk from at-risk policies
      - name: avg_churn_probability
        expr: AVG(CHURN_PROBABILITY)
        description: Average churn probability across at-risk policies
      - name: avg_risk_score
        expr: AVG(RISK_SCORE)
        description: Average risk score

  - name: AGENTS
    base_table:
      database: INSURANCE_AI_HUB
      schema: ANALYTICS
      table: AGENTS
    description: Insurance agents, adjusters, and underwriters
    dimensions:
      - name: agent_id
        expr: AGENT_ID
        description: Unique agent identifier
        unique: true
      - name: agent_name
        expr: AGENT_NAME
        description: Agent full name
      - name: agent_type
        expr: AGENT_TYPE
        description: Agent role type (Underwriter, Claims Adjuster, Sales Agent)
      - name: region
        expr: REGION
        description: Agent region (Northeast, Southeast, Midwest, Southwest, West)
      - name: specialization
        expr: SPECIALIZATION
        description: Insurance line specialization
    measures:
      - name: total_agents
        expr: COUNT(DISTINCT AGENT_ID)
        description: Total number of agents
      - name: avg_performance_rating
        expr: AVG(PERFORMANCE_RATING)
        description: Average agent performance rating

relationships:
  - left_table: POLICIES
    right_table: CUSTOMERS
    join_type: left
    relationship_type: many_to_one
    on:
      - left_column: CUSTOMER_ID
        right_column: CUSTOMER_ID
  - left_table: POLICIES
    right_table: AGENTS
    join_type: left
    relationship_type: many_to_one
    on:
      - left_column: AGENT_ID
        right_column: AGENT_ID
  - left_table: CLAIMS
    right_table: POLICIES
    join_type: left
    relationship_type: many_to_one
    on:
      - left_column: POLICY_ID
        right_column: POLICY_ID
  - left_table: CLAIMS
    right_table: CUSTOMERS
    join_type: left
    relationship_type: many_to_one
    on:
      - left_column: CUSTOMER_ID
        right_column: CUSTOMER_ID
  - left_table: BILLING
    right_table: POLICIES
    join_type: left
    relationship_type: many_to_one
    on:
      - left_column: POLICY_ID
        right_column: POLICY_ID
  - left_table: BILLING
    right_table: CUSTOMERS
    join_type: left
    relationship_type: many_to_one
    on:
      - left_column: CUSTOMER_ID
        right_column: CUSTOMER_ID
  - left_table: AT_RISK_POLICIES
    right_table: POLICIES
    join_type: left
    relationship_type: many_to_one
    on:
      - left_column: POLICY_ID
        right_column: POLICY_ID
  - left_table: AT_RISK_POLICIES
    right_table: CUSTOMERS
    join_type: left
    relationship_type: many_to_one
    on:
      - left_column: CUSTOMER_ID
        right_column: CUSTOMER_ID

verified_queries:
  - name: total_premium_revenue
    question: "What is the total premium revenue?"
    sql: "SELECT SUM(PREMIUM_AMOUNT) AS total_premium_revenue FROM INSURANCE_AI_HUB.ANALYTICS.POLICIES"
  - name: claims_by_type
    question: "How many claims are there by type?"
    sql: "SELECT CLAIM_TYPE, COUNT(*) AS claim_count, SUM(CLAIM_AMOUNT) AS total_amount FROM INSURANCE_AI_HUB.ANALYTICS.CLAIMS GROUP BY CLAIM_TYPE ORDER BY claim_count DESC"
  - name: revenue_at_risk
    question: "What is the total revenue at risk?"
    sql: "SELECT SUM(REVENUE_AT_RISK) AS total_revenue_at_risk FROM INSURANCE_AI_HUB.ANALYTICS.AT_RISK_POLICIES"
  - name: active_policies_by_type
    question: "How many active policies are there by product type?"
    sql: "SELECT POLICY_TYPE, COUNT(*) AS policy_count FROM INSURANCE_AI_HUB.ANALYTICS.POLICIES WHERE POLICY_STATUS = 'Active' GROUP BY POLICY_TYPE ORDER BY policy_count DESC"
```

### Step 2.2: Data Quality Semantic View

```yaml
# SV_DATA_QUALITY — Semantic View Definition
name: SV_DATA_QUALITY
description: >
  Semantic model for data quality monitoring and root-cause analysis.
  Covers quality rules, execution results, table scores, and column health.

tables:
  - name: DQ_RULES
    base_table:
      database: INSURANCE_AI_HUB
      schema: DATA_QUALITY
      table: DQ_RULES
    description: Data quality rule definitions
    dimensions:
      - name: rule_id
        expr: RULE_ID
        unique: true
      - name: rule_name
        expr: RULE_NAME
      - name: target_table
        expr: TARGET_TABLE
      - name: target_column
        expr: TARGET_COLUMN
      - name: rule_type
        expr: RULE_TYPE
        description: Rule category (Completeness, Accuracy, Validity, Format, etc.)
      - name: severity
        expr: SEVERITY
    measures:
      - name: total_rules
        expr: COUNT(DISTINCT RULE_ID)
      - name: critical_rules
        expr: COUNT(CASE WHEN IS_CRITICAL THEN 1 END)

  - name: DQ_RESULTS
    base_table:
      database: INSURANCE_AI_HUB
      schema: DATA_QUALITY
      table: DQ_RESULTS
    dimensions:
      - name: result_id
        expr: RESULT_ID
        unique: true
      - name: execution_date
        expr: EXECUTION_DATE
      - name: status
        expr: STATUS
    measures:
      - name: avg_pass_rate
        expr: AVG(PASS_RATE)
      - name: total_failed_records
        expr: SUM(FAILED_RECORDS)
      - name: failed_rules_count
        expr: COUNT(CASE WHEN STATUS = 'FAIL' THEN 1 END)

  - name: DQ_SCORES
    base_table:
      database: INSURANCE_AI_HUB
      schema: DATA_QUALITY
      table: DQ_SCORES
    dimensions:
      - name: score_id
        expr: SCORE_ID
        unique: true
      - name: table_name
        expr: TABLE_NAME
      - name: score_date
        expr: SCORE_DATE
      - name: trend
        expr: TREND
    measures:
      - name: avg_overall_score
        expr: AVG(OVERALL_SCORE)
      - name: avg_completeness
        expr: AVG(COMPLETENESS_SCORE)
      - name: avg_accuracy
        expr: AVG(ACCURACY_SCORE)

  - name: DQ_COLUMN_HEALTH
    base_table:
      database: INSURANCE_AI_HUB
      schema: DATA_QUALITY
      table: DQ_COLUMN_HEALTH
    dimensions:
      - name: health_id
        expr: HEALTH_ID
        unique: true
      - name: table_name
        expr: TABLE_NAME
      - name: column_name
        expr: COLUMN_NAME
      - name: health_status
        expr: HEALTH_STATUS
    measures:
      - name: avg_null_pct
        expr: AVG(NULL_PCT)
      - name: total_outliers
        expr: SUM(OUTLIER_COUNT)
      - name: total_format_violations
        expr: SUM(FORMAT_VIOLATION_COUNT)

relationships:
  - left_table: DQ_RESULTS
    right_table: DQ_RULES
    join_type: left
    relationship_type: many_to_one
    on:
      - left_column: RULE_ID
        right_column: RULE_ID
```

### Step 2.3: Create Semantic Views in Snowflake

```sql
-- Create the Insurance Operations semantic view
CREATE OR REPLACE SEMANTIC VIEW INSURANCE_AI_HUB.ANALYTICS.SV_INSURANCE_OPS
  FROM @my_stage/sv_insurance_ops.yaml;

-- Create the Data Quality semantic view
CREATE OR REPLACE SEMANTIC VIEW INSURANCE_AI_HUB.DATA_QUALITY.SV_DATA_QUALITY
  FROM @my_stage/sv_data_quality.yaml;

-- Verify semantic views are created
SHOW SEMANTIC VIEWS IN SCHEMA INSURANCE_AI_HUB.ANALYTICS;
SHOW SEMANTIC VIEWS IN SCHEMA INSURANCE_AI_HUB.DATA_QUALITY;
```

---

## Phase 3: Cortex Search Implementation

### Step 3.1: Generate Embeddings for Document Chunks

```sql
-- If DOCUMENT_CHUNKS doesn't already have embeddings populated,
-- generate them using Cortex Embed
UPDATE INSURANCE_AI_HUB.DOCUMENTS.DOCUMENT_CHUNKS
SET EMBEDDING = SNOWFLAKE.CORTEX.EMBED_TEXT_768('snowflake-arctic-embed-m-v2.0', CHUNK_TEXT)
WHERE EMBEDDING IS NULL;

-- Verify embeddings
SELECT CHUNK_ID, SECTION_TITLE, TOKEN_COUNT,
       VECTOR_L2_DISTANCE(EMBEDDING, EMBEDDING) AS self_distance
FROM INSURANCE_AI_HUB.DOCUMENTS.DOCUMENT_CHUNKS
LIMIT 5;
```

### Step 3.2: Create Cortex Search Service

```sql
CREATE OR REPLACE CORTEX SEARCH SERVICE INSURANCE_AI_HUB.DOCUMENTS.CORTEX_SEARCH_SVC
  ON CHUNK_TEXT
  ATTRIBUTES SECTION_TITLE, DOCUMENT_ID
  WAREHOUSE = COMPUTE_WH
  TARGET_LAG = '1 hour'
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

-- Test the search service
SELECT SNOWFLAKE.CORTEX.SEARCH(
  'INSURANCE_AI_HUB.DOCUMENTS.CORTEX_SEARCH_SVC',
  'What does the health insurance policy cover?',
  { 'columns': ['CHUNK_TEXT', 'SECTION_TITLE', 'DOCUMENT_ID'], 'limit': 3 }
);
```

---

## Phase 4: Cortex Analyst Setup

### Step 4.1: Test Analyst with Semantic Views

```sql
-- Test Insurance Operations Analyst
SELECT SNOWFLAKE.CORTEX.ANALYST(
  'INSURANCE_AI_HUB.ANALYTICS.SV_INSURANCE_OPS',
  'What is the total premium revenue by policy type?'
);

-- Test Data Quality Analyst
SELECT SNOWFLAKE.CORTEX.ANALYST(
  'INSURANCE_AI_HUB.DATA_QUALITY.SV_DATA_QUALITY',
  'Which tables have the lowest data quality scores?'
);
```

### Step 4.2: Create Custom Tool Procedures

```sql
-- Claim Risk Score Tool
CREATE OR REPLACE PROCEDURE INSURANCE_AI_HUB.ANALYTICS.SP_CLAIM_RISK_SCORE(
    P_CLAIM_ID VARCHAR
)
RETURNS VARIANT
LANGUAGE SQL
AS
BEGIN
    LET result VARIANT;
    SELECT OBJECT_CONSTRUCT(
        'claim_id', c.CLAIM_ID,
        'claim_amount', c.CLAIM_AMOUNT,
        'fraud_score', c.FRAUD_SCORE,
        'fraud_flag', c.FRAUD_FLAG,
        'claim_type', c.CLAIM_TYPE,
        'claim_status', c.CLAIM_STATUS,
        'priority', c.PRIORITY,
        'days_to_resolve', c.DAYS_TO_RESOLVE,
        'friction_point', c.FRICTION_POINT,
        'policy_type', p.POLICY_TYPE,
        'policy_premium', p.PREMIUM_AMOUNT,
        'policy_loss_ratio', p.LOSS_RATIO,
        'customer_risk_tier', cu.RISK_TIER,
        'customer_credit_score', cu.CREDIT_SCORE,
        'risk_assessment', CASE
            WHEN c.FRAUD_SCORE > 0.8 THEN 'CRITICAL - Immediate investigation required'
            WHEN c.FRAUD_SCORE > 0.6 THEN 'HIGH - Prioritize for review'
            WHEN c.FRAUD_SCORE > 0.4 THEN 'MEDIUM - Standard review'
            ELSE 'LOW - Routine processing'
        END,
        'contributing_factors', ARRAY_CONSTRUCT(
            CASE WHEN c.FRAUD_SCORE > 0.7 THEN 'High fraud score' END,
            CASE WHEN c.CLAIM_AMOUNT > 50000 THEN 'Large claim amount' END,
            CASE WHEN cu.RISK_TIER IN ('High', 'Very High') THEN 'High-risk customer' END,
            CASE WHEN p.LOSS_RATIO > 0.8 THEN 'High loss ratio policy' END,
            CASE WHEN c.FRAUD_FLAG THEN 'Fraud flag active' END
        )
    ) INTO :result
    FROM INSURANCE_AI_HUB.ANALYTICS.CLAIMS c
    LEFT JOIN INSURANCE_AI_HUB.ANALYTICS.POLICIES p ON c.POLICY_ID = p.POLICY_ID
    LEFT JOIN INSURANCE_AI_HUB.ANALYTICS.CUSTOMERS cu ON c.CUSTOMER_ID = cu.CUSTOMER_ID
    WHERE c.CLAIM_ID = :P_CLAIM_ID;

    RETURN :result;
END;

-- DQ Root Cause Tool
CREATE OR REPLACE PROCEDURE INSURANCE_AI_HUB.DATA_QUALITY.SP_DQ_ROOT_CAUSE(
    P_TABLE_NAME VARCHAR,
    P_SCORE_DATE VARCHAR DEFAULT NULL
)
RETURNS VARIANT
LANGUAGE SQL
AS
BEGIN
    LET result VARIANT;
    LET target_date DATE := COALESCE(TRY_TO_DATE(:P_SCORE_DATE), (SELECT MAX(SCORE_DATE) FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_SCORES WHERE TABLE_NAME = :P_TABLE_NAME));

    SELECT OBJECT_CONSTRUCT(
        'table_name', :P_TABLE_NAME,
        'analysis_date', :target_date::VARCHAR,
        'overall_score', (SELECT OVERALL_SCORE FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_SCORES WHERE TABLE_NAME = :P_TABLE_NAME AND SCORE_DATE = :target_date),
        'score_trend', (SELECT TREND FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_SCORES WHERE TABLE_NAME = :P_TABLE_NAME AND SCORE_DATE = :target_date),
        'score_components', (SELECT OBJECT_CONSTRUCT('completeness', COMPLETENESS_SCORE, 'accuracy', ACCURACY_SCORE, 'consistency', CONSISTENCY_SCORE, 'timeliness', TIMELINESS_SCORE) FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_SCORES WHERE TABLE_NAME = :P_TABLE_NAME AND SCORE_DATE = :target_date),
        'failed_rules', (SELECT ARRAY_AGG(OBJECT_CONSTRUCT('rule_name', rl.RULE_NAME, 'rule_type', rl.RULE_TYPE, 'severity', rl.SEVERITY, 'target_column', r.TARGET_COLUMN, 'pass_rate', r.PASS_RATE, 'failed_records', r.FAILED_RECORDS, 'error_sample', r.ERROR_SAMPLE)) FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_RESULTS r JOIN INSURANCE_AI_HUB.DATA_QUALITY.DQ_RULES rl ON r.RULE_ID = rl.RULE_ID WHERE r.TARGET_TABLE = :P_TABLE_NAME AND r.STATUS = 'FAIL' AND DATE(r.EXECUTION_DATE) = :target_date),
        'unhealthy_columns', (SELECT ARRAY_AGG(OBJECT_CONSTRUCT('column_name', COLUMN_NAME, 'health_status', HEALTH_STATUS, 'null_pct', NULL_PCT, 'outlier_count', OUTLIER_COUNT, 'format_violations', FORMAT_VIOLATION_COUNT, 'score', SCORE)) FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_COLUMN_HEALTH WHERE TABLE_NAME = :P_TABLE_NAME AND CHECK_DATE = :target_date AND HEALTH_STATUS != 'Healthy')
    ) INTO :result;

    RETURN :result;
END;

-- Trend Detector Tool
CREATE OR REPLACE PROCEDURE INSURANCE_AI_HUB.ANALYTICS.SP_TREND_DETECTOR(
    P_METRIC_NAME VARCHAR,
    P_DIMENSION VARCHAR DEFAULT NULL,
    P_LOOKBACK_DAYS INT DEFAULT 90
)
RETURNS VARIANT
LANGUAGE SQL
AS
BEGIN
    LET result VARIANT;

    IF (:P_METRIC_NAME = 'claims_amount') THEN
        SELECT OBJECT_CONSTRUCT(
            'metric', 'claims_amount',
            'lookback_days', :P_LOOKBACK_DAYS,
            'dimension', COALESCE(:P_DIMENSION, 'overall'),
            'data_points', (
                SELECT ARRAY_AGG(OBJECT_CONSTRUCT(
                    'period', DATE_TRUNC('week', CLAIM_DATE)::VARCHAR,
                    'value', SUM(CLAIM_AMOUNT),
                    'count', COUNT(*)
                ))
                FROM INSURANCE_AI_HUB.ANALYTICS.CLAIMS
                WHERE CLAIM_DATE >= DATEADD(DAY, -:P_LOOKBACK_DAYS, CURRENT_DATE())
                GROUP BY DATE_TRUNC('week', CLAIM_DATE)
                ORDER BY 1
            )
        ) INTO :result;
    ELSEIF (:P_METRIC_NAME = 'dq_score') THEN
        SELECT OBJECT_CONSTRUCT(
            'metric', 'dq_score',
            'data_points', (
                SELECT ARRAY_AGG(OBJECT_CONSTRUCT(
                    'table_name', TABLE_NAME,
                    'score_date', SCORE_DATE::VARCHAR,
                    'overall_score', OVERALL_SCORE,
                    'trend', TREND
                ))
                FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_SCORES
                ORDER BY TABLE_NAME, SCORE_DATE
            )
        ) INTO :result;
    ELSE
        result := OBJECT_CONSTRUCT('error', 'Unsupported metric: ' || :P_METRIC_NAME);
    END IF;

    RETURN :result;
END;
```

---

## Phase 5: Cortex Agent Setup

### Step 5.1: Create the Cortex Agent

```sql
CREATE OR REPLACE CORTEX AGENT INSURANCE_AI_HUB.ANALYTICS.INSURANCE_INTELLIGENCE_AGENT
  MODEL = 'llama3.1-70b'
  TOOLS = (
    -- Cortex Analyst for structured analytics
    TOOL(
      TYPE = 'cortex_analyst_tool',
      NAME = 'insurance_operations_analyst',
      SEMANTIC_VIEW = 'INSURANCE_AI_HUB.ANALYTICS.SV_INSURANCE_OPS'
    ),
    -- Cortex Analyst for data quality
    TOOL(
      TYPE = 'cortex_analyst_tool',
      NAME = 'data_quality_analyst',
      SEMANTIC_VIEW = 'INSURANCE_AI_HUB.DATA_QUALITY.SV_DATA_QUALITY'
    ),
    -- Cortex Search for document Q&A
    TOOL(
      TYPE = 'cortex_search_tool',
      NAME = 'policy_document_search',
      CORTEX_SEARCH_SERVICE = 'INSURANCE_AI_HUB.DOCUMENTS.CORTEX_SEARCH_SVC',
      SEARCH_COLUMN = 'CHUNK_TEXT',
      COLUMNS = ['CHUNK_TEXT', 'SECTION_TITLE', 'DOCUMENT_ID']
    ),
    -- Custom SQL tools
    TOOL(
      TYPE = 'sql_tool',
      NAME = 'claim_risk_score',
      DESCRIPTION = 'Calculates governed risk score for a specific claim with contributing factors and recommended action.',
      SQL = 'CALL INSURANCE_AI_HUB.ANALYTICS.SP_CLAIM_RISK_SCORE(?)',
      PARAMETERS = [{'name': 'claim_id', 'type': 'string', 'description': 'The claim ID to assess'}]
    ),
    TOOL(
      TYPE = 'sql_tool',
      NAME = 'dq_root_cause',
      DESCRIPTION = 'Investigates root causes for data quality failures on a table. Returns failed rules, unhealthy columns, and error samples.',
      SQL = 'CALL INSURANCE_AI_HUB.DATA_QUALITY.SP_DQ_ROOT_CAUSE(?, ?)',
      PARAMETERS = [
        {'name': 'table_name', 'type': 'string', 'description': 'Table to investigate'},
        {'name': 'score_date', 'type': 'string', 'description': 'Date to investigate (optional)'}
      ]
    ),
    TOOL(
      TYPE = 'sql_tool',
      NAME = 'trend_detector',
      DESCRIPTION = 'Detects trends in claims, premiums, or data quality scores over configurable time windows.',
      SQL = 'CALL INSURANCE_AI_HUB.ANALYTICS.SP_TREND_DETECTOR(?, ?, ?)',
      PARAMETERS = [
        {'name': 'metric_name', 'type': 'string', 'description': 'Metric: claims_amount, premium, dq_score'},
        {'name': 'dimension', 'type': 'string', 'description': 'Segment dimension (optional)'},
        {'name': 'lookback_days', 'type': 'integer', 'description': 'Analysis window in days (default 90)'}
      ]
    )
  )
  INSTRUCTIONS = '
    You are the Insurance Intelligence Assistant. You help insurance professionals
    make data-driven decisions by combining structured analytics, document intelligence,
    and data quality insights.

    ROUTING: Use insurance_operations_analyst for KPIs, claims, policies, billing,
    risk questions. Use data_quality_analyst for DQ scores, rules, column health.
    Use policy_document_search for coverage, exclusions, procedures.
    Use claim_risk_score for specific claim investigation.
    Use dq_root_cause for quality failure investigation.
    Use trend_detector for trend analysis.

    RULES: Always cite sources. Show confidence. Flag data quality issues.
    Require human review for decisions over $50K impact.
    Never fabricate statistics not returned by tools.
  ';
```

### Step 5.2: Test the Agent

```sql
-- Test structured analytics
SELECT SNOWFLAKE.CORTEX.AGENT(
  'INSURANCE_AI_HUB.ANALYTICS.INSURANCE_INTELLIGENCE_AGENT',
  'What is the total premium revenue by policy type?'
);

-- Test document search
SELECT SNOWFLAKE.CORTEX.AGENT(
  'INSURANCE_AI_HUB.ANALYTICS.INSURANCE_INTELLIGENCE_AGENT',
  'What does the health insurance policy say about pre-existing conditions?'
);

-- Test data quality
SELECT SNOWFLAKE.CORTEX.AGENT(
  'INSURANCE_AI_HUB.ANALYTICS.INSURANCE_INTELLIGENCE_AGENT',
  'Why did the customers table quality score drop?'
);

-- Test cross-domain
SELECT SNOWFLAKE.CORTEX.AGENT(
  'INSURANCE_AI_HUB.ANALYTICS.INSURANCE_INTELLIGENCE_AGENT',
  'Show me high-risk claims in the Southeast and check if the underlying data is trustworthy'
);
```

---

## Phase 6: React Frontend Integration

### Step 6.1: Snowflake API Client Setup

```typescript
// services/snowflake-api.ts
const SNOWFLAKE_ACCOUNT_URL = process.env.REACT_APP_SNOWFLAKE_ACCOUNT_URL;

export async function executeSQL(sql: string, token: string): Promise<QueryResult> {
  const response = await fetch(`${SNOWFLAKE_ACCOUNT_URL}/api/v2/statements`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
      'X-Snowflake-Authorization-Token-Type': 'OAUTH',
    },
    body: JSON.stringify({
      statement: sql,
      warehouse: 'COMPUTE_WH',
      database: 'INSURANCE_AI_HUB',
      schema: 'ANALYTICS',
      role: 'INSURANCE_EXEC_ROLE',
    }),
  });
  return response.json();
}
```

### Step 6.2: Cortex Agent Streaming Client

```typescript
// services/cortex-agent.ts
export async function* streamAgentResponse(
  question: string,
  token: string
): AsyncGenerator<AgentStreamEvent> {
  const response = await fetch(
    `${SNOWFLAKE_ACCOUNT_URL}/api/v2/cortex/agent:run`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        agent: 'INSURANCE_AI_HUB.ANALYTICS.INSURANCE_INTELLIGENCE_AGENT',
        messages: [{ role: 'user', content: question }],
        stream: true,
      }),
    }
  );

  const reader = response.body!.getReader();
  const decoder = new TextDecoder();

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    const chunk = decoder.decode(value);
    // Parse SSE events
    for (const line of chunk.split('\n')) {
      if (line.startsWith('data: ')) {
        yield JSON.parse(line.slice(6));
      }
    }
  }
}
```

### Step 6.3: React Query Hook

```typescript
// hooks/useSnowflakeQuery.ts
import { useQuery } from '@tanstack/react-query';
import { executeSQL } from '../services/snowflake-api';
import { useAuth } from './useAuth';

export function useSnowflakeQuery(sql: string, options?: { enabled?: boolean }) {
  const { token } = useAuth();

  return useQuery({
    queryKey: ['snowflake', sql],
    queryFn: () => executeSQL(sql, token),
    enabled: options?.enabled !== false && !!token,
    staleTime: 5 * 60 * 1000, // 5 minutes
  });
}
```

---

## Phase 7: Testing

### Step 7.1: Data Validation Tests

```sql
-- Verify all tables have expected row counts
-- Verify referential integrity
-- Verify data quality patterns (intentional degradation in CUSTOMERS)
-- Verify document chunks have embeddings
-- Verify DQ scores show week-over-week trend
```

### Step 7.2: Semantic View Validation

```sql
-- Test each verified query in the semantic view
-- Verify Cortex Analyst generates correct SQL for benchmark questions
-- Test edge cases: empty results, ambiguous questions, multi-table joins
```

### Step 7.3: Agent Benchmark Suite

Run the 115-question benchmark set covering:
- 50 structured analytics questions
- 30 document Q&A questions
- 20 DQ root-cause scenarios
- 15 cross-domain questions

Measure: SQL correctness, retrieval recall, routing accuracy, citation coverage, response time.

---

## Phase 8: Production Deployment

### Step 8.1: RBAC Setup

```sql
-- Create database roles
CREATE DATABASE ROLE IF NOT EXISTS INSURANCE_AI_HUB.INSURANCE_ADMIN_ROLE;
CREATE DATABASE ROLE IF NOT EXISTS INSURANCE_AI_HUB.INSURANCE_EXEC_ROLE;
CREATE DATABASE ROLE IF NOT EXISTS INSURANCE_AI_HUB.INSURANCE_CLAIMS_ROLE;
CREATE DATABASE ROLE IF NOT EXISTS INSURANCE_AI_HUB.INSURANCE_UW_ROLE;
CREATE DATABASE ROLE IF NOT EXISTS INSURANCE_AI_HUB.INSURANCE_DATA_STEWARD_ROLE;
CREATE DATABASE ROLE IF NOT EXISTS INSURANCE_AI_HUB.INSURANCE_ANALYST_ROLE;

-- Grant schema access
GRANT USAGE ON SCHEMA INSURANCE_AI_HUB.ANALYTICS TO DATABASE ROLE INSURANCE_ANALYST_ROLE;
GRANT SELECT ON ALL TABLES IN SCHEMA INSURANCE_AI_HUB.ANALYTICS TO DATABASE ROLE INSURANCE_ANALYST_ROLE;
GRANT SELECT ON ALL VIEWS IN SCHEMA INSURANCE_AI_HUB.ANALYTICS TO DATABASE ROLE INSURANCE_ANALYST_ROLE;

-- DQ schema access for data stewards
GRANT USAGE ON SCHEMA INSURANCE_AI_HUB.DATA_QUALITY TO DATABASE ROLE INSURANCE_DATA_STEWARD_ROLE;
GRANT SELECT ON ALL TABLES IN SCHEMA INSURANCE_AI_HUB.DATA_QUALITY TO DATABASE ROLE INSURANCE_DATA_STEWARD_ROLE;

-- Documents schema (restricted)
GRANT USAGE ON SCHEMA INSURANCE_AI_HUB.DOCUMENTS TO DATABASE ROLE INSURANCE_CLAIMS_ROLE;
GRANT SELECT ON ALL TABLES IN SCHEMA INSURANCE_AI_HUB.DOCUMENTS TO DATABASE ROLE INSURANCE_CLAIMS_ROLE;

-- Role hierarchy
GRANT DATABASE ROLE INSURANCE_ANALYST_ROLE TO DATABASE ROLE INSURANCE_EXEC_ROLE;
GRANT DATABASE ROLE INSURANCE_ANALYST_ROLE TO DATABASE ROLE INSURANCE_CLAIMS_ROLE;
GRANT DATABASE ROLE INSURANCE_ANALYST_ROLE TO DATABASE ROLE INSURANCE_UW_ROLE;
GRANT DATABASE ROLE INSURANCE_EXEC_ROLE TO DATABASE ROLE INSURANCE_ADMIN_ROLE;
GRANT DATABASE ROLE INSURANCE_CLAIMS_ROLE TO DATABASE ROLE INSURANCE_ADMIN_ROLE;
GRANT DATABASE ROLE INSURANCE_UW_ROLE TO DATABASE ROLE INSURANCE_ADMIN_ROLE;
GRANT DATABASE ROLE INSURANCE_DATA_STEWARD_ROLE TO DATABASE ROLE INSURANCE_ADMIN_ROLE;
```

### Step 8.2: Masking Policies

```sql
-- PII masking for customer data
CREATE OR REPLACE MASKING POLICY INSURANCE_AI_HUB.ANALYTICS.MASK_EMAIL AS
  (val VARCHAR) RETURNS VARCHAR ->
  CASE
    WHEN CURRENT_ROLE() IN ('INSURANCE_ADMIN_ROLE') THEN val
    ELSE REGEXP_REPLACE(val, '(^[^@]{2})[^@]*(@.*)', '\\1***\\2')
  END;

ALTER TABLE INSURANCE_AI_HUB.ANALYTICS.CUSTOMERS
  MODIFY COLUMN EMAIL SET MASKING POLICY INSURANCE_AI_HUB.ANALYTICS.MASK_EMAIL;

CREATE OR REPLACE MASKING POLICY INSURANCE_AI_HUB.ANALYTICS.MASK_PHONE AS
  (val VARCHAR) RETURNS VARCHAR ->
  CASE
    WHEN CURRENT_ROLE() IN ('INSURANCE_ADMIN_ROLE') THEN val
    ELSE REGEXP_REPLACE(val, '(\\d{3})-\\d{4}', '\\1-****')
  END;

ALTER TABLE INSURANCE_AI_HUB.ANALYTICS.CUSTOMERS
  MODIFY COLUMN PHONE SET MASKING POLICY INSURANCE_AI_HUB.ANALYTICS.MASK_PHONE;
```

### Step 8.3: Object Tags

```sql
-- Create tag for data classification
CREATE TAG IF NOT EXISTS INSURANCE_AI_HUB.ANALYTICS.PII_LEVEL
  ALLOWED_VALUES 'HIGH', 'MEDIUM', 'LOW', 'NONE';

CREATE TAG IF NOT EXISTS INSURANCE_AI_HUB.ANALYTICS.BUSINESS_DOMAIN
  ALLOWED_VALUES 'CUSTOMER', 'POLICY', 'CLAIMS', 'BILLING', 'RISK', 'DOCUMENTS', 'DATA_QUALITY';

-- Apply tags
ALTER TABLE INSURANCE_AI_HUB.ANALYTICS.CUSTOMERS
  MODIFY COLUMN EMAIL SET TAG INSURANCE_AI_HUB.ANALYTICS.PII_LEVEL = 'HIGH';
ALTER TABLE INSURANCE_AI_HUB.ANALYTICS.CUSTOMERS
  MODIFY COLUMN PHONE SET TAG INSURANCE_AI_HUB.ANALYTICS.PII_LEVEL = 'HIGH';
ALTER TABLE INSURANCE_AI_HUB.ANALYTICS.CUSTOMERS
  MODIFY COLUMN ADDRESS SET TAG INSURANCE_AI_HUB.ANALYTICS.PII_LEVEL = 'HIGH';
ALTER TABLE INSURANCE_AI_HUB.ANALYTICS.CUSTOMERS
  MODIFY COLUMN DATE_OF_BIRTH SET TAG INSURANCE_AI_HUB.ANALYTICS.PII_LEVEL = 'MEDIUM';

ALTER TABLE INSURANCE_AI_HUB.ANALYTICS.CLAIMS
  SET TAG INSURANCE_AI_HUB.ANALYTICS.BUSINESS_DOMAIN = 'CLAIMS';
ALTER TABLE INSURANCE_AI_HUB.ANALYTICS.POLICIES
  SET TAG INSURANCE_AI_HUB.ANALYTICS.BUSINESS_DOMAIN = 'POLICY';
```

---

## Best Practices

1. **Semantic Views**: Add verified queries (VQRs) for the most common questions to improve Analyst accuracy
2. **Cortex Search**: Use metadata filters (SECTION_TITLE, DOCUMENT_ID) to narrow retrieval scope
3. **Agent Instructions**: Be specific about routing rules — the more explicit, the better routing accuracy
4. **Custom Tools**: Use deterministic SQL procedures for numeric calculations; never let the LLM compute numbers
5. **Governance**: Apply masking policies before granting agent access to ensure PII is never exposed in responses
6. **Monitoring**: Log every agent interaction to the audit table for observability and evaluation
7. **Evaluation**: Run the benchmark suite after every semantic view or agent configuration change
8. **Cost Control**: Monitor token usage per query and set credit budgets per role

---

*This guide provides the complete step-by-step implementation instructions for building the Insurance Intelligence Platform on Snowflake, from data preparation through production deployment.*
