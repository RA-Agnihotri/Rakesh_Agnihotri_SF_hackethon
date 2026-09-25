import streamlit as st

COLORS = ["#3b82f6", "#8b5cf6", "#22c55e", "#f59e0b", "#ef4444", "#06b6d4", "#ec4899", "#14b8a6", "#f97316", "#6366f1"]

DATABASE = "INSURANCE_AI_HUB"
SCHEMA = "ANALYTICS"


def get_conn():
    return st.session_state.get("sf_conn")


def run_query(sql, ttl_seconds=600):
    conn = get_conn()
    if conn is None:
        return None
    return conn.query(sql, ttl=ttl_seconds)
