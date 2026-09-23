import { SNOWFLAKE_CONFIG } from '../lib/constants';

let authToken: string | null = null;

export function setToken(token: string) { authToken = token; }
export function getToken(): string | null { return authToken; }
export function clearToken() { authToken = null; }

function getBaseUrl(): string {
  if (import.meta.env.DEV) return '';
  return SNOWFLAKE_CONFIG.accountUrl;
}

function getAuthHeaders(token: string): Record<string, string> {
  return {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-Snowflake-Authorization-Token-Type': 'PROGRAMMATIC_ACCESS_TOKEN',
  };
}

async function fetchWithRetry(url: string, options: RequestInit, retries = 3): Promise<Response> {
  for (let attempt = 0; attempt <= retries; attempt++) {
    try {
      const resp = await fetch(url, options);
      // Retry on 502 from proxy error handler
      if (resp.status === 502 && attempt < retries) {
        await new Promise(r => setTimeout(r, 1000 * (attempt + 1)));
        continue;
      }
      return resp;
    } catch (err: any) {
      if (attempt < retries) {
        await new Promise(r => setTimeout(r, 1000 * (attempt + 1)));
        continue;
      }
      throw err;
    }
  }
  throw new Error('Request failed after retries');
}

export async function executeSQL(sql: string): Promise<any> {
  const token = getToken();
  if (!token) throw new Error('Not authenticated. Please enter your PAT token.');

  const baseUrl = getBaseUrl();

  // Use async=false so Snowflake waits up to 45s for result inline
  // This avoids the poll request that causes ECONNRESET
  const resp = await fetchWithRetry(`${baseUrl}/api/v2/statements?async=false`, {
    method: 'POST',
    headers: getAuthHeaders(token),
    body: JSON.stringify({
      statement: sql,
      warehouse: SNOWFLAKE_CONFIG.warehouse,
      database: SNOWFLAKE_CONFIG.database,
      schema: SNOWFLAKE_CONFIG.schema,
      role: SNOWFLAKE_CONFIG.role,
      timeout: 120,
    }),
  });

  if (!resp.ok) {
    const err = await resp.json().catch(() => ({}));
    if (resp.status === 401 || resp.status === 403) {
      clearToken();
      throw new Error('Authentication failed. Please check your PAT token.');
    }
    throw new Error(err.message || `SQL API error: ${resp.status}`);
  }

  const result = await resp.json();

  // If Snowflake still returns async (query takes >45s), fall back to polling
  if (result.statementStatusUrl && !result.data) {
    return pollResult(result.statementHandle, token);
  }

  return parseResult(result);
}

async function pollResult(handle: string, token: string, maxAttempts = 60): Promise<any> {
  const baseUrl = getBaseUrl();
  for (let i = 0; i < maxAttempts; i++) {
    await new Promise(r => setTimeout(r, 2000));
    try {
      const resp = await fetchWithRetry(
        `${baseUrl}/api/v2/statements/${handle}`,
        { headers: getAuthHeaders(token) },
        2
      );
      if (!resp.ok) continue;
      const result = await resp.json();
      if (result.statementStatusUrl && !result.data) continue;
      return parseResult(result);
    } catch {
      continue;
    }
  }
  throw new Error('Query timed out');
}

// Parameterized SQL execution — use this for any query with user-supplied values.
// Bindings prevent SQL injection by sending values out-of-band from the SQL text.
export async function executeSQLWithBindings(
  sql: string,
  bindings: Record<string, { type: string; value: string }> | Array<{ type: string; value: string }>
): Promise<any> {
  const token = getToken();
  if (!token) throw new Error('Not authenticated. Please enter your PAT token.');

  const baseUrl = getBaseUrl();

  // Convert array bindings to positional map: {"1": {...}, "2": {...}}
  let bindingsMap: Record<string, { type: string; value: string }>;
  if (Array.isArray(bindings)) {
    bindingsMap = {};
    bindings.forEach((b, i) => { bindingsMap[String(i + 1)] = b; });
  } else {
    bindingsMap = bindings;
  }

  const resp = await fetchWithRetry(`${baseUrl}/api/v2/statements?async=false`, {
    method: 'POST',
    headers: getAuthHeaders(token),
    body: JSON.stringify({
      statement: sql,
      warehouse: SNOWFLAKE_CONFIG.warehouse,
      database: SNOWFLAKE_CONFIG.database,
      schema: SNOWFLAKE_CONFIG.schema,
      role: SNOWFLAKE_CONFIG.role,
      timeout: 120,
      bindings: bindingsMap,
    }),
  });

  if (!resp.ok) {
    const err = await resp.json().catch(() => ({}));
    if (resp.status === 401 || resp.status === 403) {
      clearToken();
      throw new Error('Authentication failed. Please check your PAT token.');
    }
    throw new Error(err.message || `SQL API error: ${resp.status}`);
  }

  const result = await resp.json();
  if (result.statementStatusUrl && !result.data) {
    return pollResult(result.statementHandle, token);
  }
  return parseResult(result);
}

function parseResult(result: any) {
  const columns = result.resultSetMetaData?.rowType?.map((c: any) => ({
    name: c.name,
    type: c.type,
  })) || [];
  const data = result.data || [];
  return { columns, data, rowCount: result.resultSetMetaData?.numRows || 0 };
}
