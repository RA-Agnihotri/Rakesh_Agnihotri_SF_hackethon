import streamlit as st
from utils.agent_chat import render_agent_chat

st.header(":material/trending_up: Market Intelligence Agent")
st.caption("Market trends, competitor benchmarking, regulatory changes")

with st.container(horizontal=True):
    st.metric("Tools", "4", border=True)
    st.metric("Semantic Views", "2", border=True)
    st.metric("MCP Connectors", "1 (Jira)", border=True)

render_agent_chat(
    "MARKET_INTELLIGENCE_AGENT",
    suggestions=[
        "What are the key market trends for Health insurance?",
        "Which policy types have the fastest premium growth?",
        "How do our loss ratios compare to industry benchmarks?",
        "What regulatory changes are affecting the insurance market?",
    ],
)
