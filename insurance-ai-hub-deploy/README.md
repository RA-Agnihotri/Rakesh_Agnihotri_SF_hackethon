# Insurance Intelligence Platform - Production Deployment Package

Complete production deployment package for the **Insurance AI Hub** Snowflake platform.

## Architecture Overview

```
INSURANCE_AI_HUB (Database)
├── ANALYTICS (Schema)
│   ├── Tables (12): AGENTS, CUSTOMERS, POLICIES, CLAIMS, BILLING, AT_RISK_POLICIES,
│   │                 AGENT_AUDIT_LOG, PRODUCT_CATALOG, COMPETITOR_PRICING,
│   │                 MARKET_TRENDS, PRODUCT_MATCH_SCORES, PRICING_SCENARIOS
│   ├── Views (6): VW_CUSTOMER_360, VW_CLAIMS_PERFORMANCE, VW_AT_RISK_PORTFOLIO,
│   │              VW_COMPETITIVE_PRICING, VW_MATCH_ACCURACY, VW_MARKET_ANALYSIS
│   ├── Semantic Views (4): SV_INSURANCE_OPS (10 VQRs), SV_COMPETITIVE_INTEL (4 VQRs),
│   │                       SV_MARKET_INTELLIGENCE (3 VQRs), SV_PRODUCT_MATCHING (3 VQRs)
│   ├── Procedures: SP_CLAIM_RISK_SCORE, SP_TREND_DETECTOR, SP_PRODUCT_MATCH,
│   │               SP_PRICE_OPTIMIZER, SP_MARKET_FORECAST
│   ├── Agents (5): INSURANCE_INTELLIGENCE_AGENT (3 tools),
│   │               UNIFIED_ENTERPRISE_AGENT (7 tools + MCP),
│   │               MARKET_INTELLIGENCE_AGENT, PRICE_OPTIMIZATION_AGENT,
│   │               PRODUCT_MATCHING_AGENT
│   └── MCP: ATLASSIAN_MCP_SERVER (Jira + Confluence)
├── DOCUMENTS (Schema)
│   ├── Tables: POLICY_DOCUMENTS, DOCUMENT_CHUNKS (768-dim embeddings)
│   └── Cortex Search: CORTEX_SEARCH_SVC (Arctic Embed M v1.5, 1hr lag)
├── DATA_QUALITY (Schema)
│   ├── Tables: DQ_RULES, DQ_RESULTS, DQ_SCORES, DQ_COLUMN_HEALTH
│   ├── View: VW_DQ_ROOT_CAUSE
│   ├── Semantic View: SV_DATA_QUALITY (5 VQRs)
│   └── Procedure: SP_DQ_ROOT_CAUSE
├── RBAC: 6 database roles with hierarchy
│   ├── INSURANCE_ADMIN_ROLE (inherits all)
│   ├── INSURANCE_DATA_STEWARD_ROLE
│   ├── INSURANCE_EXEC_ROLE → INSURANCE_ANALYST_ROLE
│   ├── INSURANCE_UW_ROLE → INSURANCE_ANALYST_ROLE
│   └── INSURANCE_CLAIMS_ROLE → INSURANCE_ANALYST_ROLE
└── CoWork: SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT (agent registry)
```

## Package Contents

