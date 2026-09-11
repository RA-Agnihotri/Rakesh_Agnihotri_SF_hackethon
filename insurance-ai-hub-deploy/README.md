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
│   └── 19_extended_rbac.sql          # Grants on new objects to existing roles
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
├── deploy.sh                     # One-command deployment script (13 phases)
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

## Snowflake Features Used

| Category | Feature | Usage |
|----------|---------|-------|
| **Cortex AI** | Cortex Agent | 5 agents with multi-tool orchestration |
| **Cortex AI** | Cortex Analyst (NL-to-SQL) | Text-to-SQL via 5 Semantic Views |
| **Cortex AI** | Cortex Search | RAG over 25 document chunks (Arctic Embed M v1.5) |
| **Cortex AI** | Data-to-Chart | In-CoWork visualizations |
| **Semantic Layer** | Semantic Views | 5 views with 25+ Verified Queries (VQRs) |
| **Governance** | Object Tags | PII_LEVEL, BUSINESS_DOMAIN |
| **Governance** | Dynamic Masking | 3 policies: email, phone, address |
| **Governance** | Database Roles | 6 hierarchical roles (RBAC) |
| **Platform** | Snowflake CoWork | Conversational BI for business users |
| **Platform** | MCP Connectors | Atlassian (Jira + Confluence) |
| **Platform** | Snowflake Intelligence | Account-level agent registry |
| **Data** | Vector Embeddings | VECTOR(FLOAT, 768) for document similarity |
| **Data** | Stored Procedures | 6 procedures (JS + SQL) |
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

| Page | Description |
|------|-------------|
| Executive Dashboard | KPIs, premium by type, claims by status, DQ trends |
| KPI Dashboard | 30 KPIs across 5 pillars with embedded Agent chat |
| AI Assistant | Full Cortex Agent chat with tool traces |
| Knowledge Hub | Document browser + RAG-powered Q&A |
| Agent Insights | Agent configuration and tool routing |
| Document Intelligence | Summarize, classify, extract, compare documents |
| Data Explorer | NL-to-SQL + manual SQL editor |
| Governance | DQ scores, failed rules, column health |
| Admin Console | Session info and system status |

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
