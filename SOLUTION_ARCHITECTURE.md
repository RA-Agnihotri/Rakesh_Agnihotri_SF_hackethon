# Insurance AI Hub — Solution Architecture Guide

> Enterprise-grade insurance intelligence platform built entirely on Snowflake
> with Cortex AI, multi-agent orchestration, and a React analytics dashboard.

---

## 1. Executive Summary

The Insurance AI Hub is a full-stack data intelligence platform that transforms
raw insurance data into actionable insights through conversational AI agents,
real-time data quality monitoring, document intelligence, and competitive
market analysis.

**What it does:**
- Answers natural-language questions about policies, claims, billing, and risk
  using Cortex Agents backed by Semantic Views
- Searches policy documents via RAG (Cortex Search with Arctic Embed M v1.5)
- Monitors data quality with automated scoring, alerting, and root-cause analysis
- Benchmarks pricing against competitors and generates what-if scenarios
- Matches products to customers using multi-strategy scoring
- Creates Jira tickets from insights via MCP connector
- Accepts voice input in any language via AI_TRANSLATE

**Scale:** 18 tables, 2,085+ seed rows, 7 views, 5 semantic views (25 VQRs),
5 Cortex Agents, 6 stored procedures, 3 streams, 3 tasks, 1 alert, 6 database
roles, 3 masking policies, 14-page React dashboard.

---

## 2. Solution Overview Diagram

```
                         ┌─────────────────────────────────────┐
                         │         USER INTERFACES             │
                         │                                     │
                         │  ┌──────────┐  ┌────────────────┐  │
                         │  │  React    │  │  Snowflake     │  │
                         │  │  Dashboard│  │  CoWork        │  │
                         │  │  (14 pg)  │  │  (5 agents)    │  │
                         │  └─────┬─────┘  └───────┬────────┘  │
                         └────────┼────────────────┼───────────┘
                                  │                │
              ┌───────────────────┼────────────────┼──────────────────┐
              │                   ▼                ▼                  │
              │           ┌─────────────────────────────────┐        │
              │           │      CORTEX AI LAYER            │        │
              │           │                                 │        │
              │           │  ┌───────────────────────────┐  │        │
              │           │  │   5 CORTEX AGENTS          │  │        │
              │           │  │                           │  │        │
              │           │  │  Insurance Intelligence   │  │        │
              │           │  │  Unified Enterprise Hub   │  │        │
              │           │  │  Market Intelligence      │  │        │
              │           │  │  Price Optimization       │  │        │
              │           │  │  Product Matching         │  │        │
              │           │  └─────┬──────┬──────┬──────┘  │        │
              │           │        │      │      │         │        │
              │           │   ┌────┘  ┌───┘  ┌───┘         │        │
              │           │   ▼       ▼      ▼             │        │
              │           │ ┌─────┐┌──────┐┌──────┐┌─────┐│        │
              │           │ │Anal-││Search││Chart ││ MCP ││        │
              │           │ │yst  ││(RAG) ││      ││Jira ││        │
              │           │ └──┬──┘└──┬───┘└──────┘└─────┘│        │
              │           └────┼──────┼────────────────────┘        │
              │                │      │                              │
              │           ┌────┼──────┼────────────────────┐        │
              │           │    ▼      ▼                    │        │
              │           │   SEMANTIC & SEARCH LAYER      │        │
              │           │                                │        │
              │           │  5 Semantic Views (25 VQRs)    │        │
              │           │  1 Cortex Search Service       │        │
              │           │  (Arctic Embed M v1.5, 768d)   │        │
              │           └────────────┬───────────────────┘        │
              │                        │                             │
              │           ┌────────────┼───────────────────┐        │
              │           │            ▼                   │        │
              │           │      DATA LAYER                │        │
              │           │                                │        │
              │           │  ┌──────────┐ ┌─────────┐     │        │
              │           │  │ANALYTICS │ │DOCUMENTS│     │        │
              │           │  │12 tables │ │2 tables │     │        │
              │           │  │7 views   │ │Search   │     │        │
              │           │  │4 SVs     │ │Service  │     │        │
              │           │  │5 procs   │ └─────────┘     │        │
              │           │  └──────────┘                  │        │
              │           │  ┌──────────────┐              │        │
              │           │  │DATA_QUALITY  │              │        │
              │           │  │4 tables      │              │        │
              │           │  │1 view, 1 SV  │              │        │
              │           │  │1 proc        │              │        │
              │           │  └──────────────┘              │        │
              │           └────────────────────────────────┘        │
              │                                                     │
              │           ┌────────────────────────────────┐        │
              │           │   AUTOMATION LAYER             │        │
              │           │                                │        │
              │           │  3 Streams (CDC)               │        │
              │           │  3 Tasks (1 cron + 2 trigger)  │        │
              │           │  1 Alert (DQ score monitor)    │        │
              │           └────────────────────────────────┘        │
              │                                                     │
              │           ┌────────────────────────────────┐        │
              │           │   GOVERNANCE LAYER             │        │
              │           │                                │        │
              │           │  2 Tags  3 Masking Policies    │        │
              │           │  6 Database Roles (hierarchy)  │        │
              │           │  Resource Monitor + Budget     │        │
              │           └────────────────────────────────┘        │
              │                                                     │
              │                    SNOWFLAKE                        │
              └─────────────────────────────────────────────────────┘
```

