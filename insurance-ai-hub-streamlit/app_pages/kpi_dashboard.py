import streamlit as st
from utils.queries import run_query

st.header("KPI Dashboard")

pillar = st.tabs(["Executive", "Claims", "Fraud", "Underwriting", "Data Trust"])

with pillar[0]:
    df = run_query("""
        SELECT COUNT(DISTINCT CUSTOMER_ID) AS CUSTOMERS,
               COUNT(CASE WHEN POLICY_STATUS='Active' THEN 1 END) AS ACTIVE_POLICIES,
               SUM(PREMIUM_AMOUNT) AS TOTAL_PREMIUM,
               ROUND(AVG(COVERAGE_AMOUNT),0) AS AVG_COVERAGE,
               ROUND(AVG(LOSS_RATIO),3) AS AVG_LOSS_RATIO,
               COUNT(DISTINCT AGENT_ID) AS ACTIVE_AGENTS
        FROM INSURANCE_AI_HUB.ANALYTICS.POLICIES
    """)
    if df is not None and len(df) > 0:
        r = df.iloc[0]
        with st.container(horizontal=True):
            st.metric("Customers", f"{r['CUSTOMERS']:,}", border=True)
            st.metric("Active Policies", f"{r['ACTIVE_POLICIES']:,}", border=True)
            st.metric("Total Premium", f"${r['TOTAL_PREMIUM']:,.0f}", border=True)
        with st.container(horizontal=True):
            st.metric("Avg Coverage", f"${r['AVG_COVERAGE']:,.0f}", border=True)
            st.metric("Avg Loss Ratio", f"{r['AVG_LOSS_RATIO']:.1%}", border=True)
            st.metric("Active Agents", f"{r['ACTIVE_AGENTS']:,}", border=True)

with pillar[1]:
    df = run_query("""
        SELECT COUNT(*) AS TOTAL_CLAIMS,
               COUNT(CASE WHEN CLAIM_STATUS='Open' THEN 1 END) AS OPEN_CLAIMS,
               COUNT(CASE WHEN CLAIM_STATUS='Closed' THEN 1 END) AS CLOSED_CLAIMS,
               ROUND(AVG(CLAIM_AMOUNT),2) AS AVG_CLAIM,
               ROUND(AVG(DAYS_TO_RESOLVE),1) AS AVG_DAYS,
               SUM(APPROVED_AMOUNT) AS TOTAL_APPROVED
        FROM INSURANCE_AI_HUB.ANALYTICS.CLAIMS
    """)
    if df is not None and len(df) > 0:
        r = df.iloc[0]
        with st.container(horizontal=True):
            st.metric("Total Claims", f"{r['TOTAL_CLAIMS']:,}", border=True)
            st.metric("Open", f"{r['OPEN_CLAIMS']:,}", border=True)
            st.metric("Closed", f"{r['CLOSED_CLAIMS']:,}", border=True)
        with st.container(horizontal=True):
            st.metric("Avg Claim Amount", f"${r['AVG_CLAIM']:,.0f}", border=True)
            st.metric("Avg Resolution Days", f"{r['AVG_DAYS']}", border=True)
            st.metric("Total Approved", f"${r['TOTAL_APPROVED']:,.0f}", border=True)

with pillar[2]:
    df = run_query("""
        SELECT COUNT(CASE WHEN FRAUD_FLAG THEN 1 END) AS FLAGGED,
               COUNT(CASE WHEN FRAUD_SCORE > 0.7 THEN 1 END) AS HIGH_RISK,
               ROUND(AVG(FRAUD_SCORE),3) AS AVG_SCORE,
               ROUND(MAX(FRAUD_SCORE),3) AS MAX_SCORE,
               SUM(CASE WHEN FRAUD_SCORE > 0.7 THEN CLAIM_AMOUNT ELSE 0 END) AS EXPOSURE
        FROM INSURANCE_AI_HUB.ANALYTICS.CLAIMS
    """)
    if df is not None and len(df) > 0:
        r = df.iloc[0]
        with st.container(horizontal=True):
            st.metric("Fraud-Flagged", f"{r['FLAGGED']:,}", border=True)
            st.metric("High-Risk (>0.7)", f"{r['HIGH_RISK']:,}", border=True)
            st.metric("Avg Fraud Score", f"{r['AVG_SCORE']:.3f}", border=True)
        with st.container(horizontal=True):
            st.metric("Max Fraud Score", f"{r['MAX_SCORE']:.3f}", border=True)
            st.metric("Fraud Exposure", f"${r['EXPOSURE']:,.0f}", border=True)

with pillar[3]:
    df = run_query("""
        SELECT ROUND(AVG(LOSS_RATIO),3) AS AVG_LOSS_RATIO,
               ROUND(AVG(PREMIUM_AMOUNT),2) AS AVG_PREMIUM,
               ROUND(AVG(DEDUCTIBLE),2) AS AVG_DEDUCTIBLE,
               COUNT(CASE WHEN LOSS_RATIO > 1.0 THEN 1 END) AS UNPROFITABLE
        FROM INSURANCE_AI_HUB.ANALYTICS.POLICIES WHERE POLICY_STATUS='Active'
    """)
    if df is not None and len(df) > 0:
        r = df.iloc[0]
        with st.container(horizontal=True):
            st.metric("Avg Loss Ratio", f"{r['AVG_LOSS_RATIO']:.1%}", border=True)
            st.metric("Avg Premium", f"${r['AVG_PREMIUM']:,.0f}", border=True)
            st.metric("Avg Deductible", f"${r['AVG_DEDUCTIBLE']:,.0f}", border=True)
            st.metric("Unprofitable Policies", f"{r['UNPROFITABLE']:,}", border=True)

with pillar[4]:
    df = run_query("""
        SELECT TABLE_NAME, OVERALL_SCORE, COMPLETENESS_SCORE, ACCURACY_SCORE,
               CONSISTENCY_SCORE, TIMELINESS_SCORE
        FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_SCORES
        QUALIFY ROW_NUMBER() OVER (PARTITION BY TABLE_NAME ORDER BY SCORE_DATE DESC) = 1
        ORDER BY OVERALL_SCORE ASC
    """)
    if df is not None:
        avg_score = df["OVERALL_SCORE"].mean()
        st.metric("Trusted Data Index", f"{avg_score:.1f}%", border=True)
        st.dataframe(df, use_container_width=True, hide_index=True)
