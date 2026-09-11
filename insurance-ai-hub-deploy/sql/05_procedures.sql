-- ============================================================================
-- INSURANCE AI HUB - Production Deployment
-- Script 05: Stored Procedures
-- ============================================================================
-- Run as: ACCOUNTADMIN
-- Depends on: 02_tables.sql
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE INSURANCE_AI_HUB;

-- ############################################################################
-- SP 1: Claim Risk Score (JavaScript)
-- ############################################################################

CREATE OR REPLACE PROCEDURE ANALYTICS.SP_CLAIM_RISK_SCORE(P_CLAIM_ID VARCHAR)
RETURNS VARIANT
LANGUAGE JAVASCRIPT
EXECUTE AS CALLER
AS '
  var sql = `SELECT OBJECT_CONSTRUCT(
    ''claim_id'', c.CLAIM_ID,
    ''claim_amount'', c.CLAIM_AMOUNT,
    ''fraud_score'', c.FRAUD_SCORE,
    ''fraud_flag'', c.FRAUD_FLAG,
    ''claim_type'', c.CLAIM_TYPE,
    ''claim_status'', c.CLAIM_STATUS,
    ''priority'', c.PRIORITY,
    ''days_to_resolve'', c.DAYS_TO_RESOLVE,
    ''friction_point'', c.FRICTION_POINT,
    ''policy_type'', p.POLICY_TYPE,
    ''policy_premium'', p.PREMIUM_AMOUNT,
    ''policy_loss_ratio'', p.LOSS_RATIO,
    ''customer_risk_tier'', cu.RISK_TIER,
    ''customer_credit_score'', cu.CREDIT_SCORE,
    ''risk_assessment'', CASE
      WHEN c.FRAUD_SCORE > 0.8 THEN ''CRITICAL - Immediate investigation required''
      WHEN c.FRAUD_SCORE > 0.6 THEN ''HIGH - Prioritize for review''
      WHEN c.FRAUD_SCORE > 0.4 THEN ''MEDIUM - Standard review''
      ELSE ''LOW - Routine processing''
    END,
    ''contributing_factors'', ARRAY_CONSTRUCT_COMPACT(
      CASE WHEN c.FRAUD_SCORE > 0.7 THEN ''High fraud score'' END,
      CASE WHEN c.CLAIM_AMOUNT > 50000 THEN ''Large claim amount'' END,
      CASE WHEN cu.RISK_TIER IN (''High'', ''Very High'') THEN ''High-risk customer'' END,
      CASE WHEN p.LOSS_RATIO > 0.8 THEN ''High loss ratio policy'' END,
      CASE WHEN c.FRAUD_FLAG THEN ''Fraud flag active'' END
    )
  ) AS result
  FROM INSURANCE_AI_HUB.ANALYTICS.CLAIMS c
  LEFT JOIN INSURANCE_AI_HUB.ANALYTICS.POLICIES p ON c.POLICY_ID = p.POLICY_ID
  LEFT JOIN INSURANCE_AI_HUB.ANALYTICS.CUSTOMERS cu ON c.CUSTOMER_ID = cu.CUSTOMER_ID
  WHERE c.CLAIM_ID = ?`;
  var stmt = snowflake.createStatement({sqlText: sql, binds: [P_CLAIM_ID]});
  var rs = stmt.execute();
  if (rs.next()) { return rs.getColumnValue(1); }
  return {"error": "Claim not found: " + P_CLAIM_ID};
';


-- ############################################################################
-- SP 2: Trend Detector (JavaScript)
-- ############################################################################

