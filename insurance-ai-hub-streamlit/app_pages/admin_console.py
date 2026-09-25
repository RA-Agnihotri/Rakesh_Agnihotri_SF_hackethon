import streamlit as st
from utils.queries import run_query

st.header(":material/admin_panel_settings: Admin Console")

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
    st.subheader("Database Objects")
    objects = run_query("""
        SELECT TABLE_SCHEMA AS SCHEMA_NAME, TABLE_TYPE AS TYPE, COUNT(*) AS COUNT
        FROM INSURANCE_AI_HUB.INFORMATION_SCHEMA.TABLES
        GROUP BY TABLE_SCHEMA, TABLE_TYPE
        ORDER BY TABLE_SCHEMA, TABLE_TYPE
    """)
    if objects is not None and len(objects) > 0:
        st.dataframe(objects, use_container_width=True, hide_index=True)
    else:
        st.info("No objects found.")

with st.container(border=True):
    st.subheader("Masking Policies")
    policies = run_query("""
        SELECT POLICY_NAME AS name, POLICY_SCHEMA AS schema
        FROM TABLE(INSURANCE_AI_HUB.INFORMATION_SCHEMA.POLICY_REFERENCES(
            REF_ENTITY_DOMAIN => 'TABLE',
            REF_ENTITY_NAME => 'INSURANCE_AI_HUB.ANALYTICS.CUSTOMERS'
        ))
    """)
    if policies is not None and len(policies) > 0:
        st.dataframe(policies, use_container_width=True, hide_index=True)
    else:
        st.info("No masking policies attached to ANALYTICS tables.")

with st.container(border=True):
    st.subheader("Warehouse Usage (Last 7 Days)")
    usage = run_query("""
        SELECT WAREHOUSE_NAME, COUNT(*) AS QUERY_COUNT,
               ROUND(SUM(TOTAL_ELAPSED_TIME) / 1000, 1) AS TOTAL_SECONDS,
               ROUND(AVG(TOTAL_ELAPSED_TIME) / 1000, 2) AS AVG_SECONDS
        FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
          AND WAREHOUSE_NAME IS NOT NULL
        GROUP BY WAREHOUSE_NAME
        ORDER BY QUERY_COUNT DESC
    """)
    if usage is not None and len(usage) > 0:
        st.dataframe(usage, use_container_width=True, hide_index=True)
    else:
        st.info("No warehouse usage data available.")
