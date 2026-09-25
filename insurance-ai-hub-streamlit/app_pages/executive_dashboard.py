import streamlit as st
from utils.queries import run_query

st.header("Executive Dashboard")

kpi_sql = """
SELECT
    SUM(CASE WHEN p.POLICY_STATUS = 'Active' THEN p.PREMIUM_AMOUNT ELSE 0 END) AS total_premium,
    SUM(CASE WHEN p.POLICY_STATUS = 'Active' AND p.LOSS_RATIO > 0.8 THEN p.PREMIUM_AMOUNT ELSE 0 END) AS revenue_at_risk,
    COUNT(CASE WHEN p.POLICY_STATUS = 'Active' THEN 1 END) AS active_policies,
    COUNT(DISTINCT p.CUSTOMER_ID) AS total_customers,
    COUNT(DISTINCT c.CLAIM_ID) AS open_claims,
    ROUND(AVG(c.DAYS_TO_RESOLVE), 1) AS avg_resolution_days,
    COUNT(CASE WHEN c.FRAUD_SCORE > 0.7 THEN 1 END) AS high_risk_fraud,
    SUM(CASE WHEN c.FRAUD_SCORE > 0.7 THEN c.CLAIM_AMOUNT ELSE 0 END) AS fraud_exposure
FROM INSURANCE_AI_HUB.ANALYTICS.POLICIES p
LEFT JOIN INSURANCE_AI_HUB.ANALYTICS.CLAIMS c ON p.POLICY_ID = c.POLICY_ID
"""

df = run_query(kpi_sql)

if df is not None and len(df) > 0:
    row = df.iloc[0]

    with st.container(horizontal=True):
        st.metric("Premium Revenue", f"${row['TOTAL_PREMIUM']:,.0f}", border=True)
        st.metric("Revenue at Risk", f"${row['REVENUE_AT_RISK']:,.0f}", delta_color="inverse", border=True)
        st.metric("Active Policies", f"{row['ACTIVE_POLICIES']:,}", border=True)
        st.metric("Total Customers", f"{row['TOTAL_CUSTOMERS']:,}", border=True)

    with st.container(horizontal=True):
        st.metric("Open Claims", f"{row['OPEN_CLAIMS']:,}", border=True)
        st.metric("Avg Resolution (days)", f"{row['AVG_RESOLUTION_DAYS']}", border=True)
        st.metric("High-Risk Fraud Claims", f"{row['HIGH_RISK_FRAUD']:,}", delta_color="inverse", border=True)
        st.metric("Fraud Exposure", f"${row['FRAUD_EXPOSURE']:,.0f}", delta_color="inverse", border=True)

# Charts
col1, col2 = st.columns(2)

with col1:
    with st.container(border=True):
        st.subheader("Premium by Policy Type")
        premium_df = run_query("""
            SELECT POLICY_TYPE, SUM(PREMIUM_AMOUNT) AS PREMIUM
            FROM INSURANCE_AI_HUB.ANALYTICS.POLICIES
            WHERE POLICY_STATUS = 'Active'
            GROUP BY POLICY_TYPE ORDER BY PREMIUM DESC
        """)
        if premium_df is not None:
            st.bar_chart(premium_df, x="POLICY_TYPE", y="PREMIUM", color="#3b82f6")

with col2:
    with st.container(border=True):
        st.subheader("Claims by Status")
        claims_df = run_query("""
            SELECT CLAIM_STATUS, COUNT(*) AS COUNT
            FROM INSURANCE_AI_HUB.ANALYTICS.CLAIMS
            GROUP BY CLAIM_STATUS ORDER BY COUNT DESC
        """)
        if claims_df is not None:
            st.bar_chart(claims_df, x="CLAIM_STATUS", y="COUNT", color="#8b5cf6")

col3, col4 = st.columns(2)

with col3:
    with st.container(border=True):
        st.subheader("Data Quality Trend")
        dq_df = run_query("""
            SELECT SCORE_DATE, ROUND(AVG(OVERALL_SCORE), 1) AS AVG_SCORE
            FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_SCORES
            GROUP BY SCORE_DATE ORDER BY SCORE_DATE
        """)
        if dq_df is not None:
            st.line_chart(dq_df, x="SCORE_DATE", y="AVG_SCORE", color="#22c55e")

with col4:
    with st.container(border=True):
        st.subheader("Revenue at Risk by Category")
        risk_df = run_query("""
            SELECT POLICY_TYPE,
                   SUM(CASE WHEN LOSS_RATIO > 0.8 THEN PREMIUM_AMOUNT ELSE 0 END) AS AT_RISK
            FROM INSURANCE_AI_HUB.ANALYTICS.POLICIES
            WHERE POLICY_STATUS = 'Active'
            GROUP BY POLICY_TYPE ORDER BY AT_RISK DESC
        """)
        if risk_df is not None:
            st.bar_chart(risk_df, x="POLICY_TYPE", y="AT_RISK", color="#ef4444")
