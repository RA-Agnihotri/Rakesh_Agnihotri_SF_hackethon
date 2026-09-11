import { useState } from 'react';
import { Database, Play, Copy, ChevronRight, Loader2, AlertCircle, CheckCircle, Sparkles, Send, ArrowDown, Bot } from 'lucide-react';
import { executeSQL } from '../services/snowflake-api';
import { getToken } from '../services/snowflake-api';

const SCHEMA_TREE = [
  { schema: 'ANALYTICS', tables: ['AGENTS', 'CUSTOMERS', 'POLICIES', 'CLAIMS', 'BILLING', 'AT_RISK_POLICIES'] },
  { schema: 'DOCUMENTS', tables: ['POLICY_DOCUMENTS', 'DOCUMENT_CHUNKS'] },
  { schema: 'DATA_QUALITY', tables: ['DQ_RULES', 'DQ_RESULTS', 'DQ_SCORES', 'DQ_COLUMN_HEALTH'] },
];

const NL_SUGGESTIONS = [
  'Show total premium revenue by policy type for active policies',
  'Which claims have fraud score above 0.7?',
  'What is the average resolution time by claim type?',
  'Top 5 customers by total premium amount',
  'Show data quality scores for all tables sorted by score',
  'How many at-risk policies are there by risk category?',
];

function getBaseUrl(): string {
  if (import.meta.env.DEV) return '';
  return import.meta.env.VITE_SNOWFLAKE_ACCOUNT_URL || '';
}

