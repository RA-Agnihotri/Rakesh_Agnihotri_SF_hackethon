import streamlit as st
from utils.queries import run_query

st.header(":material/insights: Agent Insights")
st.caption("Status and configuration of deployed Cortex Agents")

AGENTS = [
    {"name": "INSURANCE_INTELLIGENCE_AGENT", "tools": 3, "icon": ":material/smart_toy:", "desc": "General insurance analytics + document search + data quality"},
    {"name": "UNIFIED_ENTERPRISE_AGENT", "tools": 10, "icon": ":material/hub:", "desc": "7 Analyst + Search + Chart + MCP (Jira)"},
    {"name": "MARKET_INTELLIGENCE_AGENT", "tools": 4, "icon": ":material/trending_up:", "desc": "Market trends + competitor benchmarks + MCP"},
    {"name": "PRICE_OPTIMIZATION_AGENT", "tools": 3, "icon": ":material/attach_money:", "desc": "Pricing analysis + competitive comparison + MCP"},
    {"name": "PRODUCT_MATCHING_AGENT", "tools": 4, "icon": ":material/compare:", "desc": "Product eligibility + matching + coverage recs + MCP"},
]

with st.container(horizontal=True):
    st.metric("Total Agents", "5", border=True)
    st.metric("Total Tools", "24", border=True)
    st.metric("Semantic Views", "5", border=True)
    st.metric("MCP Connectors", "1 (Atlassian Jira)", border=True)

for agent in AGENTS:
    with st.container(border=True):
        col1, col2, col3 = st.columns([1, 3, 1])
        with col1:
            st.markdown(f"### {agent['icon']}")
        with col2:
            st.markdown(f"**{agent['name']}**")
            st.caption(agent["desc"])
        with col3:
            st.metric("Tools", agent["tools"])

with st.container(border=True):
    st.subheader("CoWork Registration")
    st.info("All 5 agents are registered in the Snowflake Intelligence object (SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT) for business user access via CoWork.")
