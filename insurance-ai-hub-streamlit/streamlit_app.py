import os
import streamlit as st

st.set_page_config(
    page_title="Insurance AI Hub",
    page_icon=":material/shield:",
    layout="wide",
)

conn = st.connection("snowflake", ttl=os.getenv("SNOWFLAKE_CONNECTION_TTL"))
st.session_state["sf_conn"] = conn

page = st.navigation(
    {
        "Dashboards": [
            st.Page("app_pages/executive_dashboard.py", title="Executive Dashboard", icon=":material/dashboard:"),
            st.Page("app_pages/kpi_dashboard.py", title="KPI Dashboard", icon=":material/monitoring:"),
            st.Page("app_pages/governance_dashboard.py", title="Governance", icon=":material/verified_user:"),
        ],
        "AI Agents": [
            st.Page("app_pages/enterprise_hub_agent.py", title="Enterprise Hub", icon=":material/hub:"),
            st.Page("app_pages/market_intel_agent.py", title="Market Intel", icon=":material/trending_up:"),
            st.Page("app_pages/pricing_advisor_agent.py", title="Pricing Advisor", icon=":material/attach_money:"),
            st.Page("app_pages/product_matcher_agent.py", title="Product Matcher", icon=":material/compare:"),
        ],
        "Intelligence": [
            st.Page("app_pages/ai_assistant.py", title="AI Assistant", icon=":material/smart_toy:"),
            st.Page("app_pages/knowledge_hub.py", title="Knowledge Hub", icon=":material/menu_book:"),
            st.Page("app_pages/document_intelligence.py", title="Documents", icon=":material/description:"),
            st.Page("app_pages/data_explorer.py", title="Data Explorer", icon=":material/database:"),
        ],
        "Admin": [
            st.Page("app_pages/agent_insights.py", title="Agent Insights", icon=":material/insights:"),
            st.Page("app_pages/admin_console.py", title="Admin Console", icon=":material/admin_panel_settings:"),
        ],
    },
    position="sidebar",
)

page.run()