```
insurance-ai-hub-deploy/
├── sql/
│   ├── 00_setup.sql              # Database, schemas, warehouse
│   ├── 01_governance.sql         # Tags (PII_LEVEL, BUSINESS_DOMAIN), masking policies
│   ├── 02_tables.sql             # 13 core tables with PK, tags, masking
│   ├── 03_views.sql              # 4 core analytical views
│   ├── 04_semantic_views.sql     # 2 core semantic views with 15 VQRs
│   ├── 05_procedures.sql         # 3 core stored procedures (JS + SQL)
│   ├── 06_cortex_search.sql      # Cortex Search service on document chunks
│   ├── 07_cortex_agent.sql       # Agent deployment reference
│   ├── 08_rbac.sql               # 6 database roles + full grant hierarchy
│   ├── 09_seed_data.sql          # Core sample data (~1,670 rows)
│   ├── 10_extended_tables.sql    # 5 new tables (Product, Competitor, Market, Match, Scenarios)
│   ├── 11_extended_views.sql     # 3 new analytical views
│   ├── 12_extended_semantic_views.sql # 3 new semantic views with 10 VQRs
│   ├── 13_extended_procedures.sql    # 3 new procedures (Match, Price, Forecast)
│   ├── 14_extended_seed_data.sql     # Extended sample data (~400 rows)
│   ├── 15_specialized_agents.sql     # 3 domain agents with MCP
│   ├── 16_unified_agent.sql          # Unified Enterprise Agent (7 tools + MCP)
│   ├── 17_cowork_setup.sql           # Snowflake CoWork Intelligence object
│   ├── 18_mcp_connectors.sql         # Atlassian MCP connector (Jira + Confluence)
│   ├── 19_extended_rbac.sql          # Grants on new objects to existing roles
│   ├── 20_rollback.sql                # Complete teardown / rollback script (12 sections)
│   └── 21_tasks_and_streams.sql       # 3 streams + 3 tasks + 1 alert (automation)
├── cortex_project/
│   ├── cortex-project.yaml                       # Project manifest (7 artifacts)
│   ├── INSURANCE_INTELLIGENCE_AGENT.agent.yaml   # Core agent (3 tools)
│   ├── UNIFIED_ENTERPRISE_AGENT.agent.yaml       # Enterprise agent (7 tools + MCP)
│   ├── SV_INSURANCE_OPS.sv.yaml                  # Insurance operations SV
│   ├── SV_DATA_QUALITY.sv.yaml                   # Data quality SV
│   ├── SV_COMPETITIVE_INTEL.sv.yaml              # Competitive intelligence SV
│   ├── SV_MARKET_INTELLIGENCE.sv.yaml            # Market intelligence SV
│   └── SV_PRODUCT_MATCHING.sv.yaml               # Product matching SV
├── dashboard/                     # React JS dashboard (TypeScript + Tailwind)
│   ├── src/
│   │   ├── pages/                # 9 pages (Executive, KPI, AI Assistant, etc.)
│   │   ├── services/             # Snowflake SQL API + Cortex Agent API clients
│   │   ├── components/           # Reusable UI components
│   │   └── ...
│   ├── package.json
│   ├── vite.config.ts
│   └── .env.example
├── ci-cd/
│   └── deploy.yml                # GitHub Actions pipeline
├── deploy.sh                     # One-command deployment script (14 phases)
├── ENHANCEMENT_PLAN.md           # Enhancement roadmap
└── README.md                     # This file
```

## Quick Start

### Option 1: Automated Deployment (SnowSQL)

```bash
# 1. Clone/download this package
# 2. Configure SnowSQL connection
export SNOWFLAKE_ACCOUNT=your_account
export SNOWFLAKE_USER=your_user

# 3. Run deployment
./deploy.sh
```

### Option 2: Manual Step-by-Step

Run SQL scripts in order using Snowsight or SnowSQL:

```sql
-- Core: Execute SQL files 00-09 in order
-- Extensions: Execute SQL files 10-19 in order
```

Then deploy Cortex Agents:
```bash
snow cortex deploy --project-dir cortex_project/
```

### Option 3: GitHub Actions CI/CD

1. Copy `ci-cd/deploy.yml` to `.github/workflows/deploy.yml`
2. Set repository secrets:
   - `SNOWFLAKE_ACCOUNT`
   - `SNOWFLAKE_USER`
   - `SNOWFLAKE_PASSWORD`
   - `SNOWFLAKE_ACCOUNT_URL`
3. Push to `main` branch

## Multilingual Voice Input Pipeline

The dashboard supports **voice input in any language**, automatically translating to English before querying Cortex Agents. This uses two Snowflake Cortex AI functions in a pipeline:

### How It Works

```
┌──────────────┐     ┌──────────────────────┐     ┌──────────────────────┐     ┌──────────────┐
│  User speaks  │────>│  Browser Web Speech   │────>│  Snowflake           │────>│ Cortex Agent │
│  (any language)│     │  API (speech-to-text) │     │  AI_TRANSLATE(?, '', │     │ processes    │
│               │     │  useVoiceInput hook   │     │    'en')             │     │ English query│
└──────────────┘     └──────────────────────┘     └──────────────────────┘     └──────────────┘
       🎙️                   📝 transcript              🌐 auto-detect              🤖 agent
                                                       + translate to EN
```

### Step 1: Speech-to-Text (Web Speech API)

