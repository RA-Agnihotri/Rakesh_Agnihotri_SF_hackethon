import streamlit as st
from utils.agent_chat import render_agent_chat

st.header(":material/attach_money: Pricing Advisor Agent")
st.caption("Competitive pricing analysis, premium optimization, price positioning")

with st.container(horizontal=True):
    st.metric("Tools", "3", border=True)
    st.metric("Semantic Views", "2", border=True)
    st.metric("MCP Connectors", "1 (Jira)", border=True)

render_agent_chat(
    "PRICE_OPTIMIZATION_AGENT",
    suggestions=[
        "How do our premiums compare to competitors for Health insurance?",
        "Which plan tiers have the widest price gap vs competitors?",
        "Show competitor pricing for Auto insurance in the West region",
        "What is our market share by policy type?",
    ],
)
