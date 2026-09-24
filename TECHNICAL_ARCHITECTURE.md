# Insurance AI Hub — Technical Architecture Guide

> Deep-dive into implementation patterns, data models, security controls,
> API contracts, and system internals.

---

## 1. Database Object Inventory

### 1.1 Complete Object Map

```
INSURANCE_AI_HUB
│
├── ANALYTICS (Schema)
│   ├── Tables
│   │   ├── AGENTS .................. 20 rows, 11 columns, PK: AGENT_ID
│   │   ├── CUSTOMERS .............. 200 rows, 16 columns, PK: CUSTOMER_ID
│   │   │   └── Masking: EMAIL, PHONE, ADDRESS
│   │   │   └── Tags: PII_LEVEL (column), BUSINESS_DOMAIN (table)
│   │   ├── POLICIES ............... 300 rows, 15 columns, PK: POLICY_ID
│   │   ├── CLAIMS ................. 400 rows, 16 columns, PK: CLAIM_ID
│   │   ├── BILLING ................ 500 rows, 13 columns, PK: BILLING_ID
│   │   ├── AT_RISK_POLICIES ....... 165 rows, 14 columns, PK: RISK_ID
│   │   ├── AGENT_AUDIT_LOG ........ system-generated, 20 columns, PK: LOG_ID (UUID)
│   │   ├── PRODUCT_CATALOG ........ 20 rows, 17 columns, PK: PRODUCT_ID
│   │   ├── COMPETITOR_PRICING ..... 60 rows, 14 columns, PK: BENCHMARK_ID
│   │   ├── MARKET_TRENDS .......... 80 rows, 16 columns, PK: TREND_ID
│   │   ├── PRODUCT_MATCH_SCORES ... 200 rows, 14 columns, PK: MATCH_ID
│   │   └── PRICING_SCENARIOS ...... 40 rows, 16 columns, PK: SCENARIO_ID
│   │
│   ├── Views
│   │   ├── VW_CUSTOMER_360 ........ CUSTOMERS + POLICIES + CLAIMS + BILLING + AT_RISK
│   │   ├── VW_CLAIMS_PERFORMANCE .. CLAIMS + POLICIES + CUSTOMERS + AGENTS
│   │   ├── VW_AT_RISK_PORTFOLIO ... AT_RISK + POLICIES + CUSTOMERS
│   │   ├── VW_COMPETITIVE_PRICING . COMPETITOR_PRICING + POLICIES (aggregated)
│   │   ├── VW_MATCH_ACCURACY ...... MATCH_SCORES + PRODUCT_CATALOG + CUSTOMERS
│   │   └── VW_MARKET_ANALYSIS ..... MARKET_TRENDS (enriched with performance status)
│   │
│   ├── Semantic Views
│   │   ├── SV_INSURANCE_OPS ....... 6 tables, 2 rels, 15 facts, 66 dims, 10 VQRs
│   │   ├── SV_COMPETITIVE_INTEL ... 4 tables, 1 rel, 17 facts, 17 dims, 4 VQRs
│   │   ├── SV_MARKET_INTELLIGENCE . 2 tables, 1 rel, 8 facts, 11 dims, 3 VQRs
│   │   └── SV_PRODUCT_MATCHING .... 3 tables, 2 rels, 8 facts, 18 dims, 3 VQRs
│   │
│   ├── Stored Procedures
│   │   ├── SP_CLAIM_RISK_SCORE(VARCHAR) ......... JavaScript, EXECUTE AS CALLER
│   │   ├── SP_TREND_DETECTOR(VARCHAR,VARCHAR,FLOAT) JavaScript, EXECUTE AS CALLER
│   │   ├── SP_PRODUCT_MATCH(VARCHAR) ............ JavaScript, EXECUTE AS CALLER
│   │   ├── SP_PRICE_OPTIMIZER(VARCHAR,VARCHAR) .. JavaScript, EXECUTE AS CALLER
│   │   └── SP_MARKET_FORECAST(VARCHAR,VARCHAR) .. JavaScript, EXECUTE AS CALLER
│   │
│   ├── Cortex Agents
│   │   ├── INSURANCE_INTELLIGENCE_AGENT ......... 3 tools
│   │   ├── UNIFIED_ENTERPRISE_AGENT ............. 7 tools + chart + MCP
│   │   ├── MARKET_INTELLIGENCE_AGENT ............ 2 tools + chart + MCP
│   │   ├── PRICE_OPTIMIZATION_AGENT ............. 2 tools + MCP
│   │   └── PRODUCT_MATCHING_AGENT ............... 3 tools + MCP
│   │
│   ├── Streams
│   │   └── CLAIMS_STREAM ......... APPEND_ONLY on CLAIMS
│   │
│   ├── Tasks
│   │   ├── TASK_DQ_DAILY_SCORE_REFRESH .......... CRON 0 6 * * * UTC
│   │   └── TASK_FLAG_HIGH_FRAUD_CLAIMS .......... WHEN CLAIMS_STREAM has data
│   │
│   ├── External MCP Server
│   │   └── ATLASSIAN_MCP_SERVER .. Jira + Confluence via DCR OAuth
│   │
│   ├── Tags
│   │   ├── PII_LEVEL ............. HIGH, MEDIUM, LOW, NONE
│   │   └── BUSINESS_DOMAIN ....... CUSTOMER, POLICY, CLAIMS, BILLING, RISK, DOCUMENTS, DATA_QUALITY
│   │
│   └── Masking Policies
│       ├── MASK_EMAIL ............ REGEXP_REPLACE for non-admin
│       ├── MASK_PHONE ............ Full redaction for non-admin
│       └── MASK_ADDRESS .......... Full redaction for non-admin
│
├── DOCUMENTS (Schema)
│   ├── Tables
│   │   ├── POLICY_DOCUMENTS ....... 10 rows, 13 columns, PK: DOCUMENT_ID
│   │   └── DOCUMENT_CHUNKS ........ 25 rows, 8 columns, PK: CHUNK_ID
│   │       └── EMBEDDING: VECTOR(FLOAT, 768)
│   │
│   ├── Cortex Search Service
│   │   └── CORTEX_SEARCH_SVC ...... ON CHUNK_TEXT, Arctic Embed M v1.5, 1hr lag
│   │
│   └── Streams
│       └── DOCUMENT_CHUNKS_STREAM . APPEND_ONLY on DOCUMENT_CHUNKS
│
├── DATA_QUALITY (Schema)
│   ├── Tables
│   │   ├── DQ_RULES ............... 50 rows, 12 columns, PK: RULE_ID
│   │   ├── DQ_RESULTS ............. 40 rows, 12 columns, PK: RESULT_ID
│   │   ├── DQ_SCORES .............. 28 rows, 14 columns, PK: SCORE_ID
│   │   └── DQ_COLUMN_HEALTH ....... 28 rows, 12 columns, PK: HEALTH_ID
│   │
│   ├── Views
│   │   └── VW_DQ_ROOT_CAUSE ....... DQ_RESULTS + DQ_RULES + DQ_SCORES + DQ_COLUMN_HEALTH
│   │
│   ├── Semantic View
│   │   └── SV_DATA_QUALITY ........ 4 tables, 1 rel, 10 facts, 40 dims, 5 VQRs
│   │
│   ├── Stored Procedure
│   │   └── SP_DQ_ROOT_CAUSE(VARCHAR,VARCHAR) .... SQL, EXECUTE AS OWNER
│   │
│   ├── Streams
│   │   └── DQ_RESULTS_STREAM ...... APPEND_ONLY on DQ_RESULTS
│   │
│   ├── Tasks
│   │   └── TASK_DQ_FAILURE_ALERT .. WHEN DQ_RESULTS_STREAM has data
│   │       └── DAG dependency: runs AFTER TASK_DQ_DAILY_SCORE_REFRESH
│   │
│   └── Alerts
│       └── ALERT_DQ_SCORE_DROP .... CRON 0 */12 * * * UTC, threshold < 70%
│
├── Database Roles (6)
│   ├── INSURANCE_ADMIN_ROLE ....... inherits all below
│   ├── INSURANCE_DATA_STEWARD_ROLE  DATA_QUALITY access
│   ├── INSURANCE_EXEC_ROLE ........ agents + MCP, inherits ANALYST
│   ├── INSURANCE_UW_ROLE .......... pricing + matching, inherits ANALYST
│   ├── INSURANCE_CLAIMS_ROLE ...... DOCUMENTS access, inherits ANALYST
│   └── INSURANCE_ANALYST_ROLE ..... base ANALYTICS read
│
└── Account-Level Objects
    ├── INSURANCE_DEPLOY_ROLE ...... account role for DDL
    ├── INSURANCE_SERVICE_ROLE ..... account role for runtime
    ├── COMPUTE_WH ................. SMALL, auto-suspend 300s, QAS enabled
    ├── INSURANCE_AI_HUB_MONITOR ... 500 credits/month resource monitor
    ├── INSURANCE_AI_HUB_BUDGET .... 1,000 credits/month budget
    ├── JIRA_MCP_API_INTEGRATION ... DCR OAuth for Atlassian
    └── SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT ... CoWork (5 agents registered)
```

