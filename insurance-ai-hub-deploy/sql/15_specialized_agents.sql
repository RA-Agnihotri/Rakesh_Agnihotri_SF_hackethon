-- ============================================================================
-- INSURANCE AI HUB - Enhancement Deployment
-- Script 15: Specialized Domain Agents (3 agents with MCP)
-- ============================================================================
-- Run as: ACCOUNTADMIN
-- Depends on: 12_extended_semantic_views.sql, 18_mcp_connectors.sql
-- Note: Run AFTER 18_mcp_connectors.sql if MCP connector is set up.
--       If MCP is not yet configured, remove the mcp_servers section.
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE INSURANCE_AI_HUB;
USE SCHEMA ANALYTICS;

-- ############################################################################
-- Agent 1: MARKET_INTELLIGENCE_AGENT
-- ############################################################################

CREATE OR REPLACE AGENT MARKET_INTELLIGENCE_AGENT
  COMMENT = 'Market intelligence agent for trend detection and forecasting'
  PROFILE = '{"display_name": "Market Intel", "color": "purple"}'
  FROM SPECIFICATION $$
models:
  orchestration: auto
instructions:
  response: "Always include the trend direction and YoY change when discussing market metrics. Compare internal performance to industry benchmarks when possible. Flag anomalies and explain potential drivers."
  orchestration: >
    ROUTING RULES:
    - For market trends, benchmarks, YoY changes -> market_analyst
    - For internal claims, premium, performance -> operations_analyst
    - For Jira tickets -> use Atlassian MCP connector tools.
  system: "You are the Market Intelligence Assistant. You help executives understand market trends, detect anomalies, and benchmark against industry standards. You have Atlassian Jira access."
  sample_questions:
    - question: "What are the key market trends for Auto insurance this quarter?"
    - question: "How do our loss ratios compare to industry averages?"
    - question: "Which regions are seeing the fastest premium growth?"
tools:
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: market_analyst
      description: "Market trends, benchmarks, competitive landscape, YoY changes."
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: operations_analyst
      description: "Internal insurance operations, claims, policies, premiums."
  - tool_spec:
      type: data_to_chart
      name: data_to_chart
      description: "Generates visualizations from data."
mcp_servers:
  - server_spec:
      name: "INSURANCE_AI_HUB.ANALYTICS.ATLASSIAN_MCP_SERVER"
tool_resources:
  market_analyst:
    semantic_view: "INSURANCE_AI_HUB.ANALYTICS.SV_MARKET_INTELLIGENCE"
    execution_environment:
      type: warehouse
      warehouse: "COMPUTE_WH"
  operations_analyst:
    semantic_view: "INSURANCE_AI_HUB.ANALYTICS.SV_INSURANCE_OPS"
    execution_environment:
      type: warehouse
      warehouse: "COMPUTE_WH"
$$;

GRANT USAGE ON AGENT MARKET_INTELLIGENCE_AGENT TO ROLE ACCOUNTADMIN;

-- ############################################################################
-- Agent 2: PRICE_OPTIMIZATION_AGENT
-- ############################################################################

CREATE OR REPLACE AGENT PRICE_OPTIMIZATION_AGENT
  COMMENT = 'Price optimization agent for competitive analysis and pricing strategy'
  PROFILE = '{"display_name": "Pricing Advisor", "color": "green"}'
  FROM SPECIFICATION $$
models:
  orchestration: auto
instructions:
  response: "Always show the price ratio (our price / market avg) when discussing competitive positioning. Include competitor names and market share when available."
  orchestration: >
    ROUTING RULES:
    - For competitor pricing, market position -> competitive_intel_analyst
    - For internal policies, premiums, loss ratios -> portfolio_analyst
    - For Jira tickets -> use Atlassian MCP connector tools.
  system: "You are the Pricing Optimization Assistant for insurance premium analysis. You have Atlassian Jira access."
  sample_questions:
    - question: "How does our Health insurance pricing compare to competitors?"
    - question: "Which regions are we most overpriced in?"
    - question: "What is the revenue impact of matching market pricing for Auto?"
tools:
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: competitive_intel_analyst
      description: "Competitor pricing, market positioning, pricing scenarios, revenue impact."
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: portfolio_analyst
      description: "Internal policy portfolio, premium amounts, loss ratios."
mcp_servers:
  - server_spec:
      name: "INSURANCE_AI_HUB.ANALYTICS.ATLASSIAN_MCP_SERVER"
tool_resources:
  competitive_intel_analyst:
    semantic_view: "INSURANCE_AI_HUB.ANALYTICS.SV_COMPETITIVE_INTEL"
    execution_environment:
      type: warehouse
      warehouse: "COMPUTE_WH"
  portfolio_analyst:
    semantic_view: "INSURANCE_AI_HUB.ANALYTICS.SV_INSURANCE_OPS"
    execution_environment:
      type: warehouse
      warehouse: "COMPUTE_WH"
$$;

GRANT USAGE ON AGENT PRICE_OPTIMIZATION_AGENT TO ROLE ACCOUNTADMIN;

-- ############################################################################
-- Agent 3: PRODUCT_MATCHING_AGENT
-- ############################################################################

CREATE OR REPLACE AGENT PRODUCT_MATCHING_AGENT
  COMMENT = 'Product matching agent with multi-strategy recommendation engine'
  PROFILE = '{"display_name": "Product Matcher", "color": "blue"}'
  FROM SPECIFICATION $$
models:
  orchestration: auto
instructions:
  response: "Always include the match strategy used, the confidence score, and the contributing factors. Compare recommended premium to market average when available."
  orchestration: >
    ROUTING RULES:
    - For product recommendations, match scores -> product_matching_analyst
    - For customer profiles, risk tiers -> customer_analyst
    - For product features, eligibility -> product_search
    - For Jira tickets -> use Atlassian MCP connector tools.
  system: "You are the Product Matching Assistant using rule-based, similarity, and AI scoring strategies. You have Atlassian Jira access."
  sample_questions:
    - question: "What products best match customer CUST-00042?"
    - question: "Which matching strategy performs best for high-risk customers?"
    - question: "Show me the top 5 product recommendations for Corporate segment"
tools:
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: product_matching_analyst
      description: "Product-customer match scores, strategies, recommendations."
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: customer_analyst
      description: "Customer profiles, risk tiers, segments, credit scores."
  - tool_spec:
      type: cortex_search
      name: product_search
      description: "Product catalog features, eligibility rules, coverage details."
mcp_servers:
  - server_spec:
      name: "INSURANCE_AI_HUB.ANALYTICS.ATLASSIAN_MCP_SERVER"
tool_resources:
  product_matching_analyst:
    semantic_view: "INSURANCE_AI_HUB.ANALYTICS.SV_PRODUCT_MATCHING"
    execution_environment:
      type: warehouse
      warehouse: "COMPUTE_WH"
  customer_analyst:
    semantic_view: "INSURANCE_AI_HUB.ANALYTICS.SV_INSURANCE_OPS"
    execution_environment:
      type: warehouse
      warehouse: "COMPUTE_WH"
  product_search:
    search_service: "INSURANCE_AI_HUB.DOCUMENTS.CORTEX_SEARCH_SVC"
    max_results: 5
    title_column: "SECTION_TITLE"
    id_column: "CHUNK_ID"
$$;

GRANT USAGE ON AGENT PRODUCT_MATCHING_AGENT TO ROLE ACCOUNTADMIN;
