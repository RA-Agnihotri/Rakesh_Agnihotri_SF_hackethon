import streamlit as st
from utils.queries import run_query

st.header(":material/admin_panel_settings: Admin Console")

conn = st.session_state.get("sf_conn")

with st.container(border=True):
    st.subheader("Session Information")
    session_info = run_query("""
        SELECT CURRENT_USER() AS USERNAME, CURRENT_ROLE() AS ROLE,
               CURRENT_WAREHOUSE() AS WAREHOUSE, CURRENT_DATABASE() AS DB,
               CURRENT_SCHEMA() AS SCHEMA_NAME, CURRENT_ACCOUNT() AS ACCOUNT
    """)
    if session_info is not None:
        r = session_info.iloc[0]
        with st.container(horizontal=True):
            st.metric("User", r["USERNAME"], border=True)
            st.metric("Role", r["ROLE"], border=True)
            st.metric("Warehouse", r["WAREHOUSE"], border=True)
        with st.container(horizontal=True):
            st.metric("Database", r["DB"], border=True)
            st.metric("Schema", r["SCHEMA_NAME"], border=True)
            st.metric("Account", r["ACCOUNT"], border=True)

with st.container(border=True):
    st.subheader("Database Roles")
    roles = run_query("SHOW DATABASE ROLES IN DATABASE INSURANCE_AI_HUB")
    if roles is not None:
        st.dataframe(roles[["name", "comment"]], use_container_width=True, hide_index=True)

with st.container(border=True):
    st.subheader("Masking Policies")
    policies = run_query("SHOW MASKING POLICIES IN SCHEMA INSURANCE_AI_HUB.ANALYTICS")
    if policies is not None:
        st.dataframe(policies[["name", "kind"]], use_container_width=True, hide_index=True)

with st.container(border=True):
    st.subheader("Resource Monitor")
    monitors = run_query("SHOW RESOURCE MONITORS")
    if monitors is not None:
        st.dataframe(monitors, use_container_width=True, hide_index=True)
