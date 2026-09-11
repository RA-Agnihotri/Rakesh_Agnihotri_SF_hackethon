# Insurance AI Hub — Enhancement Plan

## Current State Summary

The deployed solution includes:
- **1 database** (`INSURANCE_AI_HUB`) with 3 schemas, 13 tables, 4 views
- **2 semantic views** (SV_INSURANCE_OPS with 10 VQRs, SV_DATA_QUALITY with 5 VQRs)
- **1 Cortex Agent** (`INSURANCE_INTELLIGENCE_AGENT`) with 3 tools (2x Cortex Analyst, 1x Cortex Search)
- **1 Cortex Search Service** (RAG over 25 document chunks)
- **3 stored procedures** (claim risk scoring, trend detection, DQ root cause)
- **6 database roles** with RBAC hierarchy, 3 masking policies, 2 governance tags
- **React dashboard** (9 pages: Executive, KPI, AI Assistant, Knowledge Hub, Agent Insights, Document Intelligence, Data Explorer, Governance, Admin Console)

---

## Gap Analysis: What Needs to Be Added

### Requirement 1: Product Matching Agent with Multi-Strategy Approach

**What exists today:** The current agent (`INSURANCE_INTELLIGENCE_AGENT`) answers questions about existing policies, claims, and billing. It does NOT perform any product-to-customer matching, recommendation, or comparison logic.

**What's missing:**

| Gap | Description |
|-----|-------------|
| **Competitive products data** | No table storing competitor products, market rates, or benchmark pricing |
| **Product catalog table** | No normalized product catalog with features, coverage tiers, and pricing rules |
| **Matching logic** | No procedure or function that scores customer-to-product fit based on risk profile, segment, credit score, or coverage needs |
| **Multi-strategy scoring** | No implementation of multiple matching strategies (rule-based, similarity-based, AI-scored) that can be compared or ensembled |
| **Dedicated matching agent** | No agent specifically designed for product recommendation with orchestration instructions tailored to matching workflows |

### Requirement 2: Price Optimization Agent for Competitive Analysis

**What exists today:** Policies have `PREMIUM_AMOUNT`, `COVERAGE_AMOUNT`, `DEDUCTIBLE`, and `LOSS_RATIO`, but there is no competitor pricing data, no price elasticity modeling, no optimization logic, and no competitive benchmarking.

**What's missing:**

