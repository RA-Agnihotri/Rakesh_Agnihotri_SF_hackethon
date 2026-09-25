import streamlit as st
from utils.agent_client import call_agent


def render_agent_chat(agent_name, suggestions=None):
    conn = st.session_state.get("sf_conn")
    if conn is None:
        st.error("No Snowflake connection available.")
        return

    msg_key = f"messages_{agent_name}"
    hist_key = f"history_{agent_name}"
    pending_key = f"pending_{agent_name}"
    if msg_key not in st.session_state:
        st.session_state[msg_key] = []
    if hist_key not in st.session_state:
        st.session_state[hist_key] = []

    if suggestions and not st.session_state[msg_key] and pending_key not in st.session_state:
        selected = st.pills("Try asking:", suggestions, label_visibility="collapsed")
        if selected:
            st.session_state[pending_key] = selected
            st.rerun()

    # Determine prompt: either from pending pill selection or chat input
    prompt = st.session_state.pop(pending_key, None)

    for msg in st.session_state[msg_key]:
        with st.chat_message(msg["role"]):
            if msg.get("content"):
                st.write(msg["content"])
            if not msg.get("content") and msg.get("datasets"):
                for df in msg["datasets"]:
                    st.dataframe(df, use_container_width=True, hide_index=True)
            if msg.get("tool_trace"):
                _render_tool_trace(msg["tool_trace"], msg.get("sql"))

    if not prompt:
        prompt = st.chat_input(f"Ask {agent_name}...")

    if prompt:
        st.session_state[msg_key].append({"role": "user", "content": prompt})
        with st.chat_message("user"):
            st.write(prompt)

        with st.chat_message("assistant"):
            with st.spinner("Agent is thinking..."):
                try:
                    result = call_agent(
                        agent_name,
                        prompt,
                        session=conn,
                        history=st.session_state[hist_key],
                    )
                    response_text = result["text"]
                    datasets = result.get("datasets", [])
                    tool_trace = result.get("tool_trace", [])
                    sql = result.get("sql")
                    st.session_state[hist_key] = result["messages"]
                except Exception as e:
                    response_text = f"Agent error: {e}"
                    datasets = []
                    tool_trace = []
                    sql = None

                if response_text:
                    st.write(response_text)
                if not response_text and datasets:
                    for df in datasets:
                        st.dataframe(df, use_container_width=True, hide_index=True)
                if tool_trace:
                    _render_tool_trace(tool_trace, sql)

        entry = {"role": "assistant", "content": response_text}
        if datasets:
            entry["datasets"] = datasets
        if tool_trace:
            entry["tool_trace"] = tool_trace
        if sql:
            entry["sql"] = sql
        st.session_state[msg_key].append(entry)
        st.rerun()


def _render_tool_trace(trace, sql=None):
    count = len(trace)
    label = f"Tool Trace ({count} tool{'s' if count != 1 else ''} called)"
    with st.expander(label):
        for t in trace:
            cols = st.columns([2, 2, 3])
            cols[0].markdown(f"**{t.get('tool_name', 'tool')}**")
            cols[1].caption(t.get("tool_type", ""))
            if t.get("target"):
                cols[2].caption(f"-> {t['target']}")
        if sql:
            st.code(sql, language="sql")
