import json
import pandas as pd


def call_agent(agent_name, prompt, session, history=None):
    """Call a deployed Cortex Agent via the Snowflake REST API."""
    messages = list(history or [])
    messages.append({
        "role": "user",
        "content": [{"type": "text", "text": prompt}],
    })

    result = _send_request(agent_name, messages, session)
    return _parse_response(result, messages)


def _send_request(agent_name, messages, session):
    """Send POST to the agent :run endpoint using the Snowpark session."""
    import requests

    path = (
        f"/api/v2/databases/INSURANCE_AI_HUB/schemas/ANALYTICS"
        f"/agents/{agent_name}:run"
    )
    payload = {"messages": messages, "stream": False}

    # Extract host and token from the Snowpark session's connection
    snow_session = session.session()
    sf_conn = snow_session.connection
    host = sf_conn.host
    token = sf_conn.rest.token

    resp = requests.post(
        f"https://{host}{path}",
        headers={
            "Authorization": f'Snowflake Token="{token}"',
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
        json=payload,
        timeout=120,
    )
    resp.raise_for_status()
    return resp.json()

    
def _parse_response(result, messages):
    """Extract text, datasets, tool trace, and SQL from agent response."""
    content_blocks = result.get("content", [])
    if isinstance(content_blocks, str):
        content_blocks = [{"type": "text", "text": content_blocks}]

    text_parts = []
    datasets = []
    tool_trace = []
    sql = None

    for block in content_blocks:
        btype = block.get("type", "")

        if btype == "text" and block.get("text"):
            text_parts.append(block["text"])

        elif btype == "tool_use":
            tu = block.get("tool_use", block)
            trace = {
                "tool_name": tu.get("name", "tool"),
                "tool_type": tu.get("type", "unknown"),
            }
            inp = tu.get("input", {})
            if inp.get("sql"):
                trace["sql"] = inp["sql"]
                sql = inp["sql"]
            if inp.get("semantic_model"):
                trace["target"] = inp["semantic_model"]
            tool_trace.append(trace)

        elif btype == "tool_result":
            tr = block.get("tool_result", block)
            contents = tr.get("content", [])
            if not isinstance(contents, list):
                contents = [contents]
            for c in contents:
                if not isinstance(c, dict):
                    continue
                if c.get("type") == "json" and c.get("json"):
                    j = c["json"]
                    if j.get("sql"):
                        sql = j["sql"]
                    if j.get("semantic_model_path") and tool_trace:
                        tool_trace[-1]["target"] = j["semantic_model_path"]
                    df = _result_set_to_df(j.get("result_set", {}))
                    if df is not None:
                        datasets.append(df)

        elif btype == "table":
            rs = block.get("table", {}).get("result_set", {})
            df = _result_set_to_df(rs)
            if df is not None:
                datasets.append(df)

    messages.append({"role": "assistant", "content": content_blocks})

    text = "".join(text_parts)
    if not text and not datasets:
        text = "The agent processed your request but returned no text."

    return {
        "text": text,
        "datasets": datasets,
        "tool_trace": tool_trace,
        "sql": sql,
        "messages": messages,
    }


def _result_set_to_df(rs):
    """Convert a Snowflake result_set dict to a pandas DataFrame."""
    if not rs or not rs.get("data"):
        return None
    row_type = rs.get("resultSetMetaData", {}).get("rowType")
    if not row_type:
        return None
    cols = [col["name"] for col in row_type]
    return pd.DataFrame(rs["data"], columns=cols)