| Gap | Description |
|-----|-------------|
| **Competitor pricing data** | No table for market rates, competitor premiums, or industry benchmarks by policy type/region/tier |
| **Price optimization procedures** | No stored procedure or function that calculates optimal pricing given risk factors, market position, and retention goals |
| **Elasticity/sensitivity analysis** | No analysis of how price changes affect retention (AT_RISK_POLICIES has churn data but it's not linked to pricing scenarios) |
| **Pricing recommendation semantic view** | No semantic view that joins internal pricing with competitor benchmarks for NL queries |
| **Dedicated pricing agent** | No agent configured with pricing-specific tools and orchestration |

### Requirement 3: Market Intelligence Agent for Trend Detection

**What exists today:** `SP_TREND_DETECTOR` provides basic weekly aggregations for claims, premiums, and DQ scores. It does NOT perform any market-level analysis, external trend detection, or predictive forecasting.

**What's missing:**

| Gap | Description |
|-----|-------------|
| **Market data tables** | No tables for industry trends, regulatory changes, economic indicators, or regional market conditions |
| **Advanced trend detection** | `SP_TREND_DETECTOR` only does weekly GROUP BY — no moving averages, anomaly detection, seasonal decomposition, or forecasting |
| **Cortex ML functions** | Not using `SNOWFLAKE.ML.FORECAST`, `SNOWFLAKE.ML.ANOMALY_DETECTION`, or `SNOWFLAKE.ML.TOP_INSIGHTS` on claims/premium data |
| **Market intelligence semantic view** | No semantic view that combines internal performance with market context for NL queries |
| **Dedicated market intelligence agent** | No agent specifically for trend and market analysis |

### Requirement 4: Snowflake Intelligence (CoWork)

**What exists today:** The agent is deployed as `INSURANCE_AI_HUB.ANALYTICS.INSURANCE_INTELLIGENCE_AGENT` and is callable via REST API from the React dashboard. It is NOT yet registered with Snowflake CoWork.

**What's missing:**

| Gap | Description |
|-----|-------------|
| **Snowflake Intelligence object** | No `CREATE SNOWFLAKE INTELLIGENCE` object has been created |
| **CoWork agent registration** | The existing agent is not surfaced in the CoWork UI (AI & ML > Agents) for business users |
| **Dashboard pages in CoWork** | The React dashboard's competitive pricing, market trend, and matching accuracy views are not available inside Snowflake — they only live in the external React app |
| **Data-to-chart tool** | The agent does not have `data_to_chart` tool enabled for in-CoWork visualizations |
| **Code execution tool** | The agent does not have Python code execution enabled for ad-hoc analysis |
| **Agent profile** | No `PROFILE` set on the agent (display_name, avatar, color) for CoWork branding |

### Requirement 5: MCP Integration

**What exists today:** No MCP connectors are configured. The solution is entirely self-contained within Snowflake.

**What's missing:**

| Gap | Description |
|-----|-------------|
| **External data source connectors** | No MCP connector to pull competitor pricing or market data from external APIs |
| **Notification/action connectors** | No MCP connector to push alerts (e.g., Slack notifications for high-risk matches, Jira tickets for pricing reviews) |
| **API integration objects** | No `CREATE API INTEGRATION` for MCP OAuth credentials |
| **External MCP server objects** | No `CREATE EXTERNAL MCP SERVER` objects |
| **Agent MCP tool configuration** | Agent specification does not reference any MCP connectors |

---

## Data Relationship Model: How New Tables Connect to Existing Data

This is the critical design section. Every new table joins back to the existing schema through explicit foreign keys or shared dimension columns. Nothing is isolated.

### Existing Data Model (Recap)

```
CUSTOMERS ──(1:N)──> POLICIES ──(1:N)──> CLAIMS
    │                    │                    │
    │                    │                    └──(N:1)──> AGENTS (via ASSIGNED_ADJUSTER)
    │                    │
    │                    ├──(1:N)──> BILLING
    │                    │
    │                    └──(1:N)──> AT_RISK_POLICIES
    │
    └──(1:N)──> CLAIMS (direct CUSTOMER_ID FK)
```

**Shared dimension columns already in use:** `POLICY_TYPE` (Health/Auto/Life/Home), `PLAN_TIER` (Bronze/Silver/Gold/Platinum), `REGION` (Northeast/Southeast/Midwest/Southwest/West), `SEGMENT` (Individual/Family/Corporate/Senior), `RISK_TIER` (Low/Medium/High/Very High).

### New Tables and Their Join Paths

```
                         ┌─────────────────┐
                         │  PRODUCT_CATALOG │
                         │  PK: PRODUCT_ID  │
                         │  POLICY_TYPE     │◄──── shared dimension
                         │  PLAN_TIER       │◄──── shared dimension
                         │  TARGET_SEGMENT  │◄──── matches CUSTOMERS.SEGMENT
                         │  TARGET_RISK_TIER│◄──── matches CUSTOMERS.RISK_TIER
                         └────────┬─────────┘
                                  │
              FK: PRODUCT_ID      │
         ┌────────────────────────┤
         │                        │
         ▼                        ▼
┌──────────────────┐    ┌───────────────────────┐
│PRODUCT_MATCH_SCORES│   │ POLICIES (existing)   │
│FK: CUSTOMER_ID ──────►│ POLICY_TYPE = same     │
│FK: PRODUCT_ID ───────►│ PLAN_TIER = same       │
│ (joins CUSTOMERS)│    │ CUSTOMER_ID            │
└──────────────────┘    └───────────┬────────────┘
                                    │
                                    │ POLICY_TYPE + PLAN_TIER + REGION
                                    ▼
                        ┌───────────────────────┐
                        │ COMPETITOR_PRICING     │
                        │ POLICY_TYPE            │◄──── joins to POLICIES
                        │ PLAN_TIER              │◄──── joins to POLICIES
                        │ REGION                 │◄──── joins to AGENTS.REGION
                        └───────────┬────────────┘
                                    │
                                    │ POLICY_TYPE + REGION
                                    ▼
                        ┌───────────────────────┐
                        │ MARKET_TRENDS          │
                        │ POLICY_TYPE            │◄──── joins to POLICIES
                        │ REGION                 │◄──── joins to AGENTS.REGION
                        └────────────────────────┘

                        ┌───────────────────────┐
                        │ PRICING_SCENARIOS      │
                        │ POLICY_TYPE            │◄──── joins to POLICIES
                        │ PLAN_TIER              │◄──── joins to POLICIES
                        │ REGION                 │◄──── joins to AGENTS.REGION
                        │ MARKET_AVG_PREMIUM     │◄──── derived from COMPETITOR_PRICING
                        └────────────────────────┘
```

### Join Specifications (Every Relationship Spelled Out)

#### 1. PRODUCT_CATALOG ↔ Existing Tables

| Join | Type | Columns | Purpose |
|------|------|---------|---------|
| PRODUCT_CATALOG → POLICIES | Many-to-Many via shared dimensions | `PRODUCT_CATALOG.POLICY_TYPE = POLICIES.POLICY_TYPE AND PRODUCT_CATALOG.PLAN_TIER = POLICIES.PLAN_TIER` | Compare catalog products to actual sold policies; find which products map to which active policies |
| PRODUCT_CATALOG → CUSTOMERS | Eligibility matching | `PRODUCT_CATALOG.TARGET_SEGMENT = CUSTOMERS.SEGMENT AND PRODUCT_CATALOG.TARGET_RISK_TIER = CUSTOMERS.RISK_TIER` | Match products to customers based on segment and risk profile |
| PRODUCT_CATALOG → COMPETITOR_PRICING | Market comparison | `PRODUCT_CATALOG.POLICY_TYPE = COMPETITOR_PRICING.POLICY_TYPE AND PRODUCT_CATALOG.PLAN_TIER = COMPETITOR_PRICING.PLAN_TIER` | Compare our base premium to competitor averages for same product category |

**Example query this enables:**
```sql
-- "Which of our products are priced above the market average?"
SELECT pc.PRODUCT_NAME, pc.POLICY_TYPE, pc.PLAN_TIER, pc.BASE_PREMIUM,
       AVG(cp.AVG_PREMIUM) AS market_avg,
       ROUND(pc.BASE_PREMIUM / NULLIF(AVG(cp.AVG_PREMIUM), 0), 2) AS price_ratio
FROM PRODUCT_CATALOG pc
JOIN COMPETITOR_PRICING cp
  ON pc.POLICY_TYPE = cp.POLICY_TYPE AND pc.PLAN_TIER = cp.PLAN_TIER
GROUP BY 1,2,3,4
HAVING price_ratio > 1.0
ORDER BY price_ratio DESC;
```

#### 2. PRODUCT_MATCH_SCORES ↔ Existing Tables

| Join | Type | Columns | Purpose |
|------|------|---------|---------|
| PRODUCT_MATCH_SCORES → CUSTOMERS | FK | `PRODUCT_MATCH_SCORES.CUSTOMER_ID = CUSTOMERS.CUSTOMER_ID` | Get full customer profile for each match recommendation |
| PRODUCT_MATCH_SCORES → PRODUCT_CATALOG | FK | `PRODUCT_MATCH_SCORES.PRODUCT_ID = PRODUCT_CATALOG.PRODUCT_ID` | Get product details (name, features, base premium) for each match |
| PRODUCT_MATCH_SCORES → POLICIES | Via CUSTOMER_ID | `PRODUCT_MATCH_SCORES.CUSTOMER_ID = POLICIES.CUSTOMER_ID` | See what the customer already has — avoid recommending duplicates, identify upsell/cross-sell opportunities |
| PRODUCT_MATCH_SCORES → AT_RISK_POLICIES | Via CUSTOMER_ID | `PRODUCT_MATCH_SCORES.CUSTOMER_ID = AT_RISK_POLICIES.CUSTOMER_ID` | Factor churn risk into matching — prioritize retention offers for at-risk customers |

**Example query this enables:**
```sql
-- "Show me product recommendations for at-risk customers, including their current churn probability"
SELECT c.FIRST_NAME, c.LAST_NAME, c.SEGMENT, c.RISK_TIER,
       pc.PRODUCT_NAME, ms.MATCH_SCORE, ms.MATCH_STRATEGY,
       ar.CHURN_PROBABILITY, ar.REVENUE_AT_RISK, ar.RECOMMENDED_ACTION
FROM PRODUCT_MATCH_SCORES ms
JOIN CUSTOMERS c ON ms.CUSTOMER_ID = c.CUSTOMER_ID
JOIN PRODUCT_CATALOG pc ON ms.PRODUCT_ID = pc.PRODUCT_ID
JOIN AT_RISK_POLICIES ar ON ms.CUSTOMER_ID = ar.CUSTOMER_ID
WHERE ms.MATCH_RANK = 1
ORDER BY ar.CHURN_PROBABILITY DESC;
```

#### 3. COMPETITOR_PRICING ↔ Existing Tables

| Join | Type | Columns | Purpose |
|------|------|---------|---------|
| COMPETITOR_PRICING → POLICIES | Dimension join | `COMPETITOR_PRICING.POLICY_TYPE = POLICIES.POLICY_TYPE AND COMPETITOR_PRICING.PLAN_TIER = POLICIES.PLAN_TIER` | Compare our actual premiums to competitor benchmarks |
| COMPETITOR_PRICING → AGENTS | Region bridge | `COMPETITOR_PRICING.REGION = AGENTS.REGION` (via POLICIES.AGENT_ID → AGENTS) | Regional competitive analysis — how are we positioned in each agent's territory |
| COMPETITOR_PRICING → MARKET_TRENDS | Context join | `COMPETITOR_PRICING.POLICY_TYPE = MARKET_TRENDS.POLICY_TYPE AND COMPETITOR_PRICING.REGION = MARKET_TRENDS.REGION` | Overlay competitor pricing on top of market trends |

**Example query this enables:**
```sql
-- "How does our average Health premium compare to competitors in each region?"
SELECT a.REGION,
       AVG(p.PREMIUM_AMOUNT) AS our_avg_premium,
       cp.COMPETITOR_NAME,
       cp.AVG_PREMIUM AS competitor_avg,
       ROUND(AVG(p.PREMIUM_AMOUNT) / NULLIF(cp.AVG_PREMIUM, 0), 2) AS price_ratio,
       CASE WHEN AVG(p.PREMIUM_AMOUNT) < cp.AVG_PREMIUM * 0.95 THEN 'Below Market'
            WHEN AVG(p.PREMIUM_AMOUNT) > cp.AVG_PREMIUM * 1.05 THEN 'Above Market'
            ELSE 'At Market' END AS position
FROM POLICIES p
JOIN AGENTS a ON p.AGENT_ID = a.AGENT_ID
JOIN COMPETITOR_PRICING cp
  ON p.POLICY_TYPE = cp.POLICY_TYPE AND p.PLAN_TIER = cp.PLAN_TIER AND a.REGION = cp.REGION
WHERE p.POLICY_STATUS = 'Active' AND p.POLICY_TYPE = 'Health'
GROUP BY a.REGION, cp.COMPETITOR_NAME, cp.AVG_PREMIUM;
```

#### 4. MARKET_TRENDS ↔ Existing Tables

| Join | Type | Columns | Purpose |
|------|------|---------|---------|
| MARKET_TRENDS → POLICIES | Dimension join | `MARKET_TRENDS.POLICY_TYPE = POLICIES.POLICY_TYPE` | Compare our premium/loss ratio to industry metrics |
| MARKET_TRENDS → CLAIMS | Dimension join | `MARKET_TRENDS.POLICY_TYPE = matching policy type via CLAIMS→POLICIES` | Compare our claim frequency to industry claim_frequency metric |
| MARKET_TRENDS → AGENTS | Region bridge | `MARKET_TRENDS.REGION = AGENTS.REGION` | Regional market conditions for each agent territory |
| MARKET_TRENDS → COMPETITOR_PRICING | Both external | `MARKET_TRENDS.POLICY_TYPE = COMPETITOR_PRICING.POLICY_TYPE AND MARKET_TRENDS.REGION = COMPETITOR_PRICING.REGION` | Full external picture: market trends + competitor positioning |

**Example query this enables:**
```sql
-- "How does our loss ratio compare to the industry benchmark by policy type?"
SELECT mt.POLICY_TYPE,
       mt.METRIC_VALUE AS industry_loss_ratio,
       AVG(p.LOSS_RATIO) AS our_loss_ratio,
       ROUND(AVG(p.LOSS_RATIO) - mt.METRIC_VALUE, 3) AS variance,
       mt.TREND_DIRECTION AS industry_trend
FROM MARKET_TRENDS mt
JOIN POLICIES p ON mt.POLICY_TYPE = p.POLICY_TYPE
WHERE mt.METRIC_NAME = 'loss_ratio_benchmark'
  AND p.POLICY_STATUS = 'Active'
GROUP BY mt.POLICY_TYPE, mt.METRIC_VALUE, mt.TREND_DIRECTION;
```

#### 5. PRICING_SCENARIOS ↔ Existing Tables

| Join | Type | Columns | Purpose |
|------|------|---------|---------|
| PRICING_SCENARIOS → POLICIES | Dimension join | `PRICING_SCENARIOS.POLICY_TYPE = POLICIES.POLICY_TYPE AND PRICING_SCENARIOS.PLAN_TIER = POLICIES.PLAN_TIER` | Scenario is derived from aggregating active policies, links back for validation |
| PRICING_SCENARIOS → COMPETITOR_PRICING | Dimension join | `PRICING_SCENARIOS.POLICY_TYPE = COMPETITOR_PRICING.POLICY_TYPE AND PRICING_SCENARIOS.PLAN_TIER = COMPETITOR_PRICING.PLAN_TIER AND PRICING_SCENARIOS.REGION = COMPETITOR_PRICING.REGION` | Each scenario's MARKET_AVG_PREMIUM comes from competitor data |
| PRICING_SCENARIOS → AT_RISK_POLICIES | Impact analysis | Via POLICY_TYPE — the retention projections factor in churn data from at-risk policies in the same category | Project how a price change affects churn for that segment |

### Complete Data Model Diagram (Existing + New)

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                         INSURANCE_AI_HUB.ANALYTICS                          │
│                                                                              │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐              │
│  │ CUSTOMERS │◄──┤ POLICIES │───►│  CLAIMS  │    │ BILLING  │              │
│  │           │    │          │    │          │    │          │              │
│  │CUSTOMER_ID│    │POLICY_ID │    │ CLAIM_ID │    │BILLING_ID│              │
│  │SEGMENT    │    │CUST_ID(FK│    │POL_ID(FK)│    │POL_ID(FK)│              │
│  │RISK_TIER  │    │AGENT_ID  │    │CUST_ID   │    │CUST_ID   │              │
│  │CREDIT_SCOR│    │POLICY_TYP│◄─┐│          │    │          │              │
│  └─────┬─────┘    │PLAN_TIER │  ││          │    └──────────┘              │
│        │          └────┬─────┘  │└──────────┘                              │
│        │               │        │                                           │
│        │     ┌─────────┘        │    ┌────────────────┐   ┌──────────┐     │
│        │     │                  │    │AT_RISK_POLICIES │   │  AGENTS  │     │
│        │     │                  │    │  POLICY_ID(FK)  │   │ AGENT_ID │     │
│        │     │                  │    │  CUSTOMER_ID(FK)│   │ REGION   │     │
│        │     │                  │    │  CHURN_PROB     │   └────┬─────┘     │
│        │     │                  │    └────────┬────────┘        │           │
│  ══════╪═════╪══════════════════╪════════════╪═════════════════╪═══════    │
│  NEW   │     │   shared dims   │            │                  │           │
│  ──────┼─────┼──────────────────┼────────────┼──────────────────┼───────   │
│        │     │                  │            │                  │           │
│        ▼     ▼                  │            ▼                  ▼           │
│  ┌───────────────┐         ┌───┴────────────────┐   ┌──────────────────┐  │
│  │PRODUCT_CATALOG│         │PRODUCT_MATCH_SCORES │   │COMPETITOR_PRICING│  │
│  │               │◄────FK──┤                     │   │                  │  │
│  │PRODUCT_ID(PK) │         │CUSTOMER_ID(FK)──────────►CUSTOMERS        │  │
│  │POLICY_TYPE  ──┼─ shared │PRODUCT_ID(FK)───────┤   │POLICY_TYPE ─────┼──┤
│  │PLAN_TIER   ──┼─ shared │MATCH_SCORE          │   │PLAN_TIER  ─────┼──┤
│  │TARGET_SEGMENT │         │MATCH_STRATEGY       │   │REGION     ─────┼──┤
│  │TARGET_RISK_TIR│         │PRICE_VS_MARKET      │   │AVG_PREMIUM     │  │
│  └───────────────┘         └────────────────────┘   └──────────────────┘  │
│                                                                             │
│  ┌──────────────────┐      ┌────────────────────┐                          │
│  │  MARKET_TRENDS    │      │ PRICING_SCENARIOS   │                         │
│  │                   │      │                     │                         │
│  │POLICY_TYPE ───────┼──shared──POLICY_TYPE       │                         │
│  │REGION      ───────┼──shared──PLAN_TIER         │                         │
│  │METRIC_NAME        │      │REGION               │                         │
│  │METRIC_VALUE       │      │CURRENT_PREMIUM      │                         │
│  │YOY_CHANGE_PCT     │      │PROPOSED_PREMIUM     │                         │
│  │TREND_DIRECTION    │      │MARKET_AVG_PREMIUM   │                         │
│  └───────────────────┘      │REVENUE_IMPACT       │                         │
│                              └────────────────────┘                         │
└──────────────────────────────────────────────────────────────────────────────┘

LEGEND:
  ──FK──►  = Foreign key (CUSTOMER_ID, PRODUCT_ID)
  ──shared── = Dimension join (POLICY_TYPE, PLAN_TIER, REGION, SEGMENT, RISK_TIER)
```

### Relationship Types Summary

| New Table | Join Type | Existing Table(s) | Join Column(s) | Cardinality |
|-----------|-----------|-------------------|----------------|-------------|
| **PRODUCT_CATALOG** | Shared dimension | POLICIES | POLICY_TYPE + PLAN_TIER | M:N (one product maps to many policies of that type/tier) |
| **PRODUCT_CATALOG** | Eligibility match | CUSTOMERS | TARGET_SEGMENT = SEGMENT, TARGET_RISK_TIER = RISK_TIER | M:N (one product targets many customers) |
| **PRODUCT_MATCH_SCORES** | **FK** | CUSTOMERS | CUSTOMER_ID | N:1 (many scores per customer) |
| **PRODUCT_MATCH_SCORES** | **FK** | PRODUCT_CATALOG | PRODUCT_ID | N:1 (many scores per product) |
| **PRODUCT_MATCH_SCORES** | Transitive FK | POLICIES, AT_RISK_POLICIES | via CUSTOMER_ID | Enables cross-reference to existing policies and churn risk |
| **COMPETITOR_PRICING** | Shared dimension | POLICIES | POLICY_TYPE + PLAN_TIER | M:N (one benchmark row maps to many policies) |
| **COMPETITOR_PRICING** | Shared dimension | AGENTS | REGION | M:N (one region has many agents, many benchmarks) |
| **COMPETITOR_PRICING** | Shared dimension | PRODUCT_CATALOG | POLICY_TYPE + PLAN_TIER | M:N (compare our catalog to competitor catalog) |
| **MARKET_TRENDS** | Shared dimension | POLICIES | POLICY_TYPE | M:N |
| **MARKET_TRENDS** | Shared dimension | AGENTS | REGION | M:N |
| **MARKET_TRENDS** | Shared dimension | COMPETITOR_PRICING | POLICY_TYPE + REGION | M:N |
| **PRICING_SCENARIOS** | Shared dimension | POLICIES | POLICY_TYPE + PLAN_TIER | M:N (scenario applies to group of policies) |
| **PRICING_SCENARIOS** | Shared dimension | COMPETITOR_PRICING | POLICY_TYPE + PLAN_TIER + REGION | 1:N (scenario references market avg) |
| **PRICING_SCENARIOS** | Impact analysis | AT_RISK_POLICIES | via POLICY_TYPE (aggregate) | Retention projections factor in churn data |

### Why This Design Works

1. **Two FK-based joins** (`PRODUCT_MATCH_SCORES.CUSTOMER_ID → CUSTOMERS`, `PRODUCT_MATCH_SCORES.PRODUCT_ID → PRODUCT_CATALOG`) create the direct transactional link between matching results and the customer/product entities.

2. **Five dimension-based joins** (`POLICY_TYPE`, `PLAN_TIER`, `REGION`, `SEGMENT`, `RISK_TIER`) reuse the same enum values already in the existing tables. The seed data for new tables must use the exact same values:
   - POLICY_TYPE: `'Health'`, `'Auto'`, `'Life'`, `'Home'`
   - PLAN_TIER: `'Bronze'`, `'Silver'`, `'Gold'`, `'Platinum'`
   - REGION: `'Northeast'`, `'Southeast'`, `'Midwest'`, `'Southwest'`, `'West'`
   - SEGMENT: `'Individual'`, `'Family'`, `'Corporate'`, `'Senior'`
   - RISK_TIER: `'Low'`, `'Medium'`, `'High'`, `'Very High'`

3. **No orphaned tables.** Every new table participates in at least 2 join paths back to the existing schema. The views in Phase 3 (VW_COMPETITIVE_PRICING, VW_MATCH_ACCURACY, VW_MARKET_ANALYSIS) all use these joins explicitly.

4. **Semantic views in Phase 4 declare these relationships** so that the Cortex Analyst agents can generate correct JOIN SQL when answering natural language questions.

### DDL Changes Required in the Enhancement Plan

The PRODUCT_CATALOG and PRODUCT_MATCH_SCORES DDL in Phase 1 already include the correct FK columns (`CUSTOMER_ID`, `PRODUCT_ID`). To make the relationships fully explicit, add a `PRODUCT_ID` column to the POLICIES table via ALTER (optional — links a sold policy back to the catalog product it was sold from):

```sql
-- Optional: link existing policies to the product catalog
ALTER TABLE INSURANCE_AI_HUB.ANALYTICS.POLICIES
  ADD COLUMN PRODUCT_ID VARCHAR(20);

-- Backfill: map existing policies to catalog products by type + tier
UPDATE INSURANCE_AI_HUB.ANALYTICS.POLICIES p
SET PRODUCT_ID = (
    SELECT pc.PRODUCT_ID
    FROM INSURANCE_AI_HUB.ANALYTICS.PRODUCT_CATALOG pc
    WHERE pc.POLICY_TYPE = p.POLICY_TYPE
      AND pc.PLAN_TIER = p.PLAN_TIER
      AND pc.ACTIVE_FLAG = TRUE
    LIMIT 1
);
```

This is optional because the dimension joins (POLICY_TYPE + PLAN_TIER) already work without it, but a direct FK makes queries cleaner and agent-generated SQL more accurate.

---

## Step-by-Step Implementation Plan

### Phase 1: New Data Infrastructure

#### Step 1.1: Create Product Catalog and Competitor Pricing Tables

```sql
-- ==========================================================================
-- Run as: ACCOUNTADMIN
-- ==========================================================================
USE ROLE ACCOUNTADMIN;
USE DATABASE INSURANCE_AI_HUB;
USE SCHEMA ANALYTICS;

-- Product catalog with coverage features and base pricing
CREATE TABLE IF NOT EXISTS PRODUCT_CATALOG (
    PRODUCT_ID          VARCHAR(20)     PRIMARY KEY,
    PRODUCT_NAME        VARCHAR(100),
    POLICY_TYPE         VARCHAR(20),        -- Health, Auto, Life, Home
    PLAN_TIER           VARCHAR(20),        -- Bronze, Silver, Gold, Platinum
    BASE_PREMIUM        DECIMAL(12,2),
    MIN_COVERAGE        DECIMAL(14,2),
    MAX_COVERAGE        DECIMAL(14,2),
    DEFAULT_DEDUCTIBLE  DECIMAL(10,2),
    FEATURES            VARIANT,            -- JSON array of included features
    ELIGIBILITY_RULES   VARIANT,            -- JSON: min_age, max_age, min_credit_score, etc.
    TARGET_SEGMENT      VARCHAR(30),        -- Individual, Family, Corporate, Senior
    TARGET_RISK_TIER    VARCHAR(20),        -- Low, Medium, High, Very High
    COMMISSION_PCT      FLOAT,
    ACTIVE_FLAG         BOOLEAN             DEFAULT TRUE,
    EFFECTIVE_DATE      DATE,
    EXPIRY_DATE         DATE,
    CREATED_AT          TIMESTAMP_NTZ       DEFAULT CURRENT_TIMESTAMP()
) WITH TAG (INSURANCE_AI_HUB.ANALYTICS.BUSINESS_DOMAIN='POLICY');

-- Competitor pricing benchmarks (populated from market research / external feeds)
CREATE TABLE IF NOT EXISTS COMPETITOR_PRICING (
    BENCHMARK_ID        VARCHAR(20)     PRIMARY KEY,
    COMPETITOR_NAME     VARCHAR(100),
    POLICY_TYPE         VARCHAR(20),
    PLAN_TIER           VARCHAR(20),
    REGION              VARCHAR(50),
    AVG_PREMIUM         DECIMAL(12,2),
    MIN_PREMIUM         DECIMAL(12,2),
    MAX_PREMIUM         DECIMAL(12,2),
    AVG_COVERAGE        DECIMAL(14,2),
    AVG_DEDUCTIBLE      DECIMAL(10,2),
    MARKET_SHARE_PCT    FLOAT,
    CUSTOMER_RATING     FLOAT,              -- 1-5 scale
    DATA_SOURCE         VARCHAR(100),
    SNAPSHOT_DATE       DATE,
    CREATED_AT          TIMESTAMP_NTZ       DEFAULT CURRENT_TIMESTAMP()
);

-- Market intelligence / industry trends
CREATE TABLE IF NOT EXISTS MARKET_TRENDS (
    TREND_ID            VARCHAR(20)     PRIMARY KEY,
    TREND_DATE          DATE,
    REGION              VARCHAR(50),
    POLICY_TYPE         VARCHAR(20),
    METRIC_NAME         VARCHAR(50),        -- e.g., 'avg_industry_premium', 'loss_ratio_benchmark',
                                            -- 'new_policy_volume', 'regulatory_change', 'claim_frequency'
    METRIC_VALUE        FLOAT,
    METRIC_UNIT         VARCHAR(20),
    YOY_CHANGE_PCT      FLOAT,
    TREND_DIRECTION     VARCHAR(10),        -- UP, DOWN, STABLE
    SOURCE              VARCHAR(100),
    NOTES               TEXT,
    CREATED_AT          TIMESTAMP_NTZ       DEFAULT CURRENT_TIMESTAMP()
);

-- Customer-product match scores (output of matching procedures)
CREATE TABLE IF NOT EXISTS PRODUCT_MATCH_SCORES (
    MATCH_ID            VARCHAR(36)     PRIMARY KEY DEFAULT UUID_STRING(),
    CUSTOMER_ID         VARCHAR(20),
    PRODUCT_ID          VARCHAR(20),
    MATCH_STRATEGY      VARCHAR(30),        -- 'rule_based', 'similarity', 'ai_scored'
    MATCH_SCORE         FLOAT,              -- 0-1 normalized
    MATCH_RANK          INT,
    CONTRIBUTING_FACTORS VARIANT,           -- JSON array of factor names and weights
    PRICE_VS_MARKET     FLOAT,              -- our price / market avg (< 1 = cheaper)
    RECOMMENDED_PREMIUM DECIMAL(12,2),
    CONFIDENCE          FLOAT,
    CREATED_AT          TIMESTAMP_NTZ       DEFAULT CURRENT_TIMESTAMP()
);

-- Price optimization scenarios
CREATE TABLE IF NOT EXISTS PRICING_SCENARIOS (
    SCENARIO_ID         VARCHAR(20)     PRIMARY KEY,
    POLICY_TYPE         VARCHAR(20),
    PLAN_TIER           VARCHAR(20),
    REGION              VARCHAR(50),
    CURRENT_PREMIUM     DECIMAL(12,2),
    PROPOSED_PREMIUM    DECIMAL(12,2),
    MARKET_AVG_PREMIUM  DECIMAL(12,2),
    PRICE_POSITION      VARCHAR(20),        -- 'below_market', 'at_market', 'above_market'
    PROJECTED_RETENTION_PCT FLOAT,
    PROJECTED_NEW_BUSINESS  INT,
    REVENUE_IMPACT      DECIMAL(14,2),
    LOSS_RATIO_IMPACT   FLOAT,
    RECOMMENDATION      VARCHAR(200),
    SCENARIO_DATE       DATE,
    CREATED_AT          TIMESTAMP_NTZ       DEFAULT CURRENT_TIMESTAMP()
);
```

#### Step 1.2: Seed the New Tables with Sample Data

Create a new SQL file `sql/10_extended_seed_data.sql` with INSERT statements to populate:

- **PRODUCT_CATALOG:** ~20 products (5 per policy type x 4 tiers)
- **COMPETITOR_PRICING:** ~60 rows (3 competitors x 4 types x 5 regions)
- **MARKET_TRENDS:** ~80 rows (monthly data for 4 policy types x 5 regions x 4 months)
- **PRODUCT_MATCH_SCORES:** ~200 rows (pre-computed matches for a subset of customers)
- **PRICING_SCENARIOS:** ~40 rows (optimization scenarios for current portfolio)

Seed data should be realistic. Example for PRODUCT_CATALOG:
```sql
INSERT INTO PRODUCT_CATALOG (PRODUCT_ID, PRODUCT_NAME, POLICY_TYPE, PLAN_TIER,
  BASE_PREMIUM, MIN_COVERAGE, MAX_COVERAGE, DEFAULT_DEDUCTIBLE,
  FEATURES, ELIGIBILITY_RULES, TARGET_SEGMENT, TARGET_RISK_TIER,
  COMMISSION_PCT, ACTIVE_FLAG, EFFECTIVE_DATE, EXPIRY_DATE)
VALUES
('PROD-001', 'Health Essential', 'Health', 'Bronze', 450.00, 50000, 250000, 2500,
  '["Hospitalization","Outpatient","Generic Rx"]'::VARIANT,
  '{"min_age":18,"max_age":65,"min_credit_score":580}'::VARIANT,
  'Individual', 'Low', 8.5, TRUE, '2025-01-01', '2025-12-31'),
-- ... more rows for each type/tier combination
;
```

Example for COMPETITOR_PRICING:
```sql
INSERT INTO COMPETITOR_PRICING VALUES
('BM-001', 'AllState National', 'Health', 'Bronze', 'Northeast', 480.00, 420.00, 550.00,
  200000, 2000, 22.5, 3.8, 'Industry Report Q1 2025', '2025-01-15'),
('BM-002', 'Guardian Shield', 'Health', 'Bronze', 'Northeast', 510.00, 450.00, 580.00,
  220000, 2200, 18.3, 4.1, 'Industry Report Q1 2025', '2025-01-15'),
-- ... more rows
;
```

Example for MARKET_TRENDS:
```sql
INSERT INTO MARKET_TRENDS VALUES
('MT-001', '2025-01-01', 'Northeast', 'Health', 'avg_industry_premium', 520.00, 'USD', 4.2, 'UP',
  'NAIC Market Report', NULL),
('MT-002', '2025-01-01', 'Northeast', 'Health', 'claim_frequency', 0.18, 'ratio', -1.5, 'DOWN',
  'NAIC Market Report', 'Slight decrease in claim frequency'),
-- ... more rows
;
```

---

### Phase 2: New Stored Procedures

#### Step 2.1: Product Matching Procedure (Multi-Strategy)

```sql
CREATE OR REPLACE PROCEDURE ANALYTICS.SP_PRODUCT_MATCH(
    P_CUSTOMER_ID VARCHAR,
    P_POLICY_TYPE VARCHAR DEFAULT NULL,
    P_STRATEGY VARCHAR DEFAULT 'all'  -- 'rule_based', 'similarity', 'ai_scored', 'all'
)
RETURNS VARIANT
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
    -- Strategy 1: Rule-based matching
    -- Matches products to customers based on eligibility rules (age, credit score,
    -- segment, risk tier). Score = weighted sum of matching criteria.

    -- Strategy 2: Similarity-based matching
    -- Compares customer profile (risk_tier, credit_score, segment, state) to the
    -- target profile of each product. Uses normalized distance scoring.

    -- Strategy 3: AI-scored (using Cortex COMPLETE for reasoning)
    -- Calls SNOWFLAKE.CORTEX.COMPLETE() with customer profile + product features
    -- as context, asks the LLM to score fit on 0-1 scale with reasoning.

    -- Combine: For 'all' strategy, average the 3 scores with weights:
    --   rule_based: 0.4, similarity: 0.35, ai_scored: 0.25

    -- Return: VARIANT with customer_id, array of ranked products with scores,
    --   contributing factors per strategy, and recommended product.
END;
$$;
```

Implementation notes:
- Rule-based: Use CASE expressions to score each eligibility criterion (age range, credit score threshold, segment match, risk tier match). Normalize to 0-1.
- Similarity: Calculate Euclidean distance or cosine similarity between customer feature vector and product target vector using Snowflake numeric functions.
- AI-scored: Use `SNOWFLAKE.CORTEX.COMPLETE('claude-3-5-sonnet', prompt)` where the prompt includes a structured description of the customer and product, asking for a JSON response with score and reasoning.
- The procedure should INSERT results into `PRODUCT_MATCH_SCORES` and RETURN the top-N matches.

#### Step 2.2: Price Optimization Procedure

```sql
CREATE OR REPLACE PROCEDURE ANALYTICS.SP_PRICE_OPTIMIZER(
    P_POLICY_TYPE VARCHAR,
    P_PLAN_TIER VARCHAR DEFAULT NULL,
    P_REGION VARCHAR DEFAULT NULL
)
RETURNS VARIANT
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
    -- 1. Fetch current internal pricing (avg premium from POLICIES where Active)
    -- 2. Fetch competitor benchmarks from COMPETITOR_PRICING
    -- 3. Fetch market trends from MARKET_TRENDS
    -- 4. Calculate price position: our_avg / market_avg
    -- 5. Estimate retention impact using AT_RISK_POLICIES churn data
    -- 6. Generate pricing scenarios:
    --    a) "Match market" — set premium to market avg
    --    b) "Undercut 5%" — set premium to market avg * 0.95
    --    c) "Premium position" — set premium to market avg * 1.10
    --    d) "Retention optimized" — minimize churn via price-churn regression
    -- 7. For each scenario, project:
    --    - revenue impact = (new_premium - current_premium) * active_policy_count
    --    - retention impact = estimated churn change
    --    - loss ratio impact = (market_loss_ratio trend direction)
    -- 8. INSERT scenarios into PRICING_SCENARIOS
    -- 9. RETURN VARIANT with all scenarios + recommendation

    -- Use SNOWFLAKE.CORTEX.COMPLETE() for the final recommendation narrative:
    -- "Given these scenarios, which is optimal and why?"
