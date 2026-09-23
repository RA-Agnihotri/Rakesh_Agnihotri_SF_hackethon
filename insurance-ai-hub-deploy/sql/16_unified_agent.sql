-- ============================================================================
-- INSURANCE AI HUB - Enhancement Deployment
-- Script 16: Unified Enterprise Agent (7 tools + chart + MCP)
-- ============================================================================
-- Run as: ACCOUNTADMIN
-- Depends on: All semantic views, cortex search, 18_mcp_connectors.sql
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE INSURANCE_AI_HUB;
USE SCHEMA ANALYTICS;

-- ############################################################################
-- UNIFIED_ENTERPRISE_AGENT
-- The most comprehensive agent combining all 6 analytical domains
-- Does NOT replace INSURANCE_INTELLIGENCE_AGENT (dashboard depends on it)
-- ############################################################################

CREATE OR REPLACE AGENT UNIFIED_ENTERPRISE_AGENT
  COMMENT = 'Unified Enterprise Agent - combines all insurance intelligence capabilities (ops, DQ, documents, competitive pricing, market trends, product matching) into a single 7-tool agent.'
  PROFILE = '{"display_name": "Insurance Enterprise Hub", "color": "blue"}'
  FROM SPECIFICATION $$
models:
  orchestration: auto
orchestration:
  capabilities:
    analytical_search: true
instructions:
  response: >
    Always ground answers in data from tool results. Include source citations
    for every factual claim. For document answers, cite document ID and section.
    For analytics answers, show the underlying metric and filters used.
    For pricing analysis, always show price ratio vs market. Never fabricate
    data or statistics not returned by tools. When uncertain, say so clearly.
    PRIVACY: Never include email addresses, phone numbers, physical addresses,
    dates of birth, or Social Security numbers in your text responses. Refer
    to customers by Customer ID and name only. If a query returns PII columns,
    summarize the data without reproducing the raw PII values.
  orchestration: >
    ROUTING RULES:
    - Customers, policies, claims, billing, premiums, risk, agents, KPIs
      -> insurance_operations_analyst
    - Data quality, DQ scores, failed rules, column health
      -> data_quality_analyst
    - Policy coverage, exclusions, benefits, procedures
      -> policy_document_search
    - Competitor pricing, market position, pricing scenarios
      -> competitive_intel_analyst
    - Market trends, industry benchmarks, forecasting
      -> market_intelligence_analyst
    - Product recommendations, matching scores, customer-product fit
      -> product_matching_analyst
    - When the user asks for a chart or visualization, ALWAYS use
      data_to_chart after retrieving the data.
    - For cross-domain questions, decompose and use multiple tools.
    - When the user asks to create, update, or search Jira tickets,
      use the Atlassian MCP connector tools.
    - When insights reveal issues (high risk, pricing gaps, data quality
      failures), offer to create a Jira ticket to track the action item.
  system: >
    You are the Unified Enterprise Insurance Agent, the most comprehensive
    AI advisor in the Insurance AI Hub. You combine six specialized analytical
    domains - operations, data quality, policy documents, competitive pricing,
    market intelligence, and product matching - into a single conversational
    interface. You also have access to Atlassian Jira for creating and managing
    tickets. You help executives, claims managers, underwriters, fraud
    investigators, pricing analysts, and data stewards make data-driven
    decisions across the entire insurance value chain.
  sample_questions:
    - question: "What is the total premium revenue by policy type?"
    - question: "How does our pricing compare to competitors for Health insurance?"
    - question: "What are the key market trends this quarter?"
    - question: "Which products best match our high-risk customers?"
    - question: "What does the health policy say about pre-existing conditions?"
    - question: "Which tables have the lowest data quality scores?"
    - question: "Show me a chart of revenue at risk by category"
    - question: "Compare our loss ratios to industry benchmarks by region"
    - question: "Create a Jira ticket to review Health pricing in the Northeast"
tools:
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: insurance_operations_analyst
      description: "Answers questions about insurance customers, policies, claims, billing, agents, and at-risk policies using structured data."
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: data_quality_analyst
      description: "Answers questions about data quality rules, execution results, table-level scores, column health, and score trends."
  - tool_spec:
      type: cortex_search
      name: policy_document_search
      description: "Searches policy documents, coverage summaries, exclusion clauses, and claims procedures."
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: competitive_intel_analyst
      description: "Answers questions about competitor pricing, market positioning, pricing scenarios, and revenue impact projections."
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: market_intelligence_analyst
      description: "Answers questions about market trends, industry benchmarks, year-over-year changes, and regional market conditions."
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: product_matching_analyst
      description: "Answers questions about product-customer match scores, matching strategies, and recommendation accuracy."
  - tool_spec:
      type: data_to_chart
      name: data_to_chart
      description: "Generates visualizations from data returned by other tools."
mcp_servers:
  - server_spec:
      name: "INSURANCE_AI_HUB.ANALYTICS.ATLASSIAN_MCP_SERVER"
tool_resources:
  insurance_operations_analyst:
    semantic_view: "INSURANCE_AI_HUB.ANALYTICS.SV_INSURANCE_OPS"
    execution_environment:
      type: warehouse
      warehouse: "COMPUTE_WH"
  data_quality_analyst:
    semantic_view: "INSURANCE_AI_HUB.DATA_QUALITY.SV_DATA_QUALITY"
    execution_environment:
      type: warehouse
      warehouse: "COMPUTE_WH"
  policy_document_search:
    search_service: "INSURANCE_AI_HUB.DOCUMENTS.CORTEX_SEARCH_SVC"
    max_results: 5
    title_column: "SECTION_TITLE"
    id_column: "CHUNK_ID"
  competitive_intel_analyst:
    semantic_view: "INSURANCE_AI_HUB.ANALYTICS.SV_COMPETITIVE_INTEL"
    execution_environment:
      type: warehouse
      warehouse: "COMPUTE_WH"
  market_intelligence_analyst:
    semantic_view: "INSURANCE_AI_HUB.ANALYTICS.SV_MARKET_INTELLIGENCE"
    execution_environment:
      type: warehouse
      warehouse: "COMPUTE_WH"
  product_matching_analyst:
    semantic_view: "INSURANCE_AI_HUB.ANALYTICS.SV_PRODUCT_MATCHING"
    execution_environment:
      type: warehouse
      warehouse: "COMPUTE_WH"
$$;

GRANT USAGE ON AGENT UNIFIED_ENTERPRISE_AGENT TO ROLE ACCOUNTADMIN;