---

## 3. Domain Model

The platform covers six analytical domains, each backed by a dedicated
Semantic View and accessible through one or more Cortex Agents:

```
┌─────────────────────────────────────────────────────────────────┐
│                    INSURANCE AI HUB DOMAINS                     │
├──────────────────┬──────────────────┬───────────────────────────┤
│  OPERATIONS      │  DATA QUALITY    │  DOCUMENTS                │
│  SV_INSURANCE_OPS│  SV_DATA_QUALITY │  CORTEX_SEARCH_SVC        │
│                  │                  │                           │
│  Customers       │  DQ Rules        │  Policy Documents         │
│  Policies        │  DQ Results      │  Document Chunks          │
│  Claims          │  DQ Scores       │  (768-dim embeddings)     │
│  Billing         │  Column Health   │                           │
│  At-Risk         │                  │                           │
│  Agents          │                  │                           │
├──────────────────┼──────────────────┼───────────────────────────┤
│  COMPETITIVE     │  MARKET          │  PRODUCT MATCHING         │
│  INTELLIGENCE    │  INTELLIGENCE    │                           │
│  SV_COMPETITIVE_ │  SV_MARKET_      │  SV_PRODUCT_MATCHING      │
│  INTEL           │  INTELLIGENCE    │                           │
│                  │                  │                           │
│  Competitor      │  Market Trends   │  Product Catalog          │
│  Pricing         │  Industry        │  Match Scores             │
│  Pricing         │  Benchmarks      │  Customer Profiles        │
│  Scenarios       │  YoY Changes     │  Recommendations          │
└──────────────────┴──────────────────┴───────────────────────────┘
```

---

## 4. Agent Architecture

### 4.1 Agent Inventory

| Agent | Tools | Semantic Views | Search | Chart | MCP | Users |
|-------|-------|---------------|--------|-------|-----|-------|
| **Insurance Intelligence** | 3 | SV_INSURANCE_OPS, SV_DATA_QUALITY | CORTEX_SEARCH_SVC | - | - | Dashboard default |
| **Unified Enterprise Hub** | 7+chart+MCP | All 5 SVs | CORTEX_SEARCH_SVC | data_to_chart | Atlassian | Executives, all roles |
| **Market Intelligence** | 2+chart+MCP | SV_MARKET_INTELLIGENCE, SV_INSURANCE_OPS | - | data_to_chart | Atlassian | Strategy team |
| **Price Optimization** | 2+MCP | SV_COMPETITIVE_INTEL, SV_INSURANCE_OPS | - | - | Atlassian | Actuaries, pricing |
| **Product Matching** | 3+MCP | SV_PRODUCT_MATCHING, SV_INSURANCE_OPS | CORTEX_SEARCH_SVC | - | Atlassian | Underwriters, sales |

### 4.2 Agent Routing Flow

