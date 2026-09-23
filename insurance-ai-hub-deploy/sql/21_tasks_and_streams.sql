-- ============================================================================
-- INSURANCE AI HUB - Production Readiness
-- Script 21: Automated Tasks, Streams, and Monitoring Alerts
-- ============================================================================
-- Run as: ACCOUNTADMIN
-- Depends on: 02_tables.sql, 06_cortex_search.sql, 08_rbac.sql
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE INSURANCE_AI_HUB;
USE WAREHOUSE COMPUTE_WH;

-- ############################################################################
-- SECTION 1: STREAMS (Change Data Capture)
-- Track inserts/updates on key tables so tasks only process new data.
-- ############################################################################

-- Stream on CLAIMS for incremental fraud scoring
CREATE STREAM IF NOT EXISTS ANALYTICS.CLAIMS_STREAM
  ON TABLE ANALYTICS.CLAIMS
  APPEND_ONLY = TRUE
  COMMENT = 'CDC stream for new claims — triggers fraud scoring task';

-- Stream on DOCUMENT_CHUNKS for Cortex Search refresh awareness
CREATE STREAM IF NOT EXISTS DOCUMENTS.DOCUMENT_CHUNKS_STREAM
  ON TABLE DOCUMENTS.DOCUMENT_CHUNKS
  APPEND_ONLY = TRUE
  COMMENT = 'CDC stream for new document chunks — tracks search index freshness';

-- Stream on DQ_RESULTS for alerting on new failures
CREATE STREAM IF NOT EXISTS DATA_QUALITY.DQ_RESULTS_STREAM
  ON TABLE DATA_QUALITY.DQ_RESULTS
  APPEND_ONLY = TRUE
  COMMENT = 'CDC stream for new DQ results — triggers failure alerting';


-- ############################################################################
-- SECTION 2: SCHEDULED TASK — Daily DQ Score Refresh
-- Recalculates data quality scores for all monitored tables.
-- Runs daily at 6 AM UTC on the serverless task engine (no warehouse needed
-- when using WAREHOUSE = COMPUTE_WH with auto-suspend).
-- ############################################################################

CREATE OR REPLACE TASK ANALYTICS.TASK_DQ_DAILY_SCORE_REFRESH
  WAREHOUSE = COMPUTE_WH
  SCHEDULE = 'USING CRON 0 6 * * * UTC'
  COMMENT = 'Daily DQ score refresh — recalculates quality metrics for all tables'
AS
  INSERT INTO INSURANCE_AI_HUB.DATA_QUALITY.DQ_SCORES
    (SCORE_ID, TABLE_NAME, SCHEMA_NAME, SCORE_DATE, OVERALL_SCORE,
     COMPLETENESS_SCORE, ACCURACY_SCORE, CONSISTENCY_SCORE, TIMELINESS_SCORE,
     RULES_PASSED, RULES_FAILED, TOTAL_RULES, TREND)
  SELECT
    'DQS-AUTO-' || TO_CHAR(CURRENT_DATE(), 'YYYYMMDD') || '-' || ROW_NUMBER() OVER (ORDER BY r.TARGET_TABLE),
    r.TARGET_TABLE,
    'ANALYTICS',
    CURRENT_DATE(),
    -- Overall score = pass rate across all rules for this table
    ROUND(AVG(r.PASS_RATE) * 100, 1),
    -- Component scores (simplified: use pass rate of rules by type)
    ROUND(AVG(CASE WHEN rl.RULE_TYPE = 'completeness' THEN r.PASS_RATE END) * 100, 1),
    ROUND(AVG(CASE WHEN rl.RULE_TYPE = 'accuracy' THEN r.PASS_RATE END) * 100, 1),
    ROUND(AVG(CASE WHEN rl.RULE_TYPE = 'consistency' THEN r.PASS_RATE END) * 100, 1),
    ROUND(AVG(CASE WHEN rl.RULE_TYPE = 'timeliness' THEN r.PASS_RATE END) * 100, 1),
    SUM(CASE WHEN r.STATUS = 'PASS' THEN 1 ELSE 0 END),
    SUM(CASE WHEN r.STATUS = 'FAIL' THEN 1 ELSE 0 END),
    COUNT(*),
    CASE
      WHEN AVG(r.PASS_RATE) >= LAG(AVG(r.PASS_RATE)) OVER (PARTITION BY r.TARGET_TABLE ORDER BY NULL)
        THEN 'Improving'
      ELSE 'Declining'
    END
  FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_RESULTS r
  JOIN INSURANCE_AI_HUB.DATA_QUALITY.DQ_RULES rl ON r.RULE_ID = rl.RULE_ID
  WHERE r.EXECUTION_DATE >= DATEADD(DAY, -1, CURRENT_TIMESTAMP())
  GROUP BY r.TARGET_TABLE;


