import streamlit as st
from utils.queries import run_query
from utils.agent_client import call_agent

st.header(":material/database: Data Explorer")
st.caption("Run SQL queries or use natural language against Insurance AI Hub")

SCHEMA_OPTIONS = {"ANALYTICS": "INSURANCE_AI_HUB.ANALYTICS", "DOCUMENTS": "INSURANCE_AI_HUB.DOCUMENTS", "DATA_QUALITY": "INSURANCE_AI_HUB.DATA_QUALITY"}

schema = st.selectbox("Schema", list(SCHEMA_OPTIONS.keys()))

tables = run_query(f"""
    SELECT TABLE_NAME AS name, ROW_COUNT AS "rows", BYTES
    FROM INSURANCE_AI_HUB.INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = '{schema}'
    ORDER BY TABLE_NAME
""")
if tables is not None:
    with st.expander("Tables in schema"):
        st.dataframe(tables, use_container_width=True, hide_index=True)

tab_sql, tab_nl = st.tabs(["SQL Query", "Natural Language"])

with tab_sql:
    sql_input = st.text_area("Enter SQL", value=f"SELECT * FROM {SCHEMA_OPTIONS[schema]}.POLICIES LIMIT 10", height=120)
    if st.button("Run Query", type="primary", key="run_sql"):
        with st.spinner("Executing..."):
            result = run_query(sql_input, ttl_seconds=0)
            if result is not None:
                st.success(f"{len(result)} rows returned")
                st.dataframe(result, use_container_width=True, hide_index=True)

with tab_nl:
    nl_input = st.text_input("Ask in natural language", placeholder="e.g., Show me the top 10 policies by premium")
    if nl_input:
        with st.spinner("Querying via Insurance Intelligence Agent..."):
            try:
                conn = st.session_state.get("sf_conn")
                result = call_agent(
                    "INSURANCE_INTELLIGENCE_AGENT",
                    nl_input,
                    session=conn,
                )
                if result["text"]:
                    st.write(result["text"])
                if not result["text"] and result.get("datasets"):
                    for df in result["datasets"]:
                        st.dataframe(df, use_container_width=True, hide_index=True)
                if result.get("sql"):
                    with st.expander("Generated SQL"):
                        st.code(result["sql"], language="sql")
                if result.get("tool_trace"):
                    with st.expander(f"Tool Trace ({len(result['tool_trace'])} tool{'s' if len(result['tool_trace']) != 1 else ''} called)"):
                        for t in result["tool_trace"]:
                            cols = st.columns([2, 2, 3])
                            cols[0].markdown(f"**{t.get('tool_name', 'tool')}**")
                            cols[1].caption(t.get("tool_type", ""))
                            if t.get("target"):
                                cols[2].caption(f"-> {t['target']}")
            except Exception as e:
                st.error(f"Error: {e}")
