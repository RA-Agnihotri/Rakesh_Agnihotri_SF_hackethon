import streamlit as st
from utils.queries import run_query

st.header(":material/verified_user: Governance Dashboard")

dq = run_query("""
    SELECT TABLE_NAME, OVERALL_SCORE, COMPLETENESS_SCORE, ACCURACY_SCORE,
           CONSISTENCY_SCORE, TIMELINESS_SCORE, SCORE_DATE
    FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_SCORES
    QUALIFY ROW_NUMBER() OVER (PARTITION BY TABLE_NAME ORDER BY SCORE_DATE DESC) = 1
    ORDER BY OVERALL_SCORE ASC
""")

if dq is not None and len(dq) > 0:
    avg = dq["OVERALL_SCORE"].mean()
    low = (dq["OVERALL_SCORE"] < 70).sum()

    with st.container(horizontal=True):
        st.metric("Trusted Data Index", f"{avg:.1f}%", border=True)
        st.metric("Tables Monitored", f"{len(dq)}", border=True)
        st.metric("Below 70% Threshold", f"{low}", delta_color="inverse", border=True)

    with st.container(border=True):
        st.subheader("Table Health Scores")
        st.dataframe(
            dq,
            use_container_width=True,
            hide_index=True,
            column_config={
                "OVERALL_SCORE": st.column_config.ProgressColumn("Overall", min_value=0, max_value=100, format="%.1f%%"),
                "COMPLETENESS_SCORE": st.column_config.ProgressColumn("Complete", min_value=0, max_value=100, format="%.1f%%"),
                "ACCURACY_SCORE": st.column_config.ProgressColumn("Accuracy", min_value=0, max_value=100, format="%.1f%%"),
                "CONSISTENCY_SCORE": st.column_config.ProgressColumn("Consistent", min_value=0, max_value=100, format="%.1f%%"),
                "TIMELINESS_SCORE": st.column_config.ProgressColumn("Timely", min_value=0, max_value=100, format="%.1f%%"),
            },
        )

    with st.container(border=True):
        st.subheader("Quality Score Trend")
        trend = run_query("""
            SELECT SCORE_DATE, ROUND(AVG(OVERALL_SCORE), 1) AS AVG_SCORE
            FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_SCORES
            GROUP BY SCORE_DATE ORDER BY SCORE_DATE
        """)
        if trend is not None:
            st.line_chart(trend, x="SCORE_DATE", y="AVG_SCORE", color="#22c55e")

    with st.container(border=True):
        st.subheader("Failed Rules")
        failed = run_query("""
            SELECT r.TARGET_TABLE, r.TARGET_COLUMN, ru.RULE_NAME, ru.SEVERITY,
                   r.FAILED_RECORDS, r.ERROR_SAMPLE, r.EXECUTION_DATE
            FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_RESULTS r
            JOIN INSURANCE_AI_HUB.DATA_QUALITY.DQ_RULES ru ON r.RULE_ID = ru.RULE_ID
            WHERE r.STATUS = 'FAIL'
            ORDER BY ru.SEVERITY DESC, r.FAILED_RECORDS DESC
            LIMIT 20
        """)
        if failed is not None:
            st.dataframe(failed, use_container_width=True, hide_index=True)
