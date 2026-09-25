import streamlit as st
from utils.queries import run_query

st.header(":material/description: Document Intelligence")
st.caption("Summarize, extract fields, and classify insurance documents using Cortex AI")

docs = run_query("""
    SELECT DOCUMENT_ID, DOCUMENT_TITLE, DOCUMENT_TYPE, DOCUMENT_STATUS
    FROM INSURANCE_AI_HUB.DOCUMENTS.POLICY_DOCUMENTS
    ORDER BY DOCUMENT_TITLE
""")

if docs is not None and len(docs) > 0:
    selected = st.selectbox("Select a document", docs["DOCUMENT_TITLE"].tolist())
    doc_id = docs[docs["DOCUMENT_TITLE"] == selected]["DOCUMENT_ID"].iloc[0]

    conn = st.session_state.get("sf_conn")
    chunks = conn.query(
        """
        SELECT CHUNK_ID, SECTION_TITLE, CHUNK_TEXT
        FROM INSURANCE_AI_HUB.DOCUMENTS.DOCUMENT_CHUNKS
        WHERE DOCUMENT_ID = ?
        ORDER BY CHUNK_ID
        """,
        params=[doc_id],
    ) if conn else None

    col1, col2 = st.columns(2)

    with col1:
        with st.container(border=True):
            st.subheader("Document Chunks")
            if chunks is not None:
                st.dataframe(chunks[["SECTION_TITLE", "CHUNK_TEXT"]], use_container_width=True, hide_index=True)

    with col2:
        action = st.radio("AI Action", ["Summarize", "Extract Fields", "Classify"], horizontal=True)
        with st.container(border=True):
            if st.button("Run", type="primary"):
                with st.spinner("Processing..."):
                    try:
                        full_text = " ".join(chunks["CHUNK_TEXT"].tolist()) if chunks is not None and len(chunks) > 0 else ""

                        if action == "Summarize":
                            result = conn.query(
                                "SELECT SNOWFLAKE.CORTEX.SUMMARIZE(?) AS result",
                                params=[full_text[:4000]],
                            )
                        elif action == "Extract Fields":
                            result = conn.query(
                                """SELECT SNOWFLAKE.CORTEX.COMPLETE('llama3.1-70b',
                                   CONCAT('Extract key fields (coverage, premium, deductible, exclusions) from: ', ?)
                                ) AS result""",
                                params=[full_text[:4000]],
                            )
                        else:
                            result = conn.query(
                                """SELECT SNOWFLAKE.CORTEX.CLASSIFY_TEXT(
                                    ?,
                                    ['Policy Terms', 'Coverage Details', 'Claims Procedure', 'Exclusions', 'Benefits']
                                )::STRING AS result""",
                                params=[full_text[:2000]],
                            )

                        st.write(result["RESULT"].iloc[0] if not result.empty else "No result")
                    except Exception as e:
                        st.error(f"Error: {e}")