END;
$$;
```

#### Step 2.3: Enhanced Trend Detection with Cortex ML

```sql
-- Forecast future claims using Snowflake ML FORECAST
CREATE OR REPLACE PROCEDURE ANALYTICS.SP_MARKET_FORECAST(
    P_METRIC VARCHAR,       -- 'claims_amount', 'premium_revenue', 'loss_ratio'
    P_POLICY_TYPE VARCHAR DEFAULT NULL,
    P_FORECAST_DAYS INT DEFAULT 90
)
RETURNS VARIANT
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
    -- 1. Prepare time series data from CLAIMS/POLICIES (weekly aggregates)
    -- 2. Call SNOWFLAKE.ML.FORECAST on the time series
    -- 3. Call SNOWFLAKE.ML.ANOMALY_DETECTION on the same series to flag outliers
    -- 4. Join with MARKET_TRENDS data for context (industry benchmarks)
    -- 5. Call SNOWFLAKE.ML.TOP_INSIGHTS to identify contributing factors
    -- 6. RETURN VARIANT with:
    --    - historical data points
    --    - forecast data points with confidence intervals
    --    - detected anomalies with timestamps
    --    - top contributing factors
    --    - market context (how our trend compares to industry)
END;
$$;
```

Implementation note: `SNOWFLAKE.ML.FORECAST` requires creating a model first:
```sql
CREATE SNOWFLAKE.ML.FORECAST claims_forecast_model(
    INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'weekly_claims_ts'),
    TIMESTAMP_COLNAME => 'WEEK_START',
    TARGET_COLNAME => 'TOTAL_CLAIMS'
);
```

---

### Phase 3: New Analytical Views

#### Step 3.1: Competitive Pricing View

```sql
CREATE OR REPLACE VIEW ANALYTICS.VW_COMPETITIVE_PRICING AS
SELECT
    p.POLICY_TYPE,
    p.PLAN_TIER,
    a.REGION,
    COUNT(DISTINCT p.POLICY_ID) AS our_policy_count,
    AVG(p.PREMIUM_AMOUNT) AS our_avg_premium,
    MIN(p.PREMIUM_AMOUNT) AS our_min_premium,
    MAX(p.PREMIUM_AMOUNT) AS our_max_premium,
    AVG(p.LOSS_RATIO) AS our_avg_loss_ratio,
    cp.COMPETITOR_NAME,
    cp.AVG_PREMIUM AS competitor_avg_premium,
    cp.MARKET_SHARE_PCT AS competitor_market_share,
    cp.CUSTOMER_RATING AS competitor_rating,
    ROUND(AVG(p.PREMIUM_AMOUNT) / NULLIF(cp.AVG_PREMIUM, 0), 3) AS price_ratio,
    CASE
        WHEN AVG(p.PREMIUM_AMOUNT) < cp.AVG_PREMIUM * 0.95 THEN 'Below Market'
        WHEN AVG(p.PREMIUM_AMOUNT) > cp.AVG_PREMIUM * 1.05 THEN 'Above Market'
        ELSE 'At Market'
    END AS price_position