---

## 2. Entity-Relationship Model

### 2.1 ANALYTICS Schema

```
                           ┌──────────────┐
                           │   AGENTS     │
                           │   PK: AGENT  │
                           │   _ID        │
                           └──────┬───────┘
                                  │ 1
                                  │
                           ┌──────┴───────┐
                           │   POLICIES   │
              ┌────────────│   PK: POLICY │──────────────┐
              │            │   _ID        │              │
              │            │   FK: CUST,  │              │
              │            │       AGENT  │              │
              │            └──────┬───────┘              │
              │ n                 │ 1                    │ n
              │                  │                      │
   ┌──────────┴──────┐   ┌──────┴───────┐   ┌─────────┴──────┐
   │   BILLING       │   │  CUSTOMERS   │   │  AT_RISK_      │
   │   PK: BILLING   │   │  PK: CUST    │   │  POLICIES      │
   │   _ID           │   │  _ID         │   │  PK: RISK_ID   │
   │   FK: POLICY,   │   │              │   │  FK: POLICY,   │
   │       CUST      │   │  Masked:     │   │      CUST      │
   └─────────────────┘   │  EMAIL,PHONE │   └────────────────┘
                          │  ADDRESS     │
                          └──────┬───────┘
                                 │ 1
                                 │
                          ┌──────┴───────┐
                          │   CLAIMS     │
                          │   PK: CLAIM  │
                          │   _ID        │
                          │   FK: POLICY,│
                          │       CUST   │
                          └──────────────┘


   ┌──────────────────┐    ┌──────────────────┐
   │  PRODUCT_CATALOG  │    │  COMPETITOR_     │
   │  PK: PRODUCT_ID   │◄──│  PRICING         │
   │                   │    │  PK: BENCHMARK_ID│
   └────────┬──────────┘    └──────────────────┘
            │ 1
            │                ┌──────────────────┐
   ┌────────┴──────────┐    │  PRICING_        │
   │ PRODUCT_MATCH_    │    │  SCENARIOS       │
   │ SCORES            │    │  PK: SCENARIO_ID │
   │ PK: MATCH_ID      │    └──────────────────┘
   │ FK: PRODUCT_ID,   │
   │     CUSTOMER_ID   │    ┌──────────────────┐
   └───────────────────┘    │  MARKET_TRENDS   │
                            │  PK: TREND_ID    │
                            └──────────────────┘

   ┌──────────────────┐
   │  AGENT_AUDIT_LOG │  (system table — tasks/agents write here)
   │  PK: LOG_ID(UUID)│
   └──────────────────┘
```

