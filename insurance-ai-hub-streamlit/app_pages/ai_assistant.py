import streamlit as st
from utils.agent_chat import render_agent_chat

st.header(":material/smart_toy: AI Assistant")
st.caption("Insurance Intelligence Agent — Analytics, Document Search, Data Quality")

render_agent_chat(
    "INSURANCE_INTELLIGENCE_AGENT",
    suggestions=[
        "What is the total premium by policy type?",
        "Show me the top claims by amount",
        "What are the fraud indicators in recent claims?",
        "Summarize the data quality scores across all tables",
    ],
)