The `useVoiceInput` React hook (`dashboard/src/hooks/useVoiceInput.ts`) captures audio via the browser's built-in `SpeechRecognition` API:

- Supports continuous recording with interim results (real-time transcript preview)
- Works in Chrome, Edge, and Safari (shows "not supported" gracefully in Firefox)
- Handles microphone permissions, no-speech, and network errors
- States: `idle` → `recording` → `processing` → `idle`

```typescript
const voice = useVoiceInput(handleVoiceResult);
// voice.startRecording()  — starts listening
// voice.stopRecording()   — stops and delivers transcript
// voice.transcript        — final recognized text
// voice.interimTranscript — real-time preview while speaking
```

### Step 2: Language Detection + Translation (Snowflake AI_TRANSLATE)

The `detectAndTranslate` function (`dashboard/src/services/translate.ts`) calls Snowflake's **AI_TRANSLATE** Cortex function to auto-detect the source language and translate to English:

```sql
SELECT AI_TRANSLATE(?, '', 'en') AS translated
-- The empty string '' for source language triggers auto-detection.
-- The ? is a parameterized binding (SQL injection safe).
```

- **Auto-detection:** Passing `''` as the source language tells AI_TRANSLATE to detect the language automatically
- **SQL injection safe:** Uses `executeSQLWithBindings()` with positional bind parameters — user text never touches the SQL string
- **Graceful degradation:** If translation fails, the original text passes through unchanged
- **English passthrough:** A normalized comparison detects when input is already English and skips displaying the "translated from" banner

### Step 3: Translation Banner in UI

When translation occurs, the user sees a green banner:

```
🌐 Translated from: "¿Cuál es el ingreso total por tipo de póliza?"
```

The translated English text is placed in the input field and sent to the Cortex Agent.

### Pages with Voice + Translation Support (7 pages)

| Page | Agent Used | Voice | Translation |
|------|-----------|-------|-------------|
| AI Assistant | INSURANCE_INTELLIGENCE_AGENT | ✅ | ✅ |
| Enterprise Hub | UNIFIED_ENTERPRISE_AGENT | ✅ | ✅ |
| Market Intel | MARKET_INTELLIGENCE_AGENT | ✅ | ✅ |
| Pricing Advisor | PRICE_OPTIMIZATION_AGENT | ✅ | ✅ |
| Product Matcher | PRODUCT_MATCHING_AGENT | ✅ | ✅ |
| Knowledge Hub | CORTEX_SEARCH_SVC | ✅ | ✅ |
| Data Explorer | NL-to-SQL | ✅ | ✅ |

### Example Usage

1. Click the **🎙️ microphone button** next to the text input on any agent page
2. Speak your question in **any language** (Spanish, Hindi, French, Japanese, etc.)
3. The red recording indicator shows real-time transcription
4. Click the stop button — the transcript is sent to `AI_TRANSLATE`
5. A spinner shows "Detecting language & translating..."
6. The translated English text appears in the input field
7. A green banner shows the original text: *"Translated from: ..."*
8. Press Enter or click Send to query the agent with the English translation

### Technical Notes

- **No AI_TRANSCRIBE needed:** The browser's Web Speech API handles speech-to-text natively on the client side — no Snowflake compute is used for transcription. Only the translation step uses Snowflake.
- **Parameterized queries:** The `executeSQLWithBindings()` function sends user text as an out-of-band binding parameter to the Snowflake SQL API, preventing SQL injection even with adversarial input.
- **Supported languages:** AI_TRANSLATE supports 30+ languages including Spanish, French, German, Portuguese, Chinese, Japanese, Korean, Hindi, Arabic, Russian, and more.

## Snowflake Features Used