```
User Question
    │
    ▼
┌──────────────────────────┐
│  Cortex Agent            │
│  (Orchestration Model)   │
│                          │
│  Routing Rules:          │
│  ├─ customers/claims     │──► insurance_operations_analyst (SV_INSURANCE_OPS)
│  ├─ DQ scores/rules      │──► data_quality_analyst (SV_DATA_QUALITY)
│  ├─ policy docs/coverage  │──► policy_document_search (CORTEX_SEARCH_SVC)
│  ├─ competitor pricing    │──► competitive_intel_analyst (SV_COMPETITIVE_INTEL)
│  ├─ market trends         │──► market_intelligence_analyst (SV_MARKET_INTELLIGENCE)
│  ├─ product matching      │──► product_matching_analyst (SV_PRODUCT_MATCHING)
│  ├─ "show chart"          │──► data_to_chart
│  ├─ Jira ticket           │──► Atlassian MCP connector
│  └─ cross-domain          │──► decompose → multiple tools
└──────────────────────────┘
    │
    ▼
┌──────────────────────────┐
│  Tool Execution          │
│                          │
│  Analyst: NL → SQL via   │
│  Semantic View + VQRs    │
│  → COMPUTE_WH            │
│                          │
│  Search: Query → Vector  │
│  similarity → Top-5      │
│  chunks with citations   │
│                          │
│  Chart: Data → Viz       │
│  MCP: API → Jira         │
└──────────────────────────┘
    │
    ▼
Grounded Response (with source citations)
```

### 4.3 Voice + Translation Pipeline

```
User speaks      Web Speech API     AI_TRANSLATE           Cortex Agent
(any language) ──► speech-to-text ──► (?, '', 'en') ──► English query
     🎙️              📝                 🌐                   🤖
                  Client-side        Snowflake SQL        Agent processes
                  (no compute)       (parameterized)      English text
```

- 7 dashboard pages support voice input
- AI_TRANSLATE auto-detects source language
- SQL injection safe via parameterized bindings
- Green banner shows "Translated from: ..." in UI

---

## 5. Data Flow Architecture

### 5.1 Seed Data Flow

```
GENERATOR(ROWCOUNT)
    │
    ├──► AGENTS (20 rows)
    ├──► CUSTOMERS (200 rows)
    ├──► POLICIES (300 rows)
    ├──► CLAIMS (400 rows)
    ├──► BILLING (500 rows)
    ├──► AT_RISK_POLICIES (165 rows)
    ├──► POLICY_DOCUMENTS (10 rows, explicit VALUES)
    ├──► DOCUMENT_CHUNKS (25 rows, explicit VALUES)
    ├──► DQ_RULES (50 rows, explicit VALUES)
    ├──► DQ_RESULTS (40 rows, explicit VALUES)
    ├──► DQ_SCORES (28 rows, explicit VALUES)
    ├──► DQ_COLUMN_HEALTH (28 rows, explicit VALUES)
    │
    │ Extended tables:
    ├──► PRODUCT_CATALOG (20 rows)
    ├──► COMPETITOR_PRICING (60 rows)
    ├──► MARKET_TRENDS (80 rows)
    ├──► PRODUCT_MATCH_SCORES (200 rows)
    └──► PRICING_SCENARIOS (40 rows)

Total: ~2,146 rows across 18 tables
```

### 5.2 Automation / CDC Flow

```
                    ┌──────────────┐
                    │  New CLAIMS   │
                    │  inserted     │
                    └──────┬───────┘
                           │
                           ▼
              ┌────────────────────────┐
              │  CLAIMS_STREAM         │
              │  (APPEND_ONLY CDC)     │
              └────────────┬───────────┘
                           │
            WHEN SYSTEM$STREAM_HAS_DATA()
                           │
                           ▼
              ┌────────────────────────┐
              │  TASK_FLAG_HIGH_FRAUD  │
              │  fraud_score > 0.7     │
              │  → AGENT_AUDIT_LOG     │
              └────────────────────────┘


                    ┌──────────────┐        ┌──────────────┐
                    │  CRON 6AM    │        │ DQ_RESULTS   │
                    │  daily       │        │ new FAIL     │
                    └──────┬───────┘        └──────┬───────┘
                           │                       │
                           ▼                       ▼
              ┌─────────────────────┐  ┌──────────────────────┐
              │ TASK_DQ_DAILY_      │  │ DQ_RESULTS_STREAM    │
              │ SCORE_REFRESH       │  │ (CDC)                │
              │ → DQ_SCORES         │  └──────────┬───────────┘
              └─────────┬───────────┘             │
                        │ (DAG: runs after)       │
                        ▼                         ▼
              ┌─────────────────────┐  (triggered independently)
              │ TASK_DQ_FAILURE_    │
              │ ALERT               │
              │ → AGENT_AUDIT_LOG   │
              └─────────────────────┘


              ┌─────────────────────────────┐
              │  ALERT_DQ_SCORE_DROP        │
              │  Every 12 hours             │
              │  IF any DQ score < 70%      │
              │  → AGENT_AUDIT_LOG          │
              └─────────────────────────────┘
```

