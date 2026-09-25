import streamlit as st


def kpi_card(label, value, delta=None, delta_color="normal"):
    st.metric(label, value, delta=delta, delta_color=delta_color, border=True)