FROM INSURANCE_AI_HUB.ANALYTICS.POLICIES p
LEFT JOIN INSURANCE_AI_HUB.ANALYTICS.AGENTS a ON p.AGENT_ID = a.AGENT_ID
LEFT JOIN INSURANCE_AI_HUB.ANALYTICS.COMPETITOR_PRICING cp
    ON p.POLICY_TYPE = cp.POLICY_TYPE
    AND p.PLAN_TIER = cp.PLAN_TIER
    AND a.REGION = cp.REGION
WHERE p.POLICY_STATUS = 'Active'
GROUP BY p.POLICY_TYPE, p.PLAN_TIER, a.REGION,
         cp.COMPETITOR_NAME, cp.AVG_PREMIUM, cp.MARKET_SHARE_PCT, cp.CUSTOMER_RATING;
```

#### Step 3.2: Product Match Accuracy View

```sql
CREATE OR REPLACE VIEW ANALYTICS.VW_MATCH_ACCURACY AS
SELECT
    ms.MATCH_STRATEGY,
    COUNT(*) AS total_matches,
    AVG(ms.MATCH_SCORE) AS avg_match_score,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ms.MATCH_SCORE) AS median_match_score,
    COUNT(CASE WHEN ms.MATCH_SCORE >= 0.8 THEN 1 END) AS high_confidence_matches,
    COUNT(CASE WHEN ms.MATCH_SCORE >= 0.6 AND ms.MATCH_SCORE < 0.8 THEN 1 END) AS medium_confidence,
    COUNT(CASE WHEN ms.MATCH_SCORE < 0.6 THEN 1 END) AS low_confidence_matches,
    AVG(ms.PRICE_VS_MARKET) AS avg_price_vs_market,
    AVG(ms.CONFIDENCE) AS avg_confidence
