import streamlit as st
from utils.queries import run_query

st.header(":material/menu_book: Knowledge Hub")
st.caption("Policy document browser and RAG-powered search")

col_docs, col_chat = st.columns([1, 2])

with col_docs:
    with st.container(border=True):
        st.subheader("Documents")
        docs = run_query("""
            SELECT d.DOCUMENT_ID, d.DOCUMENT_TITLE, d.DOCUMENT_TYPE, d.DOCUMENT_STATUS,
                   COUNT(c.CHUNK_ID) AS CHUNKS
            FROM INSURANCE_AI_HUB.DOCUMENTS.POLICY_DOCUMENTS d
            LEFT JOIN INSURANCE_AI_HUB.DOCUMENTS.DOCUMENT_CHUNKS c
              ON d.DOCUMENT_ID = c.DOCUMENT_ID
            GROUP BY d.DOCUMENT_ID, d.DOCUMENT_TITLE, d.DOCUMENT_TYPE, d.DOCUMENT_STATUS
            ORDER BY d.DOCUMENT_TITLE
        """)
        if docs is not None:
            st.dataframe(docs, use_container_width=True, hide_index=True,
                         column_config={"CHUNKS": st.column_config.NumberColumn("Chunks", format="%d")})

with col_chat:
    with st.container(border=True):
        st.subheader("Ask about Policy Documents")

        key = "messages_knowledge_hub"
        if key not in st.session_state:
            st.session_state[key] = []

        for msg in st.session_state[key]:
            with st.chat_message(msg["role"]):
                st.write(msg["content"])

        if prompt := st.chat_input("Search policy documents..."):
            st.session_state[key].append({"role": "user", "content": prompt})
            with st.chat_message("user"):
                st.write(prompt)

            with st.chat_message("assistant"):
                with st.spinner("Searching documents..."):
                    try:
                        conn = st.session_state.get("sf_conn")
                        result = conn.query(
                            """
                            SELECT SNOWFLAKE.CORTEX.COMPLETE(
                                'llama3.1-70b',
                                CONCAT('You are a policy document expert. Answer based on insurance policy knowledge: ', ?)
                            ) AS response
                            """,
                            params=[prompt],
                        )
                        response = result["RESPONSE"].iloc[0] if not result.empty else "No response."
                    except Exception as e:
                        response = f"Error: {e}"
                    st.write(response)

            st.session_state[key].append({"role": "assistant", "content": response})
            st.rerun()