### 2.2 DATA_QUALITY Schema

```
   ┌──────────────────┐          ┌──────────────────┐
   │   DQ_RULES       │ 1      n │   DQ_RESULTS     │
   │   PK: RULE_ID    │◄─────────│   PK: RESULT_ID  │
   │                   │          │   FK: RULE_ID    │
   │   50 rules across│          │                   │
   │   10 types       │          │   40 execution    │
   └──────────────────┘          │   records         │
                                 └──────────────────┘

   ┌──────────────────┐          ┌──────────────────┐
   │   DQ_SCORES      │          │  DQ_COLUMN_      │
   │   PK: SCORE_ID   │          │  HEALTH          │
   │                   │          │  PK: HEALTH_ID   │
   │   28 weekly       │          │                   │
   │   snapshots       │          │  28 column        │
   └──────────────────┘          │  health records   │
                                 └──────────────────┘
```

---

## 3. Semantic View Design

### 3.1 SV_INSURANCE_OPS (Primary)

```
Tables: 6
  CUSTOMERS ──── PK: CUSTOMER_ID
  POLICIES ───── PK: POLICY_ID ──── FK: CUSTOMER_ID, AGENT_ID
  CLAIMS ──────── PK: CLAIM_ID ──── FK: CUSTOMER_ID, POLICY_ID
  BILLING ─────── PK: BILLING_ID ── FK: CUSTOMER_ID, POLICY_ID
  AT_RISK_POLICIES PK: RISK_ID ──── FK: CUSTOMER_ID, POLICY_ID
  AGENTS ──────── PK: AGENT_ID

Relationships:
  POLICIES_TO_CUSTOMERS: POLICIES(CUSTOMER_ID) → CUSTOMERS(CUSTOMER_ID) [many_to_one]
  CLAIMS_TO_CUSTOMERS:   CLAIMS(CUSTOMER_ID) → CUSTOMERS(CUSTOMER_ID)   [many_to_one]

Facts (15):
  PREMIUM_AMOUNT, COVERAGE_AMOUNT, DEDUCTIBLE, LOSS_RATIO,
  CLAIM_AMOUNT, APPROVED_AMOUNT, FRAUD_SCORE,
  AMOUNT_DUE, AMOUNT_PAID, OUTSTANDING_BALANCE, LATE_FEE,
  RISK_SCORE, REVENUE_AT_RISK, CHURN_PROBABILITY, PERFORMANCE_RATING

Dimensions (66):
  All identifying and categorical columns from all 6 tables
  Including time dimensions: DATE_OF_BIRTH, CUSTOMER_SINCE, START_DATE,
  END_DATE, CLAIM_DATE, RESOLUTION_DATE, INVOICE_DATE, DUE_DATE, etc.

VQRs (10):
  0: Premium revenue by policy type (active)
  1: Claims breakdown by type and status
  2: Revenue at risk + avg churn probability
  3: Claims by customer state
  4: Revenue at risk by risk category
  5: Adjuster workload + avg resolution time
  6: Billing summary by payment status
  7: High fraud risk claims + exposure
  8: Active portfolio by type + loss ratio
  9: Customer + policy distribution by segment

CA Extension: JSON with time_dimensions for date-aware analytics
```

