import streamlit as st
from utils.agent_chat import render_agent_chat

st.header(":material/hub: Enterprise Hub Agent")
st.caption("Unified Enterprise Agent — 7 Cortex Analyst tools, Cortex Search, data-to-chart, Atlassian MCP")

with st.container(horizontal=True):
    st.metric("Tools", "10", border=True)
    st.metric("Semantic Views", "5", border=True)
    st.metric("MCP Connectors", "1 (Jira)", border=True)

render_agent_chat(
    "UNIFIED_ENTERPRISE_AGENT",
    suggestions=[
        "What is the total premium revenue by policy type for active policies?",
        "Which tables have the lowest data quality scores?",
        "Show me the top 5 claims by amount with fraud scores above 0.5",
        "Compare our loss ratios to industry benchmarks",
    ],
)