-- ############################################################################
-- SECTION 3: TRIGGERED TASK — Log New Claims with High Fraud Score
-- Fires when CLAIMS_STREAM has data, writes high-risk claims to audit log.
-- ############################################################################

CREATE OR REPLACE TASK ANALYTICS.TASK_FLAG_HIGH_FRAUD_CLAIMS
  WAREHOUSE = COMPUTE_WH
  COMMENT = 'Triggered task: logs new claims with fraud_score > 0.7 to audit log'
  WHEN SYSTEM$STREAM_HAS_DATA('INSURANCE_AI_HUB.ANALYTICS.CLAIMS_STREAM')
AS
  INSERT INTO INSURANCE_AI_HUB.ANALYTICS.AGENT_AUDIT_LOG
    (SESSION_ID, USER_NAME, USER_ROLE, QUESTION, DETECTED_INTENT,
     AGENT_SELECTED, RESPONSE_TEXT, CONFIDENCE_SCORE, HUMAN_ESCALATION)
  SELECT
    UUID_STRING(),
    'SYSTEM_TASK',
    'INSURANCE_SERVICE_ROLE',
    'Auto-flagged high fraud score claim: ' || CLAIM_ID,
    'FRAUD_ALERT',
    'TASK_FLAG_HIGH_FRAUD_CLAIMS',
    'Claim ' || CLAIM_ID || ' (amount: $' || CLAIM_AMOUNT::VARCHAR ||
      ', fraud_score: ' || ROUND(FRAUD_SCORE, 2)::VARCHAR ||
      ') auto-flagged for investigation.',
    FRAUD_SCORE,
    TRUE
  FROM INSURANCE_AI_HUB.ANALYTICS.CLAIMS_STREAM
  WHERE FRAUD_SCORE > 0.7;


-- ############################################################################
-- SECTION 4: TRIGGERED TASK — Alert on DQ Failures
-- Fires when DQ_RESULTS_STREAM has new FAIL records for critical rules.
-- ############################################################################

CREATE OR REPLACE TASK DATA_QUALITY.TASK_DQ_FAILURE_ALERT
  WAREHOUSE = COMPUTE_WH
  COMMENT = 'Triggered task: logs critical DQ failures to audit log for review'
  WHEN SYSTEM$STREAM_HAS_DATA('INSURANCE_AI_HUB.DATA_QUALITY.DQ_RESULTS_STREAM')
