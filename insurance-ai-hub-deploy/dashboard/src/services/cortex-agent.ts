import { SNOWFLAKE_CONFIG } from '../lib/constants';
import { getToken } from './snowflake-api';

function getBaseUrl(): string {
  if (import.meta.env.DEV) return '';
  return SNOWFLAKE_CONFIG.accountUrl;
}

export interface AgentResponse {
  text: string;
  toolTrace: ToolTraceItem[];
  sql?: string;
  tableData?: { columns: string[]; rows: string[][] };
  requestId?: string;
}

export interface ToolTraceItem {
  toolName: string;
  toolType: string;
  target?: string;
  sql?: string;
  status: 'success' | 'error';
}

let conversationHistory: Array<{ role: string; content: any }> = [];

export function clearConversation() {
  conversationHistory = [];
}

export async function runAgentQuery(question: string): Promise<AgentResponse> {
  const token = getToken();
  if (!token) throw new Error('Not authenticated');

  conversationHistory.push({
    role: 'user',
    content: [{ type: 'text', text: question }],
  });

  const baseUrl = getBaseUrl();

  // Use the agent object endpoint — this picks up the agent's configured tools
  // Format: /api/v2/databases/{db}/schemas/{schema}/agents/{name}:run
  const agentUrl = `${baseUrl}/api/v2/databases/INSURANCE_AI_HUB/schemas/ANALYTICS/agents/INSURANCE_INTELLIGENCE_AGENT:run`;

  const resp = await fetch(agentUrl, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Snowflake-Authorization-Token-Type': 'PROGRAMMATIC_ACCESS_TOKEN',
    },
    body: JSON.stringify({
      messages: conversationHistory,
      stream: false,
    }),
  });

  if (!resp.ok) {
    const errText = await resp.text();
    // Remove last message on failure
    conversationHistory.pop();
    throw new Error(`Agent API ${resp.status}: ${errText.substring(0, 300)}`);
  }

  // With stream: false, we get a single JSON response
  const contentType = resp.headers.get('content-type') || '';
  let result: any;

  if (contentType.includes('text/event-stream')) {
    // Fallback: parse SSE if server still streams
    result = await parseSSEResponse(await resp.text());
  } else {
    result = await resp.json();
  }

  // Parse the response
  const content = result.content || [];
  const textParts: string[] = [];
  const toolTrace: ToolTraceItem[] = [];
  let sql: string | undefined;
  let tableData: { columns: string[]; rows: string[][] } | undefined;

  for (const block of content) {
    if (block.type === 'text' && block.text) {
      textParts.push(block.text);
    }

    if (block.type === 'tool_use') {
      const tu = block.tool_use || block;
      const traceItem: ToolTraceItem = {
        toolName: tu.name || tu.input?.semantic_model || 'tool',
        toolType: tu.type || 'unknown',
        status: 'success',
      };
      if (tu.input?.sql) { traceItem.sql = tu.input.sql; sql = tu.input.sql; }
      if (tu.input?.semantic_model) traceItem.target = tu.input.semantic_model;
      toolTrace.push(traceItem);
    }

    if (block.type === 'tool_result') {
      const tr = block.tool_result || block;
      const contents = tr.content || [];
      for (const c of (Array.isArray(contents) ? contents : [contents])) {
        if (c.type === 'json' && c.json) {
          if (c.json.sql) sql = c.json.sql;
          if (c.json.semantic_model_path) {
            const last = toolTrace[toolTrace.length - 1];
            if (last) last.target = c.json.semantic_model_path;
          }
          if (c.json.result_set?.data && c.json.result_set?.resultSetMetaData?.rowType) {
            const cols = c.json.result_set.resultSetMetaData.rowType.map((col: any) => col.name);
            const rows = c.json.result_set.data;
            tableData = { columns: cols, rows };
            if (cols.length > 0 && rows.length > 0) {
              const header = '| ' + cols.join(' | ') + ' |';
              const sep = '| ' + cols.map(() => '---').join(' | ') + ' |';
              const dataRows = rows.slice(0, 25).map((r: string[]) => '| ' + r.map(v => v ?? 'NULL').join(' | ') + ' |');
              textParts.push('\n' + [header, sep, ...dataRows].join('\n') + '\n');
              if (rows.length > 25) textParts.push(`\n*...and ${rows.length - 25} more rows*\n`);
            }
          }
        }
      }
    }

    if (block.type === 'table' && block.table?.result_set) {
      const rs = block.table.result_set;
      if (rs.data && rs.resultSetMetaData?.rowType) {
        tableData = { columns: rs.resultSetMetaData.rowType.map((c: any) => c.name), rows: rs.data };
      }
    }
  }

  // Store assistant response for multi-turn
  conversationHistory.push({ role: 'assistant', content });

  return {
    text: textParts.join('') || 'The agent processed your request but returned no text.',
    toolTrace,
    sql,
    tableData,
    requestId: result.request_id,
  };
}

// Fallback SSE parser in case stream: false is ignored
function parseSSEResponse(rawText: string): any {
  const contentBlocks: any[] = [];
  let requestId: string | undefined;

  for (const line of rawText.split('\n')) {
    if (!line.startsWith('data: ')) continue;
    const jsonStr = line.slice(6).trim();
    if (!jsonStr || jsonStr === '[DONE]') continue;
    try {
      const event = JSON.parse(jsonStr);
      if (event.request_id) requestId = event.request_id;
      if (event.delta?.content) contentBlocks.push(...event.delta.content);
      if (event.content) contentBlocks.push(...(Array.isArray(event.content) ? event.content : [event.content]));
    } catch {}
  }

  return { content: contentBlocks, request_id: requestId };
}