FROM INSURANCE_AI_HUB.ANALYTICS.PRODUCT_MATCH_SCORES ms
GROUP BY ms.MATCH_STRATEGY;
```

#### Step 3.3: Market Trend Analysis View

```sql
CREATE OR REPLACE VIEW ANALYTICS.VW_MARKET_ANALYSIS AS
SELECT
    mt.TREND_DATE,
    mt.REGION,
    mt.POLICY_TYPE,
    mt.METRIC_NAME,
    mt.METRIC_VALUE,
    mt.YOY_CHANGE_PCT,
    mt.TREND_DIRECTION,
    -- Internal comparison
    internal.our_avg_premium,
    internal.our_policy_count,
    internal.our_avg_loss_ratio,
    -- Market position
    CASE
        WHEN mt.METRIC_NAME = 'avg_industry_premium' AND internal.our_avg_premium IS NOT NULL
        THEN ROUND(internal.our_avg_premium / NULLIF(mt.METRIC_VALUE, 0), 3)
    END AS our_vs_market_ratio
FROM INSURANCE_AI_HUB.ANALYTICS.MARKET_TRENDS mt
LEFT JOIN (
    SELECT POLICY_TYPE,
           AVG(PREMIUM_AMOUNT) AS our_avg_premium,
           COUNT(*) AS our_policy_count,
           AVG(LOSS_RATIO) AS our_avg_loss_ratio
    FROM INSURANCE_AI_HUB.ANALYTICS.POLICIES
    WHERE POLICY_STATUS = 'Active'
    GROUP BY POLICY_TYPE
) internal ON mt.POLICY_TYPE = internal.POLICY_TYPE;
```

---

### Phase 4: New Semantic Views

#### Step 4.1: Competitive Intelligence Semantic View

Create a new semantic view `SV_COMPETITIVE_INTEL` in the ANALYTICS schema that covers:

- **Tables:** PRODUCT_CATALOG, COMPETITOR_PRICING, PRICING_SCENARIOS, POLICIES, AT_RISK_POLICIES
- **Relationships:** POLICIES→PRODUCT_CATALOG (via POLICY_TYPE+PLAN_TIER), PRICING_SCENARIOS→COMPETITOR_PRICING (via type+tier+region)
- **Facts:** BASE_PREMIUM, AVG_PREMIUM, MIN_PREMIUM, MAX_PREMIUM, MARKET_SHARE_PCT, CUSTOMER_RATING, PROPOSED_PREMIUM, PROJECTED_RETENTION_PCT, REVENUE_IMPACT
- **VQRs to include (at minimum):**
  1. "How does our pricing compare to competitors by policy type?"
  2. "Which regions are we priced above market?"
  3. "What are the pricing optimization scenarios for Health insurance?"
  4. "Which competitors have the highest market share in each region?"
  5. "What is the revenue impact of matching market pricing?"

#### Step 4.2: Market Intelligence Semantic View

Create `SV_MARKET_INTELLIGENCE` in the ANALYTICS schema:

- **Tables:** MARKET_TRENDS, POLICIES, CLAIMS, COMPETITOR_PRICING
- **Relationships:** Join on POLICY_TYPE+REGION
- **Facts:** METRIC_VALUE, YOY_CHANGE_PCT, PREMIUM_AMOUNT, CLAIM_AMOUNT, AVG_PREMIUM
- **VQRs:**
  1. "What are the key market trends for Health insurance?"
  2. "How has claim frequency changed year-over-year by region?"
  3. "Which policy types are seeing the fastest premium growth in the market?"
  4. "How do our loss ratios compare to industry benchmarks?"
  5. "What regulatory changes are affecting the insurance market?"

#### Step 4.3: Product Matching Semantic View

Create `SV_PRODUCT_MATCHING` in the ANALYTICS schema:

- **Tables:** PRODUCT_MATCH_SCORES, PRODUCT_CATALOG, CUSTOMERS, POLICIES
- **Relationships:** PRODUCT_MATCH_SCORES→CUSTOMERS (CUSTOMER_ID), PRODUCT_MATCH_SCORES→PRODUCT_CATALOG (PRODUCT_ID)
- **Facts:** MATCH_SCORE, CONFIDENCE, PRICE_VS_MARKET, RECOMMENDED_PREMIUM, BASE_PREMIUM
- **VQRs:**
  1. "Which products are the best match for high-risk customers?"
  2. "What is the match accuracy breakdown by strategy?"
  3. "Which customers have no high-confidence product matches?"
  4. "What is the average match score by customer segment?"
  5. "Show me the top product recommendations for Corporate segment customers"

---

### Phase 5: New Cortex Agents

#### Step 5.1: Product Matching Agent

```sql
CREATE OR REPLACE AGENT INSURANCE_AI_HUB.ANALYTICS.PRODUCT_MATCHING_AGENT
  COMMENT = 'Product matching agent with multi-strategy recommendation engine'
  PROFILE = '{"display_name": "Product Matcher", "avatar": "target-icon.png", "color": "blue"}'
  FROM SPECIFICATION
  $$
  models:
    orchestration: auto

  instructions:
    system: >
      You are the Product Matching Assistant for insurance operations.
      You help underwriters and sales agents find the best product-customer
      matches using multiple scoring strategies: rule-based eligibility,
      similarity scoring, and AI-powered assessment.
    orchestration: >
      ROUTING RULES:
      - For questions about product recommendations, match scores, or
        customer-product fit, use the product_matching_analyst tool.
      - For questions about customer profiles, risk tiers, or segments,
        use the customer_analyst tool.
      - For questions about product features, coverage details, or
        eligibility rules, use the product_search tool.
      - Always explain which matching strategy contributed most to a
        recommendation and cite the match score.
    response: >
      Always include the match strategy used, the confidence score, and
      the contributing factors in your response. When recommending products,
      show how the customer profile aligns with product eligibility rules.
      Compare recommended premium to market average when data is available.
    sample_questions:
      - question: "What products are the best match for customer CUST-00042?"
      - question: "Which matching strategy performs best for high-risk customers?"
      - question: "Show me the top 5 product recommendations for Corporate segment"
      - question: "What is the match accuracy across all strategies?"

  tools:
    - tool_spec:
        type: cortex_analyst_text_to_sql
        name: product_matching_analyst
        description: >
          Answers questions about product-customer match scores, matching
          strategies, recommendations, and match accuracy metrics.
    - tool_spec:
        type: cortex_analyst_text_to_sql
        name: customer_analyst
        description: >
          Answers questions about customer profiles, risk tiers, segments,
          credit scores, and policy history for matching context.
    - tool_spec:
        type: cortex_search
        name: product_search
        description: >
          Searches product catalog features, eligibility rules, and
          coverage details for product comparison and recommendation.

  tool_resources:
    product_matching_analyst:
      semantic_view: INSURANCE_AI_HUB.ANALYTICS.SV_PRODUCT_MATCHING
      execution_environment:
        type: warehouse
        warehouse: COMPUTE_WH
    customer_analyst:
      semantic_view: INSURANCE_AI_HUB.ANALYTICS.SV_INSURANCE_OPS
      execution_environment:
        type: warehouse
        warehouse: COMPUTE_WH
    product_search:
      search_service: INSURANCE_AI_HUB.DOCUMENTS.CORTEX_SEARCH_SVC
      max_results: 5
      title_column: SECTION_TITLE
      id_column: CHUNK_ID
  $$;
