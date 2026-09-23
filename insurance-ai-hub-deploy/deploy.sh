#!/bin/bash
# ============================================================================
# Insurance AI Hub - Production Deployment Script
# ============================================================================
# Usage: ./deploy.sh [--skip-data] [--skip-dashboard]
#
# Prerequisites:
#   - SnowSQL installed and configured (or SNOWSQL env vars set)
#   - Node.js 18+ (for dashboard build)
#   - Snowflake CLI (for Cortex Agent deployment)
# ============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SKIP_DATA=false
SKIP_DASHBOARD=false

for arg in "$@"; do
  case $arg in
    --skip-data) SKIP_DATA=true ;;
    --skip-dashboard) SKIP_DASHBOARD=true ;;
  esac
done

log() { echo -e "${GREEN}[$(date +%H:%M:%S)]${NC} $1"; }
warn() { echo -e "${YELLOW}[$(date +%H:%M:%S)] WARNING:${NC} $1"; }
err() { echo -e "${RED}[$(date +%H:%M:%S)] ERROR:${NC} $1"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SQL_DIR="$SCRIPT_DIR/sql"

# Check SnowSQL
command -v snowsql >/dev/null 2>&1 || err "SnowSQL not found. Install from https://docs.snowflake.com/en/user-guide/snowsql"

SNOWSQL_OPTS="${SNOWSQL_OPTS:--o friendly=false -o header=true -o timing=true}"

run_sql() {
  local file="$1"
  local desc="$2"
  log "Running: $desc ($file)"
  snowsql $SNOWSQL_OPTS -f "$file" || err "Failed: $desc"
  log "Done: $desc"
}

echo ""
echo "============================================"
echo "  Insurance AI Hub - Production Deployment"
echo "============================================"
echo ""

# Phase 1: Infrastructure
log "PHASE 1: Infrastructure & Governance"
run_sql "$SQL_DIR/00_setup.sql" "Database, schemas, warehouse"
run_sql "$SQL_DIR/01_governance.sql" "Tags & masking policies"

# Phase 2: Schema Objects
log "PHASE 2: Schema Objects"
run_sql "$SQL_DIR/02_tables.sql" "13 tables (Analytics, Documents, Data Quality)"
run_sql "$SQL_DIR/03_views.sql" "4 analytical views"
run_sql "$SQL_DIR/04_semantic_views.sql" "2 semantic views with VQRs"
run_sql "$SQL_DIR/05_procedures.sql" "3 stored procedures"

# Phase 3: RBAC
log "PHASE 3: RBAC"
run_sql "$SQL_DIR/08_rbac.sql" "6 database roles + grant hierarchy"

# Phase 4: Seed Data
if [ "$SKIP_DATA" = false ]; then
  log "PHASE 4: Seed Data"
  run_sql "$SQL_DIR/09_seed_data.sql" "Sample data (~1,670 rows)"
else
  warn "Skipping seed data (--skip-data)"
fi

# Phase 5: Cortex Search
log "PHASE 5: Cortex Search Service"
run_sql "$SQL_DIR/06_cortex_search.sql" "Cortex Search on Document Chunks"

# Phase 6: Cortex Agent (original)
log "PHASE 6: Cortex Agent (Insurance Intelligence)"
if command -v snow >/dev/null 2>&1; then
  log "Deploying Cortex Agents via Snowflake CLI..."
  snow cortex deploy --project-dir "$SCRIPT_DIR/cortex_project/" || warn "Agent deployment failed - deploy manually via Snowsight"
else
  warn "Snowflake CLI not found. Deploy agent manually:"
  warn "  snow cortex deploy --project-dir cortex_project/"
  warn "  Or import via Snowsight: Projects > Cortex Projects > Import"
fi

# Phase 7: Enhancement - Extended Schema Objects
log "PHASE 7: Extended Tables & Views"
run_sql "$SQL_DIR/10_extended_tables.sql" "5 new tables (Product, Competitor, Market, Match, Scenarios)"
run_sql "$SQL_DIR/11_extended_views.sql" "3 new analytical views"
run_sql "$SQL_DIR/12_extended_semantic_views.sql" "3 new semantic views with VQRs"
run_sql "$SQL_DIR/13_extended_procedures.sql" "3 new stored procedures"

# Phase 8: Enhancement - Extended Seed Data
if [ "$SKIP_DATA" = false ]; then
  log "PHASE 8: Extended Seed Data"
  run_sql "$SQL_DIR/14_extended_seed_data.sql" "Sample data for new tables (~400 rows)"
else
  warn "Skipping extended seed data (--skip-data)"
fi

# Phase 9: Enhancement - MCP Connectors
log "PHASE 9: MCP Connectors"
run_sql "$SQL_DIR/18_mcp_connectors.sql" "Atlassian MCP connector (Jira + Confluence)"

# Phase 10: Enhancement - Specialized Agents
log "PHASE 10: Specialized Agents"
run_sql "$SQL_DIR/15_specialized_agents.sql" "3 domain agents (Market, Pricing, Product)"
run_sql "$SQL_DIR/16_unified_agent.sql" "Unified Enterprise Agent (7 tools + MCP)"

# Phase 11: Enhancement - CoWork Setup
log "PHASE 11: Snowflake CoWork Setup"
run_sql "$SQL_DIR/17_cowork_setup.sql" "Intelligence object + agent registration"

# Phase 12: Enhancement - Extended RBAC
log "PHASE 12: Extended RBAC"
run_sql "$SQL_DIR/19_extended_rbac.sql" "Grants on new objects to existing roles"

# Phase 13: Automation - Tasks, Streams, Alerts
log "PHASE 13: Tasks, Streams & Monitoring"
run_sql "$SQL_DIR/21_tasks_and_streams.sql" "3 streams + 3 tasks + 1 alert for production automation"

# Phase 14: Dashboard
if [ "$SKIP_DASHBOARD" = false ]; then
  log "PHASE 14: React Dashboard"
  if command -v npm >/dev/null 2>&1; then
    cd "$SCRIPT_DIR/dashboard"
    if [ ! -d node_modules ]; then
      log "Installing dashboard dependencies..."
      npm install
    fi
    log "Building dashboard..."
    npm run build
    log "Dashboard built in dashboard/dist/"
    cd "$SCRIPT_DIR"
  else
    warn "Node.js not found. Build dashboard manually: cd dashboard && npm install && npm run build"
  fi
else
  warn "Skipping dashboard build (--skip-dashboard)"
fi

echo ""
echo "============================================"
log "DEPLOYMENT COMPLETE"
echo "============================================"
echo ""
echo "Objects deployed:"
echo "  - 1 database (INSURANCE_AI_HUB)"
echo "  - 3 schemas (ANALYTICS, DOCUMENTS, DATA_QUALITY)"
echo "  - 18 tables with governance tags & masking policies"
echo "  - 7 analytical views"
echo "  - 5 semantic views (25+ verified queries)"
echo "  - 6 stored procedures"
echo "  - 1 Cortex Search service (Arctic Embed M v1.5)"
echo "  - 5 Cortex Agents (1 core + 3 domain + 1 unified enterprise)"
echo "  - 1 MCP Connector (Atlassian Jira + Confluence)"
echo "  - 1 Snowflake Intelligence (CoWork) object"
echo "  - 6 database roles with grant hierarchy"
echo "  - 2 tags + 3 masking policies"
echo ""
echo "Next steps:"
echo "  1. Update dashboard/.env with your Snowflake account URL"
echo "  2. Run: cd dashboard && npm run dev"
echo "  3. Open http://localhost:3000 and enter your PAT token"
echo "  4. Configure Atlassian domain: admin.atlassian.com > Apps > AI Settings > Rovo MCP Server"
echo "     Add domain: https://identity.snowflake.com/oauth2/callback"
echo "  5. In CoWork, authenticate with Atlassian via the MCP Connectors page"
echo ""