### 3.2 VQR Design Pattern

Each Verified Query follows this structure:
```sql
ai_verified_queries (
    "ID" AS (
        QUESTION 'Natural language question'
        VERIFIED_AT <epoch_timestamp>
        VERIFIED_BY 'author'
        ONBOARDING_QUESTION false
        SQL 'SELECT ... FROM ... WHERE ... GROUP BY ... ORDER BY ...'
    )
)
```

VQRs serve as "golden queries" that Cortex Analyst uses as templates for
semantically similar user questions, improving accuracy and consistency.

---

## 4. Stored Procedure Design

### 4.1 Security Pattern

All JavaScript procedures use bind parameters to prevent SQL injection:

```javascript
// SECURE: Parameterized query
var sql = `SELECT ... FROM table WHERE column = ?`;
var stmt = snowflake.createStatement({sqlText: sql, binds: [userInput]});

// NEVER: String concatenation
var sql = `SELECT ... FROM table WHERE column = '${userInput}'`;  // VULNERABLE
```

The SQL procedure (SP_DQ_ROOT_CAUSE) uses colon-prefix variables:

```sql
-- Inside LANGUAGE SQL procedure body
SELECT ... INTO :result FROM ... WHERE TABLE_NAME = :P_TABLE_NAME;
```

### 4.2 Procedure Specifications

| Procedure | Language | Returns | Purpose |
|-----------|----------|---------|---------|
| SP_CLAIM_RISK_SCORE | JavaScript | VARIANT | Multi-factor fraud risk assessment for a claim |
| SP_TREND_DETECTOR | JavaScript | VARIANT | Time-series trend analysis (claims, DQ, premium) |
| SP_DQ_ROOT_CAUSE | SQL | VARIANT | DQ failure root-cause with column health correlation |
| SP_PRODUCT_MATCH | JavaScript | VARIANT | Multi-strategy product-customer matching engine |
| SP_PRICE_OPTIMIZER | JavaScript | VARIANT | Competitive pricing analysis + scenario generation |
| SP_MARKET_FORECAST | JavaScript | VARIANT | Market trend analysis + anomaly detection |

### 4.3 SP_PRODUCT_MATCH Algorithm