| Category | Feature | Usage |
|----------|---------|-------|
| **Cortex AI** | Cortex Agent | 5 agents with multi-tool orchestration |
| **Cortex AI** | Cortex Analyst (NL-to-SQL) | Text-to-SQL via 5 Semantic Views |
| **Cortex AI** | Cortex Search | RAG over 25 document chunks (Arctic Embed M v1.5) |
| **Cortex AI** | AI_TRANSLATE | Auto-detect + translate voice input to English (7 pages) |
| **Cortex AI** | Data-to-Chart | In-CoWork visualizations |
| **Semantic Layer** | Semantic Views | 5 views with 25+ Verified Queries (VQRs) |
| **Governance** | Object Tags | PII_LEVEL, BUSINESS_DOMAIN |
| **Governance** | Dynamic Masking | 3 policies: email, phone, address |
| **Governance** | Database Roles | 6 hierarchical roles (RBAC) |
| **Automation** | Streams | 3 CDC streams (claims, DQ results, document chunks) |
| **Automation** | Tasks | 3 tasks (DQ refresh, fraud flagging, DQ failure alert) |
| **Automation** | Alerts | 1 alert (DQ score drop monitor, every 12h) |
| **Platform** | Snowflake CoWork | Conversational BI for business users |
| **Platform** | MCP Connectors | Atlassian (Jira + Confluence) |
| **Platform** | Snowflake Intelligence | Account-level agent registry |
| **Cost Control** | Resource Monitor | 500 credits/month on COMPUTE_WH |
| **Cost Control** | Budget | 1000 credits/month (warehouse + serverless AI) |
| **Data** | Vector Embeddings | VECTOR(FLOAT, 768) for document similarity |
| **Data** | Stored Procedures | 6 procedures (JS + SQL), all parameterized |
| **Data** | Query Acceleration | Enabled on COMPUTE_WH |

## Agents

| Agent | Tools | Description |
|-------|-------|-------------|
| Insurance Intelligence | 2x Analyst + Search | Core ops, DQ, policy docs |
| Insurance Enterprise Hub | 6x Analyst + Search + Chart + MCP | All 6 domains + Jira |
| Market Intel | 2x Analyst + Chart + MCP | Trends, benchmarks, forecasting |
| Pricing Advisor | 2x Analyst + MCP | Competitive pricing analysis |
| Product Matcher | 2x Analyst + Search + MCP | Product-customer recommendations |

## MCP Connector Setup (Atlassian)

1. **Atlassian Admin:** Go to admin.atlassian.com → Apps → AI Settings → Rovo MCP Server
2. Add domain: `https://identity.snowflake.com/oauth2/callback`
3. **Snowflake:** Script `18_mcp_connectors.sql` creates the API integration and MCP server
4. **CoWork:** Each user must complete OAuth flow in CoWork → Capabilities → MCP Connectors

## React Dashboard Setup

```bash
cd dashboard
cp .env.example .env
# Edit .env with your Snowflake account URL

npm install
npm run dev
# Open http://localhost:3000
```

**Authentication:** Uses Snowflake Programmatic Access Tokens (PAT).

### Dashboard Pages

| Page | Description | Voice + AI_TRANSLATE |
|------|-------------|---------------------|
| Executive Dashboard | KPIs, premium by type, claims by status, DQ trends | — |
| KPI Dashboard | 30 KPIs across 5 pillars with embedded Agent chat | — |
| AI Assistant | Full Cortex Agent chat with tool traces | Mic + auto-translate |
| Knowledge Hub | Document browser + RAG-powered Q&A | Mic + auto-translate |
| Agent Insights | Agent configuration and tool routing | — |
| Document Intelligence | Summarize, classify, extract, compare documents | — |
| Data Explorer | NL-to-SQL + manual SQL editor | Mic + auto-translate |
| Governance | DQ scores, failed rules, column health | — |
| Admin Console | Session info and system status | — |
| Market Intel Agent | Market trends + industry benchmarks | Mic + auto-translate |
| Pricing Advisor Agent | Competitive pricing analysis | Mic + auto-translate |
| Product Matcher Agent | Product-customer recommendations | Mic + auto-translate |
| Enterprise Hub Agent | All 6 domains + Jira (unified) | Mic + auto-translate |

## Governance & Security

- **Masking Policies:** Email, phone, address masked for non-admin roles
- **Tags:** PII_LEVEL (HIGH/MEDIUM/LOW/NONE), BUSINESS_DOMAIN (7 domains)
- **RBAC:** 6 database roles with least-privilege hierarchy
- **Cortex Agent:** Grounded responses with source citations

## Prerequisites

| Tool | Purpose | Required |
|------|---------|----------|
| SnowSQL | Execute SQL scripts | Yes |
| Snowflake CLI (`snow`) | Deploy Cortex Agent | Recommended |
| Node.js 18+ | Build React dashboard | For dashboard |
| Account with Cortex AI | Semantic views, search, agent | Yes |