```

Note: The `product_search` tool above reuses the existing document search. To make this more effective, you should create a **separate Cortex Search Service** over `PRODUCT_CATALOG` data — chunking the FEATURES and ELIGIBILITY_RULES JSON into searchable text. Alternatively, create a `PRODUCT_CHUNKS` table similar to `DOCUMENT_CHUNKS` and a new Cortex Search service `PRODUCT_SEARCH_SVC`.

#### Step 5.2: Price Optimization Agent

```sql
CREATE OR REPLACE AGENT INSURANCE_AI_HUB.ANALYTICS.PRICE_OPTIMIZATION_AGENT
  COMMENT = 'Price optimization agent for competitive analysis and pricing strategy'
  PROFILE = '{"display_name": "Pricing Advisor", "avatar": "chart-icon.png", "color": "green"}'
  FROM SPECIFICATION
  $$
  models:
    orchestration: auto

  instructions:
    system: >
      You are the Pricing Optimization Assistant. You help actuaries, pricing
      managers, and executives analyze competitive positioning, optimize
      premium pricing, and evaluate pricing scenarios against market benchmarks.
    orchestration: >
      ROUTING RULES:
      - For questions about competitor pricing, market position, or price
        comparison, use the competitive_intel_analyst tool.
      - For questions about internal policies, premiums, and loss ratios,
        use the portfolio_analyst tool.
      - For questions about pricing scenarios and revenue projections,
        use the competitive_intel_analyst tool.
    response: >
      Always show the price ratio (our price / market avg) when discussing
      competitive positioning. Include competitor names and market share when
      available. For pricing recommendations, show projected revenue impact
      and retention impact side by side.
    sample_questions:
      - question: "How does our Health insurance pricing compare to competitors?"
      - question: "Which regions are we most overpriced in?"
      - question: "What is the revenue impact of matching market pricing for Auto?"
      - question: "Show me pricing scenarios for Gold tier Home insurance"

  tools:
    - tool_spec:
        type: cortex_analyst_text_to_sql
        name: competitive_intel_analyst
        description: >
          Answers questions about competitor pricing, market positioning,
          pricing scenarios, revenue impact projections, and market share.
    - tool_spec:
        type: cortex_analyst_text_to_sql
        name: portfolio_analyst
        description: >
          Answers questions about the internal policy portfolio, premium
          amounts, loss ratios, and active policy distribution.

  tool_resources:
    competitive_intel_analyst:
      semantic_view: INSURANCE_AI_HUB.ANALYTICS.SV_COMPETITIVE_INTEL
      execution_environment:
        type: warehouse
        warehouse: COMPUTE_WH
    portfolio_analyst:
      semantic_view: INSURANCE_AI_HUB.ANALYTICS.SV_INSURANCE_OPS
      execution_environment:
        type: warehouse
        warehouse: COMPUTE_WH
  $$;
```

#### Step 5.3: Market Intelligence Agent

```sql
CREATE OR REPLACE AGENT INSURANCE_AI_HUB.ANALYTICS.MARKET_INTELLIGENCE_AGENT
  COMMENT = 'Market intelligence agent for trend detection and forecasting'
  PROFILE = '{"display_name": "Market Intel", "avatar": "globe-icon.png", "color": "purple"}'
  FROM SPECIFICATION
  $$
  models:
    orchestration: auto

  instructions:
    system: >
      You are the Market Intelligence Assistant. You help executives and
      strategists understand market trends, detect anomalies in performance
      data, forecast future metrics, and benchmark against industry standards.
    orchestration: >
      ROUTING RULES:
      - For questions about market trends, industry benchmarks, or
        year-over-year changes, use the market_analyst tool.
      - For questions about internal claims, premium, or performance
        trends, use the operations_analyst tool.
      - For forecasting and predictive questions, use the operations_analyst
        tool and note that ML forecasting procedures are available.
    response: >
      Always include the trend direction and YoY change when discussing
      market metrics. Compare internal performance to industry benchmarks
      when possible. Flag anomalies and explain potential drivers.
      When showing trends, include both the data and the interpretation.
    sample_questions:
      - question: "What are the key market trends for Auto insurance this quarter?"
      - question: "How do our loss ratios compare to industry averages?"
      - question: "Which regions are seeing the fastest premium growth?"
      - question: "Are there any anomalies in our claims data?"

  tools:
    - tool_spec:
        type: cortex_analyst_text_to_sql
        name: market_analyst
        description: >
          Answers questions about market trends, industry benchmarks,
          competitive landscape, year-over-year changes, and regional
          market conditions.
    - tool_spec:
        type: cortex_analyst_text_to_sql
        name: operations_analyst
        description: >
          Answers questions about internal insurance operations including
          claims, policies, premiums, loss ratios, and portfolio performance.
    - tool_spec:
        type: data_to_chart
        name: data_to_chart
        description: >
          Generates visualizations from data returned by other tools.

  tool_resources:
    market_analyst:
      semantic_view: INSURANCE_AI_HUB.ANALYTICS.SV_MARKET_INTELLIGENCE
      execution_environment:
        type: warehouse
        warehouse: COMPUTE_WH
    operations_analyst:
      semantic_view: INSURANCE_AI_HUB.ANALYTICS.SV_INSURANCE_OPS
      execution_environment:
        type: warehouse
        warehouse: COMPUTE_WH
  $$;