---

## 6. Governance Architecture

### 6.1 RBAC Hierarchy

```
ACCOUNTADMIN
    │
    ├── INSURANCE_DEPLOY_ROLE (DDL, deployment)
    │
    ├── INSURANCE_SERVICE_ROLE (runtime, agents, tasks)
    │       │
    │       └── INSURANCE_ADMIN_ROLE (database role, inherits all below)
    │               │
    │               ├── INSURANCE_DATA_STEWARD_ROLE (DATA_QUALITY schema)
    │               │
    │               ├── INSURANCE_EXEC_ROLE (agents, MCP)
    │               │       └── INSURANCE_ANALYST_ROLE (ANALYTICS read)
    │               │
    │               ├── INSURANCE_UW_ROLE (pricing + matching agents)
    │               │       └── INSURANCE_ANALYST_ROLE
    │               │
    │               └── INSURANCE_CLAIMS_ROLE (DOCUMENTS schema)
    │                       └── INSURANCE_ANALYST_ROLE
    │
    └── SYSADMIN
```

### 6.2 Data Protection

| Control | Scope | Details |
|---------|-------|---------|
| **PII_LEVEL tag** | Column | HIGH (email, phone, address), MEDIUM (DOB), LOW, NONE |
| **BUSINESS_DOMAIN tag** | Table | CUSTOMER, POLICY, CLAIMS, BILLING, RISK, DOCUMENTS, DATA_QUALITY |
| **MASK_EMAIL** | CUSTOMERS.EMAIL | `xx***@domain.com` for non-admin roles |
| **MASK_PHONE** | CUSTOMERS.PHONE | `***-****` for non-admin roles |
| **MASK_ADDRESS** | CUSTOMERS.ADDRESS | `*** REDACTED ***` for non-admin roles |
| **Resource Monitor** | Warehouse | 500 credits/month, suspend at 100% |
| **Budget** | All compute | 1,000 credits/month (warehouse + serverless AI) |

---

## 7. Dashboard Architecture

### 7.1 Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | React 18 + TypeScript |
| Styling | Tailwind CSS 3.4 |
| Build | Vite 5 |
| Charts | Recharts |
| State | Zustand + React Query |
| Auth | Snowflake Programmatic Access Token (PAT) |
| API | Snowflake SQL API v2 + Cortex Agent REST API |

### 7.2 Page Map

```
┌─────────────────────────────────────────────────────────┐
│  React Dashboard (14 pages)                             │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ANALYTICS PAGES              AGENT PAGES               │
│  ├── Executive Dashboard      ├── AI Assistant (core)   │
│  ├── KPI Dashboard (30 KPIs)  ├── Enterprise Hub (7t)   │
│  ├── Data Explorer (NL-SQL)   ├── Market Intel           │
│  ├── Governance Dashboard     ├── Pricing Advisor        │
│  └── Admin Console            └── Product Matcher        │
│                                                         │
│  DOCUMENT PAGES               VOICE + TRANSLATE         │
│  ├── Knowledge Hub (RAG)      ├── AI Assistant          │
│  └── Document Intelligence    ├── Enterprise Hub         │
│      (summarize/classify/     ├── Market Intel           │
│       extract/compare)        ├── Pricing Advisor        │
│                               ├── Product Matcher        │
│  OTHER                        ├── Knowledge Hub          │
│  ├── Agent Insights           └── Data Explorer          │
│  └── Login                                              │
└─────────────────────────────────────────────────────────┘
```

### 7.3 API Integration

