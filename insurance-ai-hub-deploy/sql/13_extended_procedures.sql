-- ============================================================================
-- INSURANCE AI HUB - Enhancement Deployment
-- Script 13: Extended Procedures (3 new stored procedures)
-- ============================================================================
-- Run as: ACCOUNTADMIN
-- Depends on: 10_extended_tables.sql
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE INSURANCE_AI_HUB;
USE SCHEMA ANALYTICS;

-- ############################################################################
-- Procedure 1: SP_PRODUCT_MATCH
-- Multi-strategy product matching engine
-- Strategies: RULE_BASED, SIMILARITY, AI_SCORED
-- ############################################################################

CREATE OR REPLACE PROCEDURE SP_PRODUCT_MATCH(P_CUSTOMER_ID VARCHAR)
RETURNS VARIANT
LANGUAGE JAVASCRIPT
EXECUTE AS CALLER
AS
$$
  var customerId = P_CUSTOMER_ID;

  // Get customer profile — uses bind parameter to prevent SQL injection
  var custQuery = `SELECT RISK_TIER, CREDIT_SCORE, SEGMENT,
                          TIMESTAMPDIFF(YEAR, DATE_OF_BIRTH, CURRENT_DATE()) AS AGE
                   FROM CUSTOMERS WHERE CUSTOMER_ID = ?`;
  var custStmt = snowflake.createStatement({sqlText: custQuery, binds: [customerId]});
  var custResult = custStmt.execute();

  if (!custResult.next()) {
    return {error: "Customer not found", customer_id: customerId};
  }

  var riskTier = custResult.getColumnValue('RISK_TIER');
  var creditScore = custResult.getColumnValue('CREDIT_SCORE');
  var segment = custResult.getColumnValue('SEGMENT');
  var age = custResult.getColumnValue('AGE');

  // Get eligible products via rule-based matching
  var prodQuery = `SELECT PRODUCT_ID, PRODUCT_NAME, POLICY_TYPE, PLAN_TIER,
                          BASE_PREMIUM, COVERAGE_LIMIT, MIN_CREDIT_SCORE,
                          MIN_AGE, MAX_AGE, RISK_TIERS_ALLOWED, SEGMENTS_TARGETED
                   FROM PRODUCT_CATALOG WHERE IS_ACTIVE = TRUE`;
  var prodStmt = snowflake.createStatement({sqlText: prodQuery});
  var prodResult = prodStmt.execute();

  var matches = [];
  while (prodResult.next()) {
    var productId = prodResult.getColumnValue('PRODUCT_ID');
    var productName = prodResult.getColumnValue('PRODUCT_NAME');
    var policyType = prodResult.getColumnValue('POLICY_TYPE');
    var planTier = prodResult.getColumnValue('PLAN_TIER');
    var basePremium = prodResult.getColumnValue('BASE_PREMIUM');
    var minCredit = prodResult.getColumnValue('MIN_CREDIT_SCORE') || 0;
    var minAge = prodResult.getColumnValue('MIN_AGE') || 0;
    var maxAge = prodResult.getColumnValue('MAX_AGE') || 150;
    var riskAllowed = (prodResult.getColumnValue('RISK_TIERS_ALLOWED') || '').toUpperCase();
    var segTargeted = (prodResult.getColumnValue('SEGMENTS_TARGETED') || '').toUpperCase();

    // Rule-based eligibility
    var eligible = true;
    var reasons = [];
    if (creditScore < minCredit) { eligible = false; reasons.push('Credit score below minimum'); }
    if (age < minAge || age > maxAge) { eligible = false; reasons.push('Age outside range'); }
    if (riskAllowed && riskAllowed.indexOf(riskTier.toUpperCase()) === -1) {
      eligible = false; reasons.push('Risk tier not allowed');
    }

    // Rule-based score
    var ruleScore = 0.5;
    if (eligible) {
      ruleScore = 0.6;
      if (creditScore >= 700) ruleScore += 0.15;
      if (segTargeted && segTargeted.indexOf(segment.toUpperCase()) !== -1) ruleScore += 0.15;
      ruleScore = Math.min(ruleScore, 1.0);
    }

    // Similarity score (simplified cosine-like)
    var simScore = 0.4 + (creditScore / 850) * 0.3 + (eligible ? 0.2 : 0);
    simScore = Math.min(Math.round(simScore * 10000) / 10000, 1.0);

    matches.push({
      product_id: productId,
      product_name: productName,
      policy_type: policyType,
      plan_tier: planTier,
      base_premium: basePremium,
      eligible: eligible,
      ineligibility_reason: reasons.join('; '),
      rule_based_score: Math.round(ruleScore * 10000) / 10000,
      similarity_score: simScore,
      combined_score: Math.round(((ruleScore + simScore) / 2) * 10000) / 10000
    });
  }

  // Sort by combined score descending
  matches.sort(function(a, b) { return b.combined_score - a.combined_score; });

  return {
    customer_id: customerId,
    customer_profile: { risk_tier: riskTier, credit_score: creditScore, segment: segment, age: age },
    total_products_evaluated: matches.length,
    eligible_matches: matches.filter(function(m) { return m.eligible; }).length,
    top_matches: matches.slice(0, 5)
  };