```

---

### Phase 6: Create Unified Enterprise Agent (NEW — does NOT replace existing)

The original `INSURANCE_INTELLIGENCE_AGENT` (3 tools) stays untouched and continues working for all current users and the React dashboard. This phase creates a **new, separate agent** that combines everything: the original 3 tools + 3 new semantic view tools + data_to_chart + analytical_search.

**Why a new agent instead of updating:**
- The React dashboard's `cortex-agent.ts` service hardcodes calls to `INSURANCE_INTELLIGENCE_AGENT` — changing it would break the existing app.
- Business users currently relying on the original agent see no disruption.
- You can A/B test: point some users at the original (3-tool) agent and others at the unified (7-tool) agent.
- If anything goes wrong with the new semantic views, the original agent is unaffected.

**Agent comparison:**

| Attribute | INSURANCE_INTELLIGENCE_AGENT (existing) | UNIFIED_ENTERPRISE_AGENT (new) |
|---|---|---|
| Tools | 3 (ops analyst, DQ analyst, doc search) | 7 (all 3 original + competitive intel, market intel, product matching, data_to_chart) |
| Semantic Views | SV_INSURANCE_OPS, SV_DATA_QUALITY | All 5: + SV_COMPETITIVE_INTEL, SV_MARKET_INTELLIGENCE, SV_PRODUCT_MATCHING |
| Cortex Search | CORTEX_SEARCH_SVC | CORTEX_SEARCH_SVC (same) |
| Analytical Search | No | Yes |
| Data-to-Chart | No | Yes |
| CoWork Profile | No | Yes (display_name, avatar, color) |
| Used by React Dashboard | Yes | No (unless dashboard is updated later) |
| Used by CoWork | Can be | Primary agent for CoWork |

#### Step 6.1: Create UNIFIED_ENTERPRISE_AGENT

```sql
CREATE OR REPLACE AGENT INSURANCE_AI_HUB.ANALYTICS.UNIFIED_ENTERPRISE_AGENT
  COMMENT = 'Unified Enterprise Agent — combines all insurance intelligence capabilities (ops, DQ, documents, competitive pricing, market trends, product matching) into a single 7-tool agent. Does NOT replace INSURANCE_INTELLIGENCE_AGENT.'
  PROFILE = '{"display_name": "Insurance Enterprise Hub", "avatar": "shield-icon.png", "color": "blue"}'
  FROM SPECIFICATION
  $$
  models:
    orchestration: auto

  orchestration:
    capabilities:
      analytical_search: true

  instructions:
    system: >
      You are the Unified Enterprise Insurance Agent, the most comprehensive
      AI advisor in the Insurance AI Hub. You combine six specialized
      analytical domains — operations, data quality, policy documents,
      competitive pricing, market intelligence, and product matching — into
      a single conversational interface. You help executives, claims managers,
      underwriters, fraud investigators, pricing analysts, and data stewards
      make data-driven decisions across the entire insurance value chain.
    orchestration: >
      ROUTING RULES:
      - Customers, policies, claims, billing, premiums, risk, agents, KPIs
        → insurance_operations_analyst
      - Data quality, DQ scores, failed rules, column health
        → data_quality_analyst
      - Policy coverage, exclusions, benefits, procedures
        → policy_document_search
      - Competitor pricing, market position, pricing scenarios
        → competitive_intel_analyst
      - Market trends, industry benchmarks, forecasting
        → market_intelligence_analyst
      - Product recommendations, matching scores, customer-product fit
        → product_matching_analyst
      - When the user asks for a chart or visualization, ALWAYS use
        data_to_chart after retrieving the data.
      - For cross-domain questions, decompose and use multiple tools.
    response: >
      Always ground answers in data from tool results.
      Include source citations for every factual claim.
      For document answers, cite document ID and section.
      For analytics answers, show the underlying metric and filters used.
      For pricing analysis, always show price ratio vs market.
      Never fabricate data or statistics not returned by tools.
      When uncertain, say so clearly.
    sample_questions:
      - question: "What is the total premium revenue by policy type?"
      - question: "How does our pricing compare to competitors for Health insurance?"
      - question: "What are the key market trends this quarter?"
      - question: "Which products best match our high-risk customers?"
      - question: "What does the health policy say about pre-existing conditions?"
      - question: "Which tables have the lowest data quality scores?"
      - question: "Show me a chart of revenue at risk by category"
      - question: "Compare our loss ratios to industry benchmarks by region"

  tools:
    - tool_spec:
        type: cortex_analyst_text_to_sql
        name: insurance_operations_analyst
        description: >
          Answers questions about insurance customers, policies, claims,
          billing, agents, and at-risk policies using structured data.
    - tool_spec:
        type: cortex_analyst_text_to_sql
        name: data_quality_analyst
        description: >
          Answers questions about data quality rules, execution results,
          table-level scores, column health, and score trends.
    - tool_spec:
        type: cortex_search
        name: policy_document_search
        description: >
          Searches policy documents, coverage summaries, exclusion clauses,
          and claims procedures.
    - tool_spec:
        type: cortex_analyst_text_to_sql
        name: competitive_intel_analyst
        description: >
          Answers questions about competitor pricing, market positioning,
          pricing scenarios, and revenue impact projections.
    - tool_spec:
        type: cortex_analyst_text_to_sql
        name: market_intelligence_analyst
        description: >
          Answers questions about market trends, industry benchmarks,
          year-over-year changes, and regional market conditions.
    - tool_spec:
        type: cortex_analyst_text_to_sql
        name: product_matching_analyst
        description: >
          Answers questions about product-customer match scores, matching
          strategies, and recommendation accuracy.
    - tool_spec:
        type: data_to_chart
        name: data_to_chart
        description: >
          Generates visualizations from data returned by other tools.

  tool_resources:
    insurance_operations_analyst:
      semantic_view: INSURANCE_AI_HUB.ANALYTICS.SV_INSURANCE_OPS
      execution_environment:
        type: warehouse
        warehouse: COMPUTE_WH
    data_quality_analyst:
      semantic_view: INSURANCE_AI_HUB.DATA_QUALITY.SV_DATA_QUALITY
      execution_environment:
        type: warehouse
        warehouse: COMPUTE_WH
    policy_document_search:
      search_service: INSURANCE_AI_HUB.DOCUMENTS.CORTEX_SEARCH_SVC
      max_results: 5
      title_column: SECTION_TITLE
      id_column: CHUNK_ID
    competitive_intel_analyst:
      semantic_view: INSURANCE_AI_HUB.ANALYTICS.SV_COMPETITIVE_INTEL
      execution_environment:
        type: warehouse
        warehouse: COMPUTE_WH
    market_intelligence_analyst:
      semantic_view: INSURANCE_AI_HUB.ANALYTICS.SV_MARKET_INTELLIGENCE
      execution_environment:
        type: warehouse
        warehouse: COMPUTE_WH
    product_matching_analyst:
      semantic_view: INSURANCE_AI_HUB.ANALYTICS.SV_PRODUCT_MATCHING
      execution_environment:
        type: warehouse
        warehouse: COMPUTE_WH
  $$;
```

---

### Phase 7: Snowflake Intelligence (CoWork) Setup

#### Step 7.1: Create Snowflake Intelligence Object

```sql
USE ROLE ACCOUNTADMIN;

-- Create the Snowflake Intelligence object
CREATE SNOWFLAKE INTELLIGENCE IF NOT EXISTS INSURANCE_AI_HUB_COWORK;

-- Grant usage to required roles
GRANT USAGE ON SNOWFLAKE INTELLIGENCE INSURANCE_AI_HUB_COWORK
  TO ROLE ACCOUNTADMIN;
```

#### Step 7.2: Configure Agents for CoWork

After agents are created (Phase 5+6), they automatically appear in:
**Snowsight > AI & ML > Agents**

To make them available in CoWork:
1. Navigate to **AI & ML > Agents** in Snowsight
2. Select `UNIFIED_ENTERPRISE_AGENT` (the primary agent for CoWork)
3. Click **Open settings**
4. Under **Snowflake CoWork**, configure:
   - **Display name:** "Insurance Enterprise Hub"
   - Enable the agent for CoWork users
5. Repeat for the 3 specialized agents (PRODUCT_MATCHING_AGENT, PRICE_OPTIMIZATION_AGENT, MARKET_INTELLIGENCE_AGENT)
6. The original `INSURANCE_INTELLIGENCE_AGENT` can also be enabled in CoWork if desired — it will appear as a separate, simpler agent

#### Step 7.3: Grant CoWork Access to Roles

```sql
-- Grant COPILOT_USER role for CoWork access
GRANT DATABASE ROLE SNOWFLAKE.COPILOT_USER TO ROLE ACCOUNTADMIN;

-- Grant to each business role that needs CoWork access
-- (Adjust role names to match your account roles)
-- GRANT DATABASE ROLE SNOWFLAKE.COPILOT_USER TO ROLE <YOUR_ANALYST_ROLE>;
-- GRANT DATABASE ROLE SNOWFLAKE.COPILOT_USER TO ROLE <YOUR_EXEC_ROLE>;
```

#### Step 7.4: Enable Cross-Region Inference (Recommended)

```sql
-- Enables access to the best available models regardless of region
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';
```

#### Step 7.5: CoWork Dashboards via Agent Capabilities

Snowflake CoWork renders dashboards natively when agents use the `data_to_chart` tool. The following capabilities are automatically available once agents are configured:

| Dashboard Need | CoWork Implementation |
|---|---|
| Competitive pricing dashboard | Ask `UNIFIED_ENTERPRISE_AGENT`: "Show me a chart comparing our pricing to competitors by policy type" — the `data_to_chart` tool generates the visualization inline |
| Market trend analysis | Ask: "Chart the market trend for Health insurance premiums over the last 4 months" |
| Matching accuracy metrics | Ask: "Show me a bar chart of match accuracy by strategy" |

No separate dashboard application is required — CoWork renders charts directly in the conversation. The original `INSURANCE_INTELLIGENCE_AGENT` (without data_to_chart) continues to serve the React dashboard via REST API.

---

### Phase 8: MCP Integration

#### Step 8.1: Identify Applicable MCP Connectors

For the insurance use case, the most applicable MCP integrations are:

| MCP Connector | Use Case | Priority |
|---|---|---|
| **Salesforce** | Pull CRM data for customer context, push product recommendations to sales reps | High (if Salesforce is used) |
| **Atlassian (Jira)** | Create tickets for pricing reviews, flag high-risk matches for underwriter review | Medium |
| **GitHub** | Version-control pricing models, track model changes | Low |
| **Slack** | Send alerts for market trend anomalies, pricing threshold breaches | Medium |
| **Custom MCP** | Connect to external market data APIs (e.g., NAIC, AM Best) | High (if available) |

#### Step 8.2: Set Up Salesforce MCP Connector (Example)

Prerequisites: Salesforce org with MCP API access, OAuth app configured.

```sql
USE ROLE ACCOUNTADMIN;

-- Step 1: Create API Integration for Salesforce
CREATE OR REPLACE API INTEGRATION salesforce_mcp_integration
  API_PROVIDER = external_mcp
  API_ALLOWED_PREFIXES = ('https://api.salesforce.com')
  API_USER_AUTHENTICATION = (
    TYPE = OAUTH,
    OAUTH_CLIENT_ID = '<your_salesforce_client_id>',
    OAUTH_CLIENT_SECRET = '<your_salesforce_client_secret>',
    OAUTH_TOKEN_ENDPOINT = 'https://login.salesforce.com/services/oauth2/token',
    OAUTH_AUTHORIZATION_ENDPOINT = 'https://login.salesforce.com/services/oauth2/authorize',
    OAUTH_ALLOWED_SCOPES = ('mcp_api', 'api', 'refresh_token')
  )
  ENABLED = TRUE;

-- Step 2: Create External MCP Server
CREATE OR REPLACE EXTERNAL MCP SERVER salesforce_mcp
  WITH DISPLAY_NAME = 'Salesforce CRM'
  URL = 'https://api.salesforce.com/platform/mcp/v1/platform/sobject-all'
  API_INTEGRATION = salesforce_mcp_integration;

-- Step 3: Grant access
GRANT USAGE ON EXTERNAL MCP SERVER salesforce_mcp
  TO DATABASE ROLE INSURANCE_AI_HUB.INSURANCE_ADMIN_ROLE;
