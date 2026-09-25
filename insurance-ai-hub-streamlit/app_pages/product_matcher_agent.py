import streamlit as st
from utils.agent_chat import render_agent_chat

st.header(":material/compare: Product Matcher Agent")
st.caption("Product eligibility, matching scores, coverage recommendations")

with st.container(horizontal=True):
    st.metric("Tools", "4", border=True)
    st.metric("Semantic Views", "3", border=True)
    st.metric("MCP Connectors", "1 (Jira)", border=True)

render_agent_chat(
    "PRODUCT_MATCHING_AGENT",
    suggestions=[
        "Which products best match a 35-year-old customer in the Northeast?",
        "Compare Gold vs Platinum Health plans for a family of four",
        "What coverage options are available for high-risk Auto profiles?",
        "Recommend a Life insurance plan for a customer with no dependents",
    ],
)