```
React App
    │
    ├── Snowflake SQL API (/api/v2/statements)
    │   ├── executeSQL() — ad-hoc queries
    │   ├── executeSQLWithBindings() — parameterized (AI_TRANSLATE)
    │   └── Proxy via Vite dev server → Snowflake account URL
    │
    ├── Cortex Agent API (/api/v2/databases/.../agents/AGENT_NAME:run)
    │   ├── runAgentQuery() — multi-turn conversation
    │   ├── SSE streaming fallback parser
    │   └── Tool trace extraction (toolName, toolType, SQL, datasets)
    │
    └── Authentication
        ├── PAT token entered at login
        ├── X-Snowflake-Authorization-Token-Type: PROGRAMMATIC_ACCESS_TOKEN
        └── 30-minute inactivity timeout (auto-logout)
```

---

## 8. Deployment Architecture

### 8.1 Deployment Pipeline

```
┌─────────────────┐     ┌──────────────┐     ┌──────────────┐
│  GitHub Repo     │────►│ GitHub       │────►│ Snowflake    │
│                  │     │ Actions      │     │ Account      │
│  sql/            │     │              │     │              │
│  cortex_project/ │     │ 3 jobs:      │     │ INSURANCE_   │
│  dashboard/      │     │ 1. SnowSQL   │     │ AI_HUB       │
│  ci-cd/          │     │ 2. Dashboard │     │              │
│                  │     │ 3. Validate  │     │              │
└─────────────────┘     └──────────────┘     └──────────────┘
```

### 8.2 Deployment Options

| Option | Method | Best For |
|--------|--------|----------|
| **Automated** | `./deploy.sh` (14 phases) | Full deployment |
| **Manual** | Run SQL files 00-21 in Snowsight | Step-by-step |
| **CI/CD** | GitHub Actions (`ci-cd/deploy.yml`) | Production |
| **Cortex Project** | `snow cortex deploy` | Agent + SV only |

### 8.3 Rollback

`sql/20_rollback.sql` reverses everything in dependency order:
1. CoWork agent deregistration
2. MCP server + API integration drop
3. Agent drop (5)
4. Cortex Search drop
5. Procedure drop (6)
6. Semantic View drop (5)
7. View drop (7)
8. Masking policy unset + drop (3)
9. Tag drop (2)
10. Database role drop (6)
11. (Optional) Database drop
12. (Optional) Account-level cleanup

---

## 9. Snowflake Features Summary

| # | Feature | Count | Purpose |
|---|---------|-------|---------|
| 1 | Cortex Agent | 5 | Conversational AI with multi-tool orchestration |
| 2 | Cortex Analyst | 5 SVs | NL-to-SQL via semantic layer |
| 3 | Cortex Search | 1 | RAG over 25 document chunks |
| 4 | AI_TRANSLATE | 7 pages | Multilingual voice input |
| 5 | Semantic Views | 5 | Structured analytics model |
| 6 | Verified Queries | 25 | Curated query templates |
| 7 | MCP Connectors | 1 | Atlassian Jira + Confluence |
| 8 | Snowflake Intelligence | 1 | CoWork agent registry |
| 9 | Data-to-Chart | in agents | Visualization from data |
| 10 | Streams | 3 | Change data capture |
| 11 | Tasks | 3 | Scheduled + triggered automation |
| 12 | Alerts | 1 | DQ score monitoring |
| 13 | Object Tags | 2 | PII + business domain classification |
| 14 | Dynamic Masking | 3 | Email, phone, address protection |
| 15 | Database Roles | 6 | Hierarchical RBAC |
| 16 | Resource Monitor | 1 | 500 credit/month warehouse cap |
| 17 | Budget | 1 | 1,000 credit/month total cap |
| 18 | Query Acceleration | 1 | Enabled on COMPUTE_WH |
| 19 | Vector Embeddings | 768d | VECTOR(FLOAT, 768) for search |
| 20 | Stored Procedures | 6 | 4 JavaScript + 2 SQL |
| 21 | Cortex Project YAML | 11 files | Declarative agent deployment |
| 22 | Cross-region inference | account | CORTEX_ENABLED_CROSS_REGION |

---

*Insurance AI Hub — Solution Architecture Guide*
*Generated: 24 Sep 2026*