GRANT USAGE ON INTEGRATION salesforce_mcp_integration
  TO DATABASE ROLE INSURANCE_AI_HUB.INSURANCE_ADMIN_ROLE;
```

#### Step 8.3: Set Up Atlassian (Jira) MCP Connector (Example)

```sql
-- Step 1: Create API Integration for Atlassian
CREATE OR REPLACE API INTEGRATION atlassian_mcp_integration
  API_PROVIDER = external_mcp
  API_ALLOWED_PREFIXES = ('https://mcp.atlassian.com')
  API_USER_AUTHENTICATION = (
    TYPE = OAUTH_DYNAMIC_CLIENT,
    OAUTH_RESOURCE_URL = 'https://mcp.atlassian.com/v1/mcp'
  )
  ENABLED = TRUE;

-- Step 2: Create External MCP Server
CREATE OR REPLACE EXTERNAL MCP SERVER atlassian_mcp
  WITH DISPLAY_NAME = 'Atlassian (Jira & Confluence)'
  URL = 'https://mcp.atlassian.com/v1/mcp'
  API_INTEGRATION = atlassian_mcp_integration;

-- Step 3: Grant access
GRANT USAGE ON EXTERNAL MCP SERVER atlassian_mcp
  TO DATABASE ROLE INSURANCE_AI_HUB.INSURANCE_ADMIN_ROLE;
GRANT USAGE ON INTEGRATION atlassian_mcp_integration
  TO DATABASE ROLE INSURANCE_AI_HUB.INSURANCE_ADMIN_ROLE;
```

#### Step 8.4: Add MCP Connectors to Agent

After MCP servers are created, add them to the unified agent via the Snowsight UI:

1. Navigate to **AI & ML > Agents**
2. Select `UNIFIED_ENTERPRISE_AGENT`
3. Go to the **Tools** tab
4. Under **MCP Connectors**, click **+ Add**
5. Select the configured MCP servers (Salesforce, Atlassian)
6. Click **Save**

Note: The original `INSURANCE_INTELLIGENCE_AGENT` does NOT get MCP connectors — it stays as-is for the React dashboard.

Or add via the agent specification YAML (MCP connectors section).

**Use cases enabled by MCP:**
- "Create a Jira ticket to review pricing for Health Bronze in the Northeast — we're 12% above market"
- "Look up customer CUST-00042 in Salesforce and show their recent interactions"
- "Post a Slack alert that Auto claims in the Southwest are trending 15% above industry average"

---

### Phase 9: RBAC Updates for New Objects

```sql
USE ROLE ACCOUNTADMIN;
USE DATABASE INSURANCE_AI_HUB;

-- Grant SELECT on new tables to ANALYST role (base read access)
GRANT SELECT ON TABLE ANALYTICS.PRODUCT_CATALOG
  TO DATABASE ROLE INSURANCE_AI_HUB.INSURANCE_ANALYST_ROLE;
GRANT SELECT ON TABLE ANALYTICS.COMPETITOR_PRICING
  TO DATABASE ROLE INSURANCE_AI_HUB.INSURANCE_ANALYST_ROLE;
GRANT SELECT ON TABLE ANALYTICS.MARKET_TRENDS
  TO DATABASE ROLE INSURANCE_AI_HUB.INSURANCE_ANALYST_ROLE;
GRANT SELECT ON TABLE ANALYTICS.PRODUCT_MATCH_SCORES
  TO DATABASE ROLE INSURANCE_AI_HUB.INSURANCE_ANALYST_ROLE;
GRANT SELECT ON TABLE ANALYTICS.PRICING_SCENARIOS
  TO DATABASE ROLE INSURANCE_AI_HUB.INSURANCE_ANALYST_ROLE;

-- Grant SELECT on new views
GRANT SELECT ON VIEW ANALYTICS.VW_COMPETITIVE_PRICING
  TO DATABASE ROLE INSURANCE_AI_HUB.INSURANCE_ANALYST_ROLE;
GRANT SELECT ON VIEW ANALYTICS.VW_MATCH_ACCURACY
  TO DATABASE ROLE INSURANCE_AI_HUB.INSURANCE_ANALYST_ROLE;
GRANT SELECT ON VIEW ANALYTICS.VW_MARKET_ANALYSIS
  TO DATABASE ROLE INSURANCE_AI_HUB.INSURANCE_ANALYST_ROLE;

-- Grant USAGE on new semantic views to roles that need agent access
-- (Semantic views inherit table grants, but explicit grants may be needed)

-- Grant USAGE on new agents
-- (Agent access is controlled via the role that owns the agent
-- and the user's default role having access to underlying objects)
```

---

### Phase 10: Verification and Testing

After all phases are complete, run these verification queries:

```sql
-- 1. Verify all new tables exist and have data
SELECT 'PRODUCT_CATALOG' AS tbl, COUNT(*) AS row_count
  FROM INSURANCE_AI_HUB.ANALYTICS.PRODUCT_CATALOG
UNION ALL SELECT 'COMPETITOR_PRICING', COUNT(*)
  FROM INSURANCE_AI_HUB.ANALYTICS.COMPETITOR_PRICING
UNION ALL SELECT 'MARKET_TRENDS', COUNT(*)
  FROM INSURANCE_AI_HUB.ANALYTICS.MARKET_TRENDS
UNION ALL SELECT 'PRODUCT_MATCH_SCORES', COUNT(*)
  FROM INSURANCE_AI_HUB.ANALYTICS.PRODUCT_MATCH_SCORES
UNION ALL SELECT 'PRICING_SCENARIOS', COUNT(*)
  FROM INSURANCE_AI_HUB.ANALYTICS.PRICING_SCENARIOS;

-- 2. Verify new semantic views
SHOW SEMANTIC VIEWS IN DATABASE INSURANCE_AI_HUB;

-- 3. Verify all agents (should show 5: original + 4 new)
SHOW AGENTS IN SCHEMA INSURANCE_AI_HUB.ANALYTICS;
-- Expected:
--   INSURANCE_INTELLIGENCE_AGENT   (original, 3 tools, untouched)
--   PRODUCT_MATCHING_AGENT         (new, Phase 5)
--   PRICE_OPTIMIZATION_AGENT       (new, Phase 5)
--   MARKET_INTELLIGENCE_AGENT      (new, Phase 5)
--   UNIFIED_ENTERPRISE_AGENT       (new, Phase 6, 7 tools)

-- 4. Verify new views
SHOW VIEWS IN SCHEMA INSURANCE_AI_HUB.ANALYTICS;

-- 5. Verify new procedures
SHOW PROCEDURES IN SCHEMA INSURANCE_AI_HUB.ANALYTICS;

-- 6. Verify MCP servers (if configured)
SHOW EXTERNAL MCP SERVERS;

-- 7. Test the UNIFIED_ENTERPRISE_AGENT
-- (Run from CoWork or via REST API targeting UNIFIED_ENTERPRISE_AGENT)
-- "How does our Health insurance pricing compare to competitors?"
-- "What products are best matched for high-risk customers?"
-- "What are the market trends for Auto insurance?"
-- "Show me a chart of premium revenue by policy type"

-- 8. Verify original agent still works (no changes)
-- (Run from React dashboard or via REST API targeting INSURANCE_INTELLIGENCE_AGENT)
-- "What is the total premium revenue by policy type?"
-- "What does the health policy say about pre-existing conditions?"
```

---

## Summary: Objects to Create

| Phase | Object Type | Count | Names |
|-------|-------------|-------|-------|
| 1 | Tables | 5 | PRODUCT_CATALOG, COMPETITOR_PRICING, MARKET_TRENDS, PRODUCT_MATCH_SCORES, PRICING_SCENARIOS |
| 1 | Seed Data | ~400 rows | Across all 5 new tables |
| 2 | Procedures | 3 | SP_PRODUCT_MATCH, SP_PRICE_OPTIMIZER, SP_MARKET_FORECAST |
| 3 | Views | 3 | VW_COMPETITIVE_PRICING, VW_MATCH_ACCURACY, VW_MARKET_ANALYSIS |
| 4 | Semantic Views | 3 | SV_COMPETITIVE_INTEL, SV_MARKET_INTELLIGENCE, SV_PRODUCT_MATCHING |
| 5 | Agents (domain-specific) | 3 | PRODUCT_MATCHING_AGENT, PRICE_OPTIMIZATION_AGENT, MARKET_INTELLIGENCE_AGENT |
| 6 | Agent (unified, NEW) | 1 | **UNIFIED_ENTERPRISE_AGENT** (7 tools + data_to_chart + analytical_search) |
| 7 | CoWork | 1 | INSURANCE_AI_HUB_COWORK Snowflake Intelligence object |
| 8 | MCP | 2-4 | API integrations + external MCP servers (Salesforce, Atlassian, etc.) |
| 9 | RBAC | ~10 | GRANT statements for new objects |

**Existing objects left untouched:** `INSURANCE_INTELLIGENCE_AGENT` (original 3-tool agent), all 13 existing tables, 4 existing views, 2 existing semantic views, 3 existing procedures, all RBAC grants, all masking policies.

**Total new objects:** ~31 (5 tables + 3 procedures + 3 views + 3 semantic views + **4 agents** + MCP + CoWork + RBAC grants)

### Agent Inventory After Deployment

| # | Agent Name | Tools | Purpose | Used By |
|---|---|---|---|---|
| 1 | `INSURANCE_INTELLIGENCE_AGENT` | 3 | Original ops + DQ + docs (unchanged) | React dashboard, CoWork (optional) |
| 2 | `PRODUCT_MATCHING_AGENT` | 3 | Product-customer matching specialist | CoWork |
| 3 | `PRICE_OPTIMIZATION_AGENT` | 2 | Competitive pricing specialist | CoWork |
| 4 | `MARKET_INTELLIGENCE_AGENT` | 3 | Market trends + forecasting specialist | CoWork |
| 5 | `UNIFIED_ENTERPRISE_AGENT` | 7 | All capabilities in one agent | CoWork (primary), MCP-enabled |