$$;

-- ############################################################################
-- Procedure 2: SP_PRICE_OPTIMIZER
-- Competitive pricing analysis and scenario generation
-- ############################################################################

CREATE OR REPLACE PROCEDURE SP_PRICE_OPTIMIZER(P_POLICY_TYPE VARCHAR, P_REGION VARCHAR DEFAULT NULL)
RETURNS VARIANT
LANGUAGE JAVASCRIPT
EXECUTE AS CALLER
AS
$$
  var policyType = P_POLICY_TYPE;
  var region = P_REGION;

  // Get our current pricing — bind parameters to prevent SQL injection
  var ourBinds = [policyType];
  var ourQuery = `SELECT AVG(PREMIUM_AMOUNT) AS AVG_PREMIUM, COUNT(*) AS POLICY_COUNT,
                         AVG(LOSS_RATIO) AS AVG_LOSS_RATIO
                  FROM POLICIES WHERE POLICY_TYPE = ? AND POLICY_STATUS = 'Active'`;
  if (region) {
    ourQuery += ` AND AGENT_ID IN (SELECT AGENT_ID FROM AGENTS WHERE REGION = ?)`;
    ourBinds.push(region);
  }
  var ourStmt = snowflake.createStatement({sqlText: ourQuery, binds: ourBinds});
  var ourResult = ourStmt.execute();
  ourResult.next();
  var ourAvgPremium = ourResult.getColumnValue('AVG_PREMIUM');
  var policyCount = ourResult.getColumnValue('POLICY_COUNT');
  var ourLossRatio = ourResult.getColumnValue('AVG_LOSS_RATIO');

  // Get competitor pricing — bind parameters to prevent SQL injection
  var compBinds = [policyType];
  var compQuery = `SELECT COMPETITOR_NAME, AVG(AVG_PREMIUM) AS AVG_PREMIUM,
                          AVG(MARKET_SHARE_PCT) AS MARKET_SHARE, AVG(CLAIMS_RATIO) AS LOSS_RATIO
                   FROM COMPETITOR_PRICING WHERE POLICY_TYPE = ?`;
  if (region) {
    compQuery += ` AND REGION = ?`;
    compBinds.push(region);
  }
  compQuery += ` GROUP BY COMPETITOR_NAME ORDER BY AVG_PREMIUM`;
  var compStmt = snowflake.createStatement({sqlText: compQuery, binds: compBinds});
  var compResult = compStmt.execute();

  var competitors = [];
  var totalMarketPremium = 0;
  var compCount = 0;
  while (compResult.next()) {
    var compPremium = compResult.getColumnValue('AVG_PREMIUM');
    totalMarketPremium += compPremium;
    compCount++;
    competitors.push({
      name: compResult.getColumnValue('COMPETITOR_NAME'),
      avg_premium: compPremium,
      market_share: compResult.getColumnValue('MARKET_SHARE'),
      loss_ratio: compResult.getColumnValue('LOSS_RATIO'),
      price_ratio: Math.round((ourAvgPremium / compPremium) * 10000) / 10000
    });
  }

  var marketAvg = compCount > 0 ? totalMarketPremium / compCount : ourAvgPremium;
  var position = ourAvgPremium > marketAvg * 1.05 ? 'ABOVE_MARKET'
               : ourAvgPremium < marketAvg * 0.95 ? 'BELOW_MARKET' : 'AT_MARKET';

  // Generate scenarios
  var scenarios = [
    { name: 'Match Market Average', target: marketAvg },
    { name: 'Undercut by 5%', target: marketAvg * 0.95 },
    { name: 'Premium Position (+10%)', target: marketAvg * 1.10 },
  ];

  var scenarioResults = scenarios.map(function(s) {
    var changePct = ((s.target - ourAvgPremium) / ourAvgPremium) * 100;
    var retentionImpact = changePct > 0 ? Math.max(0.85, 1 - changePct / 200) : Math.min(1.0, 1 - changePct / 300);
    return {
      scenario: s.name,
      proposed_premium: Math.round(s.target * 100) / 100,
      change_pct: Math.round(changePct * 100) / 100,
      estimated_retention: Math.round(retentionImpact * 10000) / 10000,
      projected_revenue: Math.round(s.target * policyCount * retentionImpact * 100) / 100,
      current_revenue: Math.round(ourAvgPremium * policyCount * 100) / 100
    };
  });

  return {
    policy_type: policyType,
    region: region || 'ALL',
    our_position: {
      avg_premium: Math.round(ourAvgPremium * 100) / 100,
      policy_count: policyCount,
      loss_ratio: Math.round(ourLossRatio * 10000) / 10000,
      market_position: position,
      vs_market_avg: Math.round((ourAvgPremium / marketAvg) * 10000) / 10000
    },
    market_average: Math.round(marketAvg * 100) / 100,
    competitors: competitors,
    scenarios: scenarioResults
  };