```
Input: CUSTOMER_ID
  │
  ├── 1. Fetch customer profile (risk_tier, credit_score, segment, age)
  │
  ├── 2. Fetch all active products from PRODUCT_CATALOG
  │
  ├── 3. For each product:
  │   ├── Rule-based eligibility check:
  │   │   ├── Credit score >= MIN_CREDIT_SCORE
  │   │   ├── Age within MIN_AGE..MAX_AGE
  │   │   └── Risk tier in RISK_TIERS_ALLOWED
  │   │
  │   ├── Rule-based score (0.5 base):
  │   │   ├── +0.15 if credit >= 700
  │   │   ├── +0.15 if segment matches SEGMENTS_TARGETED
  │   │   └── Cap at 1.0
  │   │
  │   └── Similarity score:
  │       └── 0.4 + (credit/850)*0.3 + (eligible ? 0.2 : 0)
  │
  ├── 4. Combined score = avg(rule_score, similarity_score)
  │
  └── 5. Return top 5 matches sorted by combined_score DESC
```

---

## 5. Cortex Search Configuration

```yaml
Service: CORTEX_SEARCH_SVC
Schema:  INSURANCE_AI_HUB.DOCUMENTS

Source Query:
  SELECT CHUNK_ID, CHUNK_TEXT, SECTION_TITLE, DOCUMENT_ID,
         CHUNK_INDEX, TOKEN_COUNT
  FROM DOCUMENT_CHUNKS

Configuration:
  Search Column:    CHUNK_TEXT (full-text search target)
  Attributes:       SECTION_TITLE, DOCUMENT_ID (filterable metadata)
  Embedding Model:  snowflake-arctic-embed-m-v1.5
  Vector Dimension: 768
  Target Lag:       1 hour (auto-refresh)
  Warehouse:        COMPUTE_WH

Agent Tool Config:
  max_results:  5
  title_column: SECTION_TITLE
  id_column:    CHUNK_ID
```

Corpus: 25 document chunks from 10 insurance policy documents covering:
- Health (standard + Gold plan)
- Auto (personal + commercial fleet)
- Life (term)
- Home (dwelling + personal property + liability)
- Disability, Umbrella, Workers Compensation
- Claim forms

---

## 6. MCP Connector Architecture

```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│  Cortex Agent    │     │  Snowflake       │     │  Atlassian       │
│                  │     │  MCP Server      │     │  (Jira/Confl.)   │
│  mcp_servers:    │────►│                  │────►│                  │
│   ATLASSIAN_MCP_ │     │  EXTERNAL MCP    │     │  mcp.atlassian   │
│   SERVER         │     │  SERVER          │     │  .com/v1/mcp     │
│                  │     │                  │     │                  │
└──────────────────┘     │  API_INTEGRATION │     │  OAuth DCR       │
                         │  JIRA_MCP_API_   │     │  (auto-register) │
                         │  INTEGRATION     │     │                  │
                         │                  │     │                  │
                         │  Provider:       │     │  User must       │
                         │  external_mcp    │     │  complete OAuth  │
                         │                  │     │  flow per-user   │
                         └──────────────────┘     └──────────────────┘

Pre-requisite:
  admin.atlassian.com → Apps → AI Settings → Rovo MCP Server
  Add domain: https://identity.snowflake.com/oauth2/callback

Security:
  - USAGE granted to ACCOUNTADMIN only (never PUBLIC)
  - Database roles ADMIN and EXEC get MCP via 19_extended_rbac.sql
  - Each user independently authenticates via OAuth popup in CoWork
```

---

## 7. Task DAG & Scheduling