CREATE OR REPLACE PROCEDURE ANALYTICS.SP_TREND_DETECTOR(
    P_METRIC_NAME VARCHAR,
    P_DIMENSION VARCHAR DEFAULT NULL,
    P_LOOKBACK_DAYS FLOAT DEFAULT 90
)
RETURNS VARIANT
LANGUAGE JAVASCRIPT
EXECUTE AS CALLER
AS '
  if (P_METRIC_NAME === ''claims_amount'') {
    var sql = `SELECT OBJECT_CONSTRUCT(''metric'',''claims_amount'',''lookback_days'',` + P_LOOKBACK_DAYS + `,''dimension'',COALESCE(''` + (P_DIMENSION || ''overall'') + `'',''overall''),''data_points'',(SELECT ARRAY_AGG(OBJECT_CONSTRUCT(''period'',grp_period::VARCHAR,''value'',grp_value,''count'',grp_count)) FROM (SELECT DATE_TRUNC(''week'',CLAIM_DATE) AS grp_period, SUM(CLAIM_AMOUNT) AS grp_value, COUNT(*) AS grp_count FROM INSURANCE_AI_HUB.ANALYTICS.CLAIMS WHERE CLAIM_DATE >= DATEADD(DAY,-` + P_LOOKBACK_DAYS + `,CURRENT_DATE()) GROUP BY 1 ORDER BY 1))) AS result`;
    var rs = snowflake.execute({sqlText: sql});
    if (rs.next()) return rs.getColumnValue(1);
  } else if (P_METRIC_NAME === ''dq_score'') {
    var sql = `SELECT OBJECT_CONSTRUCT(''metric'',''dq_score'',''data_points'',(SELECT ARRAY_AGG(OBJECT_CONSTRUCT(''table_name'',TABLE_NAME,''score_date'',SCORE_DATE::VARCHAR,''overall_score'',OVERALL_SCORE,''trend'',TREND)) FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_SCORES ORDER BY TABLE_NAME, SCORE_DATE)) AS result`;
    var rs = snowflake.execute({sqlText: sql});
    if (rs.next()) return rs.getColumnValue(1);
  } else if (P_METRIC_NAME === ''premium'') {
    var sql = `SELECT OBJECT_CONSTRUCT(''metric'',''premium'',''data_points'',(SELECT ARRAY_AGG(OBJECT_CONSTRUCT(''policy_type'',POLICY_TYPE,''total_premium'',grp_premium,''policy_count'',grp_count)) FROM (SELECT POLICY_TYPE, SUM(PREMIUM_AMOUNT) AS grp_premium, COUNT(*) AS grp_count FROM INSURANCE_AI_HUB.ANALYTICS.POLICIES WHERE POLICY_STATUS=''Active'' GROUP BY 1))) AS result`;
    var rs = snowflake.execute({sqlText: sql});
    if (rs.next()) return rs.getColumnValue(1);
  }
  return {"error": "Unsupported metric: " + P_METRIC_NAME, "supported_metrics": ["claims_amount","premium","dq_score"]};
';


-- ############################################################################
-- SP 3: DQ Root Cause Analysis (SQL)
-- ############################################################################

CREATE OR REPLACE PROCEDURE DATA_QUALITY.SP_DQ_ROOT_CAUSE(
    P_TABLE_NAME VARCHAR,
    P_SCORE_DATE VARCHAR DEFAULT NULL
)
RETURNS VARIANT
LANGUAGE SQL
EXECUTE AS OWNER
AS 'BEGIN
    LET target_date DATE;
    IF (:P_SCORE_DATE IS NOT NULL) THEN
        target_date := TRY_TO_DATE(:P_SCORE_DATE);
    END IF;
    IF (:target_date IS NULL) THEN
        SELECT MAX(SCORE_DATE) INTO :target_date FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_SCORES WHERE TABLE_NAME = :P_TABLE_NAME;
    END IF;

    LET result VARIANT;
    SELECT OBJECT_CONSTRUCT(
        ''table_name'', :P_TABLE_NAME,
        ''analysis_date'', :target_date::VARCHAR,
        ''overall_score'', s.OVERALL_SCORE,
        ''score_trend'', s.TREND,
        ''score_components'', OBJECT_CONSTRUCT(
            ''completeness'', s.COMPLETENESS_SCORE,
            ''accuracy'', s.ACCURACY_SCORE,
            ''consistency'', s.CONSISTENCY_SCORE,
            ''timeliness'', s.TIMELINESS_SCORE
        ),
        ''rules_passed'', s.RULES_PASSED,
        ''rules_failed'', s.RULES_FAILED,
        ''total_rules'', s.TOTAL_RULES
    ) INTO :result
    FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_SCORES s
    WHERE s.TABLE_NAME = :P_TABLE_NAME AND s.SCORE_DATE = :target_date;

    LET failed_rules VARIANT;
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(
        ''rule_name'', rl.RULE_NAME,
        ''rule_type'', rl.RULE_TYPE,
        ''severity'', rl.SEVERITY,
        ''target_column'', r.TARGET_COLUMN,
        ''pass_rate'', r.PASS_RATE,
        ''failed_records'', r.FAILED_RECORDS,
        ''error_sample'', r.ERROR_SAMPLE
    )) INTO :failed_rules
    FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_RESULTS r
    JOIN INSURANCE_AI_HUB.DATA_QUALITY.DQ_RULES rl ON r.RULE_ID = rl.RULE_ID
    WHERE r.TARGET_TABLE = :P_TABLE_NAME AND r.STATUS = ''FAIL'' AND DATE(r.EXECUTION_DATE) = :target_date;

    LET unhealthy_cols VARIANT;
    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(
        ''column_name'', COLUMN_NAME,
        ''health_status'', HEALTH_STATUS,
        ''null_pct'', NULL_PCT,
        ''outlier_count'', OUTLIER_COUNT,
        ''format_violations'', FORMAT_VIOLATION_COUNT,
        ''score'', SCORE
    )) INTO :unhealthy_cols
    FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_COLUMN_HEALTH
    WHERE TABLE_NAME = :P_TABLE_NAME AND CHECK_DATE = :target_date AND HEALTH_STATUS != ''Healthy'';

    result := OBJECT_INSERT(OBJECT_INSERT(:result, ''failed_rules'', :failed_rules), ''unhealthy_columns'', :unhealthy_cols);
    RETURN :result;
END';

-- ============================================================================
-- END OF 05_procedures.sql
-- ============================================================================