AS
  INSERT INTO INSURANCE_AI_HUB.ANALYTICS.AGENT_AUDIT_LOG
    (SESSION_ID, USER_NAME, USER_ROLE, QUESTION, DETECTED_INTENT,
     AGENT_SELECTED, RESPONSE_TEXT, CONFIDENCE_SCORE, HUMAN_ESCALATION)
  SELECT
    UUID_STRING(),
    'SYSTEM_TASK',
    'INSURANCE_SERVICE_ROLE',
    'DQ failure on ' || r.TARGET_TABLE || '.' || r.TARGET_COLUMN || ' — rule: ' || rl.RULE_NAME,
    'DQ_ALERT',
    'TASK_DQ_FAILURE_ALERT',
    'Rule "' || rl.RULE_NAME || '" (' || rl.SEVERITY || ') failed on ' ||
      r.TARGET_TABLE || '.' || r.TARGET_COLUMN ||
      '. Pass rate: ' || ROUND(r.PASS_RATE * 100, 1)::VARCHAR || '%. ' ||
      'Failed records: ' || r.FAILED_RECORDS::VARCHAR,
    r.PASS_RATE,
    CASE WHEN rl.IS_CRITICAL THEN TRUE ELSE FALSE END
  FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_RESULTS_STREAM r
  JOIN INSURANCE_AI_HUB.DATA_QUALITY.DQ_RULES rl ON r.RULE_ID = rl.RULE_ID
  WHERE r.STATUS = 'FAIL';


-- ############################################################################
-- SECTION 5: SNOWFLAKE ALERT — DQ Score Drop Monitor
-- Checks every 12 hours if any table's DQ score dropped below 70%.
-- Sends notification via the alert mechanism.
-- ############################################################################

CREATE OR REPLACE ALERT DATA_QUALITY.ALERT_DQ_SCORE_DROP
  WAREHOUSE = COMPUTE_WH
  SCHEDULE = 'USING CRON 0 */12 * * * UTC'
  COMMENT = 'Alert when any table DQ score drops below 70%'
  IF (EXISTS (
    SELECT 1
    FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_SCORES
    WHERE SCORE_DATE = CURRENT_DATE()
      AND OVERALL_SCORE < 70
  ))
  THEN
    INSERT INTO INSURANCE_AI_HUB.ANALYTICS.AGENT_AUDIT_LOG
      (SESSION_ID, USER_NAME, USER_ROLE, QUESTION, DETECTED_INTENT,
       AGENT_SELECTED, RESPONSE_TEXT, HUMAN_ESCALATION)
    SELECT
      UUID_STRING(),
      'SYSTEM_ALERT',
      'INSURANCE_SERVICE_ROLE',
      'ALERT: DQ score below 70% for ' || TABLE_NAME,
      'DQ_SCORE_ALERT',
      'ALERT_DQ_SCORE_DROP',
      'Table ' || TABLE_NAME || ' has overall DQ score of ' ||
        OVERALL_SCORE::VARCHAR || '% (threshold: 70%). Trend: ' || TREND,
      TRUE
    FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_SCORES
    WHERE SCORE_DATE = CURRENT_DATE()
      AND OVERALL_SCORE < 70;


-- ############################################################################
-- SECTION 6: TASK DEPENDENCIES (DAG)
-- DQ score refresh runs first; failure alert can fire independently.
-- ############################################################################

-- Make DQ failure alert a child of DQ score refresh (runs after refresh completes)
ALTER TASK DATA_QUALITY.TASK_DQ_FAILURE_ALERT ADD AFTER ANALYTICS.TASK_DQ_DAILY_SCORE_REFRESH;


-- ############################################################################
-- SECTION 7: RESUME TASKS AND ALERTS
-- Tasks and alerts are created in SUSPENDED state — must be resumed to run.
-- ############################################################################

-- Resume in reverse dependency order (children first, then parents)
ALTER TASK DATA_QUALITY.TASK_DQ_FAILURE_ALERT RESUME;
ALTER TASK ANALYTICS.TASK_FLAG_HIGH_FRAUD_CLAIMS RESUME;
ALTER TASK ANALYTICS.TASK_DQ_DAILY_SCORE_REFRESH RESUME;
ALTER ALERT DATA_QUALITY.ALERT_DQ_SCORE_DROP RESUME;


-- ############################################################################
-- Verification
-- ############################################################################

SHOW STREAMS IN DATABASE INSURANCE_AI_HUB;
SHOW TASKS IN DATABASE INSURANCE_AI_HUB;
SHOW ALERTS IN DATABASE INSURANCE_AI_HUB;

-- ============================================================================
-- END OF 21_tasks_and_streams.sql
-- ============================================================================