```
┌─────────────────────────────────────────────────────────────┐
│  TASK DEPENDENCY GRAPH                                      │
│                                                             │
│  TASK_DQ_DAILY_SCORE_REFRESH (root)                        │
│  ├── Schedule: CRON 0 6 * * * UTC (daily 6 AM)            │
│  ├── Warehouse: COMPUTE_WH                                 │
│  ├── Action: INSERT INTO DQ_SCORES from DQ_RESULTS+RULES  │
│  │                                                         │
│  └──► TASK_DQ_FAILURE_ALERT (child, runs AFTER parent)     │
│       ├── Trigger: SYSTEM$STREAM_HAS_DATA(DQ_RESULTS_STREAM)│
│       ├── Action: INSERT failed DQ results into AUDIT_LOG  │
│       └── Escalation: HUMAN_ESCALATION = TRUE for critical │
│                                                             │
│  TASK_FLAG_HIGH_FRAUD_CLAIMS (independent)                 │
│  ├── Trigger: SYSTEM$STREAM_HAS_DATA(CLAIMS_STREAM)       │
│  ├── Action: INSERT fraud_score > 0.7 claims into AUDIT_LOG│
│  └── Escalation: HUMAN_ESCALATION = TRUE                   │
│                                                             │
│  ALERT_DQ_SCORE_DROP (independent)                         │
│  ├── Schedule: CRON 0 */12 * * * UTC (every 12 hours)     │
│  ├── Condition: EXISTS(DQ_SCORES WHERE score < 70)         │
│  └── Action: INSERT alert into AUDIT_LOG                   │
└─────────────────────────────────────────────────────────────┘

Resume order (children first):
  1. ALTER TASK TASK_DQ_FAILURE_ALERT RESUME;
  2. ALTER TASK TASK_FLAG_HIGH_FRAUD_CLAIMS RESUME;
  3. ALTER TASK TASK_DQ_DAILY_SCORE_REFRESH RESUME;
  4. ALTER ALERT ALERT_DQ_SCORE_DROP RESUME;
```

---

## 8. Dashboard Technical Details

### 8.1 State Management

```
┌────────────────────────────────────────────────┐
│  Zustand Stores                                │
│                                                │
│  useChatStore                                  │
│  ├── messages: ChatMessage[]                   │
│  ├── addMessage(msg)                           │
│  └── clearMessages()                           │
│                                                │
│  useThemeStore                                 │
│  ├── dark: boolean                             │
│  ├── toggle()                                  │
│  └── setDark(val)                              │
│      └── Syncs with document.classList('dark') │
│      └── Persists to localStorage              │
└────────────────────────────────────────────────┘

┌────────────────────────────────────────────────┐
│  React Query                                   │
│                                                │
│  QueryClient config:                           │
│  ├── staleTime: 30 minutes                    │
│  ├── gcTime: 60 minutes                       │
│  ├── retry: 1                                  │
│  └── refetchOnWindowFocus: false              │
│                                                │
│  Prefetch on login:                            │
│  ├── exec-all (Executive Dashboard SQL)        │
│  ├── kpi-all (30 KPIs SQL)                    │
│  ├── gov-all (Governance Dashboard SQL)        │
│  └── admin-all (session info)                  │
└────────────────────────────────────────────────┘
```

### 8.2 API Retry & Error Handling

```
fetchWithRetry(url, options, retries=3)
  │
  ├── Attempt 0: fetch(url, options)
  │   ├── Success (200-299) → return response
  │   ├── 502 (proxy error) → wait 1s → retry
  │   └── Network error → wait 1s → retry
  │
  ├── Attempt 1: wait 2s → retry
  │
  ├── Attempt 2: wait 3s → retry
  │
  └── All failed → throw Error

SQL API flow:
  executeSQL(sql)
  ├── POST /api/v2/statements?async=false
  ├── If 401/403 → clearToken() → throw auth error
  ├── If result has statementStatusUrl (>45s query) → pollResult()
  │   └── Poll every 2s, up to 60 attempts (2 min max)
  └── parseResult() → { columns, data, rowCount }

Agent API flow:
  runAgentQuery(question, agentName)
  ├── Maintain conversation history per agent
  ├── POST /api/v2/databases/.../agents/AGENT:run
  ├── AbortController timeout: 120s
  ├── If SSE response → parse with fallback parser
  ├── Extract: text, toolTrace, datasets, sql, requestId
  └── Append assistant response to conversation history
```

### 8.3 DataVisualizer Auto-Detection

```
Input: dataset { columns, types, rows }
  │
  ├── Classify each column:
  │   ├── Date-like: column name matches /DATE|TIME|MONTH|YEAR|QUARTER/
  │   ├── Numeric: ≥70% of sample values parse as numbers
  │   └── Categorical: everything else
  │
  ├── Auto-select chart type:
  │   ├── date + numeric → LINE chart
  │   ├── ≤8 rows + 1 numeric + 1 categorical → PIE chart
  │   ├── categorical + numeric → BAR chart
  │   └── fallback → TABLE
  │
  └── User can toggle: bar / line / pie / table
```

---

## 9. Security Architecture

### 9.1 Authentication Flow