$$;

-- ############################################################################
-- Procedure 3: SP_MARKET_FORECAST
-- Market trend analysis with simple forecasting
-- ############################################################################

CREATE OR REPLACE PROCEDURE SP_MARKET_FORECAST(P_METRIC_NAME VARCHAR, P_POLICY_TYPE VARCHAR DEFAULT NULL)
RETURNS VARIANT
LANGUAGE JAVASCRIPT
EXECUTE AS CALLER
AS
$$
  var metricName = P_METRIC_NAME;
  var policyType = P_POLICY_TYPE;

  // Build query with bind parameters to prevent SQL injection
  var binds = [metricName];
  var query = `SELECT TREND_ID, METRIC_NAME, POLICY_TYPE, REGION,
                      PERIOD_START, PERIOD_END, METRIC_VALUE, PREVIOUS_VALUE,
                      YOY_CHANGE_PCT, TREND_DIRECTION, INDUSTRY_BENCHMARK,
                      OUR_PERFORMANCE, VARIANCE_TO_MARKET, CONFIDENCE_LEVEL
               FROM MARKET_TRENDS
               WHERE METRIC_NAME = ?`;
  if (policyType) {
    query += ` AND POLICY_TYPE = ?`;
    binds.push(policyType);
  }
  query += ` ORDER BY PERIOD_END DESC`;
  var stmt = snowflake.createStatement({sqlText: query, binds: binds});
  var result = stmt.execute();

  var trends = [];
  var totalYoY = 0;
  var count = 0;
  while (result.next()) {
    var yoy = result.getColumnValue('YOY_CHANGE_PCT') || 0;
    totalYoY += yoy;
    count++;
    trends.push({
      trend_id: result.getColumnValue('TREND_ID'),
      policy_type: result.getColumnValue('POLICY_TYPE'),
      region: result.getColumnValue('REGION'),
      period: result.getColumnValue('PERIOD_START') + ' to ' + result.getColumnValue('PERIOD_END'),
      current_value: result.getColumnValue('METRIC_VALUE'),
      previous_value: result.getColumnValue('PREVIOUS_VALUE'),
      yoy_change_pct: yoy,
      direction: result.getColumnValue('TREND_DIRECTION'),
      industry_benchmark: result.getColumnValue('INDUSTRY_BENCHMARK'),
      our_performance: result.getColumnValue('OUR_PERFORMANCE'),
      variance_to_market: result.getColumnValue('VARIANCE_TO_MARKET')
    });
  }

  var avgYoY = count > 0 ? totalYoY / count : 0;
  var overallDirection = avgYoY > 2 ? 'UP' : avgYoY < -2 ? 'DOWN' : 'STABLE';

  // Simple anomaly detection
  var anomalies = trends.filter(function(t) { return Math.abs(t.yoy_change_pct) > 15; });

  return {
    metric: metricName,
    policy_type: policyType || 'ALL',
    data_points: count,
    avg_yoy_change: Math.round(avgYoY * 100) / 100,
    overall_direction: overallDirection,
    trends: trends.slice(0, 10),
    anomalies: anomalies,
    forecast_note: 'Based on ' + count + ' data points, ' + metricName + ' is trending ' +
                   overallDirection + ' with avg YoY change of ' + (Math.round(avgYoY * 100) / 100) + '%'
  };
$$;