export default function DataExplorer() {
  const [sql, setSQL] = useState("SELECT POLICY_TYPE, POLICY_STATUS, COUNT(*) AS CNT,\n  SUM(PREMIUM_AMOUNT) AS TOTAL_PREMIUM,\n  ROUND(AVG(LOSS_RATIO), 2) AS AVG_LOSS_RATIO\nFROM INSURANCE_AI_HUB.ANALYTICS.POLICIES\nGROUP BY POLICY_TYPE, POLICY_STATUS\nORDER BY TOTAL_PREMIUM DESC;");
  const [results, setResults] = useState<any>(null);
  const [running, setRunning] = useState(false);
  const [error, setError] = useState('');
  const [expanded, setExpanded] = useState<string[]>(['ANALYTICS']);

  // NL-to-SQL state
  const [nlQuery, setNlQuery] = useState('');
  const [nlLoading, setNlLoading] = useState(false);
  const [nlError, setNlError] = useState('');
  const [generatedSQL, setGeneratedSQL] = useState('');
  const [nlExplanation, setNlExplanation] = useState('');

  const toggle = (schema: string) => setExpanded(e => e.includes(schema) ? e.filter(s => s !== schema) : [...e, schema]);

  const runQuery = async (sqlToRun?: string) => {
    const q = sqlToRun || sql;
    setRunning(true);
    setError('');
    setResults(null);
    try {
      const r = await executeSQL(q);
      setResults(r);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setRunning(false);
    }
  };

  const insertTable = (schema: string, table: string) => {
    setSQL((prev) => prev + `\n-- INSURANCE_AI_HUB.${schema}.${table}`);
  };

  // Natural Language → SQL via Cortex Agent
  const handleNLQuery = async (question?: string) => {
    const q = (question || nlQuery).trim();
    if (!q || nlLoading) return;
    setNlLoading(true);
    setNlError('');
    setGeneratedSQL('');
    setNlExplanation('');

    try {
      const token = getToken();
      if (!token) throw new Error('Not authenticated');

      const baseUrl = getBaseUrl();
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
          messages: [{ role: 'user', content: [{ type: 'text', text: q }] }],
          stream: false,
        }),
      });

      if (!resp.ok) throw new Error(`Agent API ${resp.status}: ${(await resp.text()).substring(0, 200)}`);

      // Parse response — could be JSON or SSE
      const contentType = resp.headers.get('content-type') || '';
      let content: any[] = [];

      if (contentType.includes('text/event-stream')) {
        const rawText = await resp.text();
        for (const line of rawText.split('\n')) {
          if (!line.startsWith('data: ')) continue;
          try {
            const event = JSON.parse(line.slice(6).trim());
            if (event.delta?.content) content.push(...event.delta.content);
            if (event.content) content.push(...(Array.isArray(event.content) ? event.content : [event.content]));
          } catch {}
        }
      } else {
        const result = await resp.json();
        content = result.content || [];
      }

      // Extract SQL and text from response
      let foundSQL = '';
      let explanation = '';

      for (const block of content) {
        if (block.type === 'text' && block.text) {
          explanation += block.text;
        }
        if (block.type === 'tool_use') {
          const tu = block.tool_use || block;
          if (tu.input?.sql) foundSQL = tu.input.sql;
        }
        if (block.type === 'tool_result') {
          const tr = block.tool_result || block;
          for (const c of (Array.isArray(tr.content) ? tr.content : [tr.content || {}])) {
            if (c.type === 'json' && c.json?.sql) foundSQL = c.json.sql;
          }
        }
      }

      if (foundSQL) {
        setGeneratedSQL(foundSQL);
        setSQL(foundSQL);
        setNlExplanation(explanation || 'SQL generated by Cortex Analyst.');
        // Auto-execute the generated SQL
        await runQuery(foundSQL);
      } else {
        setNlExplanation(explanation || 'The agent responded but did not generate SQL.');
      }

    } catch (err: any) {
      setNlError(err.message);
    } finally {
      setNlLoading(false);
    }
  };

  const useSuggestion = (q: string) => {
    setNlQuery(q);
    handleNLQuery(q);
  };

  return (
    <div className="flex gap-6 h-[calc(100vh-8rem)]">
      {/* Schema Browser */}
      <div className="w-64 flex-shrink-0 bg-white dark:bg-slate-800 rounded-xl border border-gray-200 dark:border-slate-700 overflow-y-auto p-4">
        <h3 className="text-xs font-semibold text-gray-500 dark:text-slate-400 uppercase mb-3">INSURANCE_AI_HUB</h3>
        {SCHEMA_TREE.map((s) => (
          <div key={s.schema} className="mb-2">
            <button onClick={() => toggle(s.schema)} className="flex items-center gap-2 w-full text-left text-sm font-medium text-gray-700 dark:text-slate-300 hover:text-brand-600">
              <ChevronRight className={`w-4 h-4 transition-transform ${expanded.includes(s.schema) ? 'rotate-90' : ''}`} />
              <Database className="w-4 h-4" />
              {s.schema}
            </button>
            {expanded.includes(s.schema) && (
              <div className="ml-6 mt-1 space-y-1">
                {s.tables.map((t) => (
                  <button key={t} onClick={() => insertTable(s.schema, t)} className="block text-xs text-gray-500 dark:text-slate-400 py-0.5 hover:text-brand-600 cursor-pointer">
                    📋 {t}
                  </button>
                ))}
              </div>
            )}
          </div>
        ))}

        {/* NL Suggestions */}
        <div className="mt-6 pt-4 border-t border-gray-200 dark:border-slate-700">
          <h3 className="text-xs font-semibold text-gray-500 dark:text-slate-400 uppercase mb-2 flex items-center gap-1">
            <Sparkles className="w-3 h-3" /> Try asking
          </h3>
          <div className="space-y-1">
            {NL_SUGGESTIONS.map((q, i) => (
              <button key={i} onClick={() => useSuggestion(q)}
                className="block w-full text-left text-[11px] text-gray-500 dark:text-slate-400 py-1.5 px-2 rounded hover:bg-brand-50 dark:hover:bg-brand-900/20 hover:text-brand-700 dark:hover:text-brand-400 transition-colors leading-tight">
                {q}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Main Panel */}
      <div className="flex-1 flex flex-col gap-4 min-w-0">
        {/* NL-to-SQL Bar */}
        <div className="bg-gradient-to-r from-brand-600 to-purple-600 rounded-xl p-4 text-white">
          <div className="flex items-center gap-2 mb-2">
            <Bot className="w-5 h-5" />
            <h3 className="text-sm font-bold">Ask in Natural Language</h3>
            <span className="text-[10px] bg-white/20 px-2 py-0.5 rounded-full">Powered by Cortex Agent</span>
          </div>
          <div className="flex gap-2">
            <div className="flex-1 flex items-center bg-white/10 backdrop-blur rounded-lg border border-white/20 focus-within:ring-2 focus-within:ring-white/50">
              <input
                value={nlQuery}
                onChange={(e) => setNlQuery(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && handleNLQuery()}
                placeholder='e.g. "Show total premium by policy type" — Agent converts to SQL and executes'
                className="flex-1 px-4 py-2.5 bg-transparent text-sm text-white placeholder-white/60 focus:outline-none"
                disabled={nlLoading}
              />
              <button onClick={() => handleNLQuery()} disabled={!nlQuery.trim() || nlLoading}
                className="p-2.5 text-white/80 hover:text-white disabled:opacity-30">
                {nlLoading ? <Loader2 className="w-4 h-4 animate-spin" /> : <Send className="w-4 h-4" />}
              </button>
            </div>
          </div>

          {/* NL Status Messages */}
          {nlLoading && (
            <p className="text-xs text-white/70 mt-2 flex items-center gap-1">
              <Loader2 className="w-3 h-3 animate-spin" /> Agent is generating SQL...
            </p>
          )}
          {nlError && (
            <p className="text-xs text-red-200 mt-2 flex items-center gap-1">
              <AlertCircle className="w-3 h-3" /> {nlError}
            </p>
          )}
          {generatedSQL && !nlLoading && (
            <div className="mt-2 flex items-center gap-2">
              <CheckCircle className="w-3 h-3 text-green-300 flex-shrink-0" />
              <p className="text-xs text-white/80 truncate">
                SQL generated and executed — {nlExplanation.substring(0, 100)}{nlExplanation.length > 100 ? '...' : ''}
              </p>
              <button onClick={() => { setSQL(generatedSQL); }} className="flex items-center gap-1 text-[10px] bg-white/20 px-2 py-0.5 rounded hover:bg-white/30 flex-shrink-0">
                <ArrowDown className="w-3 h-3" /> Edit SQL
              </button>
            </div>
          )}
        </div>

        {/* SQL Editor */}
        <div className="bg-white dark:bg-slate-800 rounded-xl border border-gray-200 dark:border-slate-700 p-4">
          <div className="flex items-center justify-between mb-2">
            <p className="text-xs font-semibold text-gray-500 dark:text-slate-400 uppercase">SQL Editor</p>
            <div className="flex gap-2">
              <button onClick={() => runQuery()} disabled={running}
                className="flex items-center gap-1 px-4 py-1.5 bg-green-600 text-white text-sm font-medium rounded-lg hover:bg-green-700 disabled:opacity-50">
                {running ? <Loader2 className="w-4 h-4 animate-spin" /> : <Play className="w-4 h-4" />} Run
              </button>
              <button onClick={() => navigator.clipboard.writeText(sql)}
                className="flex items-center gap-1 px-3 py-1.5 border border-gray-200 dark:border-slate-700 text-gray-600 dark:text-slate-400 text-sm rounded-lg hover:bg-gray-50 dark:hover:bg-slate-700">
                <Copy className="w-4 h-4" /> Copy
              </button>
            </div>
          </div>
          <textarea
            value={sql}
            onChange={(e) => setSQL(e.target.value)}
            className="w-full h-32 font-mono text-sm bg-gray-900 text-green-400 p-4 rounded-lg focus:outline-none resize-none"
            spellCheck={false}
          />
        </div>

        {/* Results */}
        <div className="flex-1 bg-white dark:bg-slate-800 rounded-xl border border-gray-200 dark:border-slate-700 overflow-auto">
          {error && (
            <div className="flex items-start gap-2 m-4 p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
              <AlertCircle className="w-4 h-4 text-red-500 mt-0.5" />
              <p className="text-sm text-red-700 dark:text-red-400">{error}</p>
            </div>
          )}
          {results && (
            <div className="p-4">
              <div className="flex items-center gap-2 mb-3">
                <CheckCircle className="w-4 h-4 text-green-500" />
                <span className="text-sm text-gray-600 dark:text-slate-400">{results.rowCount} rows returned</span>
                {generatedSQL && <span className="text-xs bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400 px-2 py-0.5 rounded-full">AI Generated</span>}
              </div>
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead className="bg-gray-50 dark:bg-slate-700/50">
                    <tr>
                      {results.columns.map((c: any) => (
                        <th key={c.name} className="px-3 py-2 text-left text-xs font-semibold text-gray-500 dark:text-slate-400 uppercase">{c.name}</th>
                      ))}
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-100 dark:divide-slate-700">
                    {results.data.slice(0, 100).map((row: string[], i: number) => (
                      <tr key={i} className="hover:bg-gray-50 dark:hover:bg-slate-700/30">
                        {row.map((v, j) => (
                          <td key={j} className="px-3 py-2 text-gray-700 dark:text-slate-300 whitespace-nowrap">{v ?? 'NULL'}</td>
                        ))}
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}
          {!results && !error && (
            <div className="text-center py-12">
              <Database className="w-10 h-10 text-gray-300 dark:text-slate-600 mx-auto mb-3" />
              <p className="text-sm text-gray-500 dark:text-slate-400">
                Ask a question in <strong>natural language</strong> above, or write SQL and click <strong>Run</strong>.
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