```
User → Login Page → Enter PAT token
  │
  ├── setToken(pat) stores in memory (never localStorage)
  │
  ├── Validation query: SELECT CURRENT_USER(), CURRENT_ROLE()...
  │   + warm cache: touch POLICIES, CLAIMS, DQ_SCORES
  │
  ├── Success → setAuthenticated(true) → prefetch dashboards
  │
  └── 30-minute inactivity timeout
      ├── Events: mousedown, keydown, scroll, touchstart
      └── Timeout → clearToken() → redirect to Login
```

### 9.2 SQL Injection Prevention

| Layer | Method |
|-------|--------|
| Dashboard SQL API | `executeSQLWithBindings()` with positional bind params |
| AI_TRANSLATE | `SELECT AI_TRANSLATE(?, '', 'en')` — user text as bind |
| JS Stored Procedures | `snowflake.createStatement({sqlText: sql, binds: [param]})` |
| SQL Stored Procedures | Colon-prefix variables (`:P_TABLE_NAME`) |
| Agent inputs | Natural language passed to Cortex Agent API as JSON body |

### 9.3 Masking Policy Logic

```sql
-- Pattern: Full access for admin, masked for everyone else
CREATE MASKING POLICY MASK_EMAIL AS (val VARCHAR) RETURNS VARCHAR ->
  CASE
    WHEN IS_DATABASE_ROLE_IN_SESSION('INSURANCE_AI_HUB.INSURANCE_ADMIN_ROLE')
      THEN val                                          -- admin sees real data
    ELSE REGEXP_REPLACE(val, '(^[^@]{2})[^@]*(@.*)', '\\1***\\2')  -- others see masked
  END;

-- Applied at column level during CREATE TABLE:
EMAIL VARCHAR(100) WITH MASKING POLICY MASK_EMAIL
                   WITH TAG (PII_LEVEL='HIGH')
```

---

## 10. Cost Control Architecture

```
┌──────────────────────────────────────────────────────────────┐
│  COST CONTROLS                                               │
│                                                              │
│  ┌────────────────────────────────┐                         │
│  │  RESOURCE MONITOR              │                         │
│  │  INSURANCE_AI_HUB_MONITOR      │                         │
│  │                                │                         │
│  │  Scope: COMPUTE_WH only        │                         │
│  │  Quota: 500 credits/month      │                         │
│  │  Triggers:                     │                         │
│  │    75% → NOTIFY                │                         │
│  │    90% → NOTIFY                │                         │
│  │   100% → SUSPEND warehouse    │                         │
│  └────────────────────────────────┘                         │
│                                                              │
│  ┌────────────────────────────────┐                         │
│  │  BUDGET                        │                         │
│  │  INSURANCE_AI_HUB_BUDGET       │                         │
│  │                                │                         │
│  │  Scope: ALL credit types       │                         │
│  │    (warehouse + serverless AI  │                         │
│  │     + Cortex Search + tasks)   │                         │
│  │  Limit: 1,000 credits/month   │                         │
│  │  Resources: COMPUTE_WH        │                         │
│  └────────────────────────────────┘                         │
│                                                              │
│  ┌────────────────────────────────┐                         │
│  │  WAREHOUSE CONFIG              │                         │
│  │  COMPUTE_WH                    │                         │
│  │                                │                         │
│  │  Size: SMALL                   │                         │
│  │  Auto-suspend: 300s (5 min)    │                         │
│  │  Auto-resume: TRUE             │                         │
│  │  Query Acceleration: ENABLED   │                         │
│  └────────────────────────────────┘                         │
└──────────────────────────────────────────────────────────────┘
```

---

## 11. File Structure

```
insurance-ai-hub-deploy/
├── sql/                          # 21 SQL deployment scripts
│   ├── 00_setup.sql              # 114 lines — infrastructure
│   ├── 01_governance.sql         # 50 lines — tags + masking
│   ├── 02_tables.sql             # 253 lines — 13 tables
│   ├── 03_views.sql              # 160 lines — 4 views
│   ├── 04_semantic_views.sql     # 296 lines — 2 SVs + 15 VQRs
│   ├── 05_procedures.sql         # 218 lines — 3 procedures
│   ├── 06_cortex_search.sql      # 33 lines — search service
│   ├── 07_cortex_agent.sql       # 36 lines — reference only
│   ├── 08_rbac.sql               # 133 lines — 6 roles + grants
│   ├── 09_seed_data.sql          # 441 lines — core data
│   ├── 10_extended_tables.sql    # 139 lines — 5 tables
│   ├── 11_extended_views.sql     # 118 lines — 3 views
│   ├── 12_extended_semantic_views.sql # 306 lines — 3 SVs + 10 VQRs
│   ├── 13_extended_procedures.sql # 280 lines — 3 procedures
│   ├── 14_extended_seed_data.sql  # 186 lines — extended data
│   ├── 15_specialized_agents.sql  # 174 lines — 3 agents
│   ├── 16_unified_agent.sql       # 140 lines — enterprise agent
│   ├── 17_cowork_setup.sql        # 73 lines — CoWork
│   ├── 18_mcp_connectors.sql      # 84 lines — Atlassian MCP
│   ├── 19_extended_rbac.sql       # 72 lines — extended grants
│   ├── 20_rollback.sql            # 153 lines — teardown
│   └── 21_tasks_and_streams.sql   # 205 lines — automation
│
├── cortex_project/               # 11 YAML files for snow cortex deploy
│   ├── cortex-project.yaml       # manifest (11 artifacts)
│   ├── INSURANCE_INTELLIGENCE_AGENT.agent.yaml
│   ├── UNIFIED_ENTERPRISE_AGENT.agent.yaml
│   ├── MARKET_INTELLIGENCE_AGENT.agent.yaml
│   ├── PRICE_OPTIMIZATION_AGENT.agent.yaml
│   ├── PRODUCT_MATCHING_AGENT.agent.yaml
│   ├── SV_INSURANCE_OPS.sv.yaml
│   ├── SV_DATA_QUALITY.sv.yaml
│   ├── SV_COMPETITIVE_INTEL.sv.yaml
│   ├── SV_MARKET_INTELLIGENCE.sv.yaml
│   └── SV_PRODUCT_MATCHING.sv.yaml
│
├── dashboard/                    # React 18 + TypeScript + Tailwind
│   ├── package.json
│   ├── .env.example
│   ├── index.html
│   ├── vite.config.ts            # Vite with HTTPS proxy to Snowflake
│   ├── tailwind.config.js
│   ├── tsconfig.json
│   └── src/
│       ├── main.tsx              # React Query + Router setup
│       ├── App.tsx               # Route definitions + auth + session timeout
│       ├── index.css             # Tailwind imports + scrollbar styles
│       ├── lib/constants.ts      # Snowflake config from env vars
│       ├── stores/index.ts       # Zustand: chat + theme
│       ├── services/
│       │   ├── snowflake-api.ts  # SQL API client with retry + polling
│       │   ├── cortex-agent.ts   # Agent API client with SSE fallback
│       │   ├── translate.ts      # AI_TRANSLATE wrapper (parameterized)
│       │   └── prefetch.ts       # Dashboard data prefetching
│       ├── hooks/
│       │   ├── useSnowflakeQuery.ts  # React Query wrapper for SQL
│       │   └── useVoiceInput.ts      # Web Speech API hook
│       ├── components/
│       │   ├── layout/Layout.tsx     # Sidebar navigation
│       │   ├── dashboard/KPICard.tsx # KPI display component
│       │   └── shared/
│       │       ├── DataVisualizer.tsx # Auto-detecting chart component
│       │       ├── RefreshButton.tsx  # Refresh trigger
│       │       └── StatusBadge.tsx    # Status indicator
│       └── pages/                # 14 pages
│           ├── Login.tsx
│           ├── ExecutiveDashboard.tsx
│           ├── KPIDashboard.tsx
│           ├── AIAssistant.tsx
│           ├── KnowledgeHub.tsx
│           ├── AgentInsights.tsx
│           ├── DocumentIntelligence.tsx
│           ├── DataExplorer.tsx
│           ├── GovernanceDashboard.tsx
│           ├── AdminConsole.tsx
│           ├── MarketIntelAgent.tsx
│           ├── PricingAdvisorAgent.tsx
│           ├── ProductMatcherAgent.tsx
│           └── EnterpriseHubAgent.tsx
│
├── ci-cd/
│   └── deploy.yml                # GitHub Actions (3 jobs)
│
└── deploy.sh                     # Bash deployment script (14 phases)
```

---

*Insurance AI Hub — Technical Architecture Guide*
*Generated: 24 Sep 2026*
