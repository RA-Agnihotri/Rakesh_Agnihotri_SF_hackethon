import { useState } from 'react';
import { FileText, Sparkles, GitCompare, Loader2, X, ChevronDown, CheckCircle2, AlertCircle } from 'lucide-react';
import { useSnowflakeQuery, useRefresh, toObjects } from '../hooks/useSnowflakeQuery';
import { executeSQL } from '../services/snowflake-api';
import RefreshButton from '../components/shared/RefreshButton';

const DOCS_SQL = `
  SELECT DOCUMENT_ID, POLICY_ID, DOCUMENT_TYPE, DOCUMENT_TITLE, FILE_NAME,
         UPLOAD_DATE, PAGE_COUNT, DOCUMENT_STATUS,
         LEFT(CONTENT_TEXT, 300) AS CONTENT_PREVIEW,
         LENGTH(CONTENT_TEXT) AS CONTENT_LENGTH
  FROM INSURANCE_AI_HUB.DOCUMENTS.POLICY_DOCUMENTS
  ORDER BY DOCUMENT_ID`;

type AnalysisType = 'idle' | 'summarize' | 'extract' | 'classify' | 'bulk' | 'compare';

interface AnalysisResult {
  type: AnalysisType;
  docId: string;
  docTitle: string;
  loading: boolean;
  error?: string;
  data?: any;
}

export default function DocumentIntelligence() {
  const docsQ = useSnowflakeQuery('docs-list', DOCS_SQL);
  const refresh = useRefresh('docs-list');
  const docs = toObjects(docsQ.data);

  const [analysis, setAnalysis] = useState<AnalysisResult | null>(null);
  const [compareDoc1, setCompareDoc1] = useState('');
  const [compareDoc2, setCompareDoc2] = useState('');
  const [showCompare, setShowCompare] = useState(false);

  const runSummarize = async (docId: string, title: string) => {
    setAnalysis({ type: 'summarize', docId, docTitle: title, loading: true });
    try {
      const result = await executeSQL(`
        SELECT SNOWFLAKE.CORTEX.SUMMARIZE(CONTENT_TEXT) AS SUMMARY
        FROM INSURANCE_AI_HUB.DOCUMENTS.POLICY_DOCUMENTS
        WHERE DOCUMENT_ID = '${docId}'
      `);
      const summary = result.data?.[0]?.[0] || 'No summary generated.';
      setAnalysis({ type: 'summarize', docId, docTitle: title, loading: false, data: { summary } });
    } catch (err: any) {
      setAnalysis({ type: 'summarize', docId, docTitle: title, loading: false, error: err.message });
    }
  };

  const runExtract = async (docId: string, title: string) => {
    setAnalysis({ type: 'extract', docId, docTitle: title, loading: true });
    try {
      const result = await executeSQL(`
        SELECT DOCUMENT_ID, DOCUMENT_TYPE, DOCUMENT_TITLE, POLICY_ID,
               UPLOAD_DATE, PAGE_COUNT, DOCUMENT_STATUS,
               COVERAGE_SUMMARY, EXCLUSION_CLAUSES
        FROM INSURANCE_AI_HUB.DOCUMENTS.POLICY_DOCUMENTS
        WHERE DOCUMENT_ID = '${docId}'
      `);
      const row = toObjects(result)[0];
      setAnalysis({ type: 'extract', docId, docTitle: title, loading: false, data: row });
    } catch (err: any) {
      setAnalysis({ type: 'extract', docId, docTitle: title, loading: false, error: err.message });
    }
  };

  const runClassify = async (docId: string, title: string) => {
    setAnalysis({ type: 'classify', docId, docTitle: title, loading: true });
    try {
      const result = await executeSQL(`
        SELECT SNOWFLAKE.CORTEX.CLASSIFY_TEXT(
          CONTENT_TEXT,
          ['Health Insurance', 'Auto Insurance', 'Life Insurance', 'Home Insurance', 'Disability Insurance', 'Workers Compensation', 'Commercial Insurance', 'Claim Form', 'Endorsement']
        ) AS CLASSIFICATION
        FROM INSURANCE_AI_HUB.DOCUMENTS.POLICY_DOCUMENTS
        WHERE DOCUMENT_ID = '${docId}'
      `);
      const raw = result.data?.[0]?.[0] || '{}';
      let parsed: any;
      try { parsed = JSON.parse(raw); } catch { parsed = { label: raw }; }
      setAnalysis({ type: 'classify', docId, docTitle: title, loading: false, data: parsed });
    } catch (err: any) {
      setAnalysis({ type: 'classify', docId, docTitle: title, loading: false, error: err.message });
    }
  };

  const runBulkProcess = async () => {
    setAnalysis({ type: 'bulk', docId: 'ALL', docTitle: 'All Documents', loading: true });
    try {
      const result = await executeSQL(`
        SELECT DOCUMENT_ID, DOCUMENT_TITLE, DOCUMENT_TYPE,
               SNOWFLAKE.CORTEX.CLASSIFY_TEXT(
                 CONTENT_TEXT,
                 ['Health Insurance', 'Auto Insurance', 'Life Insurance', 'Home Insurance', 'Disability Insurance', 'Workers Compensation', 'Commercial Insurance', 'Claim Form', 'Endorsement']
               ) AS CLASSIFICATION
        FROM INSURANCE_AI_HUB.DOCUMENTS.POLICY_DOCUMENTS
        ORDER BY DOCUMENT_ID
      `);
      const rows = toObjects(result);
      setAnalysis({ type: 'bulk', docId: 'ALL', docTitle: 'All Documents', loading: false, data: rows });
    } catch (err: any) {
      setAnalysis({ type: 'bulk', docId: 'ALL', docTitle: 'All Documents', loading: false, error: err.message });
    }
  };

  const runCompare = async () => {
    if (!compareDoc1 || !compareDoc2 || compareDoc1 === compareDoc2) return;
    setAnalysis({ type: 'compare', docId: `${compareDoc1} vs ${compareDoc2}`, docTitle: 'Document Comparison', loading: true });
    try {
      const result = await executeSQL(`
        SELECT DOCUMENT_ID, DOCUMENT_TITLE, DOCUMENT_TYPE, PAGE_COUNT,
               COVERAGE_SUMMARY, EXCLUSION_CLAUSES
        FROM INSURANCE_AI_HUB.DOCUMENTS.POLICY_DOCUMENTS
        WHERE DOCUMENT_ID IN ('${compareDoc1}', '${compareDoc2}')
        ORDER BY DOCUMENT_ID
      `);
      const rows = toObjects(result);
      setAnalysis({ type: 'compare', docId: `${compareDoc1} vs ${compareDoc2}`, docTitle: 'Document Comparison', loading: false, data: rows });
    } catch (err: any) {
      setAnalysis({ type: 'compare', docId: '', docTitle: 'Comparison', loading: false, error: err.message });
    }
  };

  if (docsQ.isLoading) {
    return <div className="flex items-center justify-center h-64"><Loader2 className="w-8 h-8 text-brand-600 animate-spin" /><span className="ml-3 text-gray-500">Loading documents...</span></div>;
  }

  return (
    <div className="space-y-6">
      {/* Action Bar */}
      <div className="flex items-center justify-between">
        <div className="flex gap-3">
          <button onClick={runBulkProcess} disabled={analysis?.loading}
            className="flex items-center gap-2 px-4 py-2 bg-brand-600 text-white rounded-lg text-sm font-medium hover:bg-brand-700 disabled:opacity-50">
            <Sparkles className="w-4 h-4" /> Bulk Classify All
          </button>
          <button onClick={() => setShowCompare(!showCompare)}
            className="flex items-center gap-2 px-4 py-2 bg-white dark:bg-slate-800 border border-gray-200 dark:border-slate-700 rounded-lg text-sm font-medium text-gray-700 dark:text-slate-300 hover:bg-gray-50 dark:hover:bg-slate-700">
            <GitCompare className="w-4 h-4" /> Compare
          </button>
        </div>
        <RefreshButton onRefresh={refresh} />
      </div>

      {/* Compare Selector */}
      {showCompare && (
        <div className="bg-white dark:bg-slate-800 rounded-xl border border-gray-200 dark:border-slate-700 p-4 flex items-end gap-4">
          <div className="flex-1">
            <label className="block text-xs font-medium text-gray-500 dark:text-slate-400 mb-1">Document 1</label>
            <select value={compareDoc1} onChange={e => setCompareDoc1(e.target.value)}
              className="w-full px-3 py-2 bg-gray-50 dark:bg-slate-700 border border-gray-200 dark:border-slate-600 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500">
              <option value="">Select...</option>
              {docs.map(d => <option key={d.DOCUMENT_ID} value={d.DOCUMENT_ID}>{d.DOCUMENT_ID} — {d.DOCUMENT_TITLE}</option>)}
            </select>
          </div>
          <div className="flex-1">
            <label className="block text-xs font-medium text-gray-500 dark:text-slate-400 mb-1">Document 2</label>
            <select value={compareDoc2} onChange={e => setCompareDoc2(e.target.value)}
              className="w-full px-3 py-2 bg-gray-50 dark:bg-slate-700 border border-gray-200 dark:border-slate-600 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500">
              <option value="">Select...</option>
              {docs.map(d => <option key={d.DOCUMENT_ID} value={d.DOCUMENT_ID}>{d.DOCUMENT_ID} — {d.DOCUMENT_TITLE}</option>)}
            </select>
          </div>
          <button onClick={runCompare} disabled={!compareDoc1 || !compareDoc2 || compareDoc1 === compareDoc2 || analysis?.loading}
            className="px-4 py-2 bg-brand-600 text-white text-sm font-medium rounded-lg hover:bg-brand-700 disabled:opacity-50">
            Compare
          </button>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Document List */}
        <div className="space-y-3 max-h-[calc(100vh-16rem)] overflow-y-auto scrollbar-thin">
          <h3 className="font-semibold text-gray-900 dark:text-white sticky top-0 bg-gray-50 dark:bg-slate-900 py-1">Documents ({docs.length})</h3>
          {docs.map((doc) => (
            <div key={doc.DOCUMENT_ID} className={`bg-white dark:bg-slate-800 rounded-xl border p-4 hover:shadow-md transition-shadow ${
              analysis?.docId === doc.DOCUMENT_ID ? 'border-brand-500 ring-1 ring-brand-500' : 'border-gray-200 dark:border-slate-700'
            }`}>
              <div className="flex items-start gap-3">
                <FileText className="w-8 h-8 text-brand-500 flex-shrink-0" />
                <div className="flex-1 min-w-0">
                  <p className="font-medium text-gray-900 dark:text-white">{doc.DOCUMENT_TITLE}</p>
                  <p className="text-xs text-gray-500 dark:text-slate-400 mt-1">
                    {doc.DOCUMENT_ID} · {doc.DOCUMENT_TYPE} · {doc.PAGE_COUNT} pages · {doc.DOCUMENT_STATUS}
                  </p>
                  <p className="text-xs text-gray-400 dark:text-slate-500 mt-1 truncate">{doc.CONTENT_PREVIEW}...</p>
                  <div className="flex gap-2 mt-3">
                    <button onClick={() => runSummarize(doc.DOCUMENT_ID, doc.DOCUMENT_TITLE)} disabled={analysis?.loading}
                      className="text-xs px-3 py-1.5 rounded-lg bg-purple-50 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400 font-medium hover:bg-purple-100 dark:hover:bg-purple-900/50 disabled:opacity-50 transition-colors">
                      {analysis?.loading && analysis.docId === doc.DOCUMENT_ID && analysis.type === 'summarize' ? '...' : 'Summarize'}
                    </button>
                    <button onClick={() => runExtract(doc.DOCUMENT_ID, doc.DOCUMENT_TITLE)} disabled={analysis?.loading}
                      className="text-xs px-3 py-1.5 rounded-lg bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400 font-medium hover:bg-blue-100 dark:hover:bg-blue-900/50 disabled:opacity-50 transition-colors">
                      {analysis?.loading && analysis.docId === doc.DOCUMENT_ID && analysis.type === 'extract' ? '...' : 'Extract Fields'}
                    </button>
                    <button onClick={() => runClassify(doc.DOCUMENT_ID, doc.DOCUMENT_TITLE)} disabled={analysis?.loading}
                      className="text-xs px-3 py-1.5 rounded-lg bg-green-50 text-green-700 dark:bg-green-900/30 dark:text-green-400 font-medium hover:bg-green-100 dark:hover:bg-green-900/50 disabled:opacity-50 transition-colors">
                      {analysis?.loading && analysis.docId === doc.DOCUMENT_ID && analysis.type === 'classify' ? '...' : 'Classify'}
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Analysis Panel */}
        <div className="bg-white dark:bg-slate-800 rounded-xl border border-gray-200 dark:border-slate-700 p-6 max-h-[calc(100vh-16rem)] overflow-y-auto scrollbar-thin">
          {!analysis && (
            <div className="text-center py-12">
              <Sparkles className="w-12 h-12 text-gray-300 dark:text-slate-600 mx-auto mb-4" />
              <h3 className="font-semibold text-gray-900 dark:text-white mb-2">AI Analysis Panel</h3>
              <p className="text-sm text-gray-500 dark:text-slate-400 max-w-sm mx-auto">
                Click <strong>Summarize</strong>, <strong>Extract Fields</strong>, or <strong>Classify</strong> on any document to see live AI analysis powered by Snowflake Cortex.
              </p>
            </div>
          )}

          {analysis?.loading && (
            <div className="flex flex-col items-center justify-center py-12">
              <Loader2 className="w-8 h-8 text-brand-600 animate-spin mb-3" />
              <p className="text-sm text-gray-500 dark:text-slate-400">Running {analysis.type} on {analysis.docTitle}...</p>
              <p className="text-xs text-gray-400 mt-1">Powered by Snowflake Cortex AI</p>
            </div>
          )}

          {analysis && !analysis.loading && analysis.error && (
            <div className="p-4 bg-red-50 dark:bg-red-900/20 rounded-lg border border-red-200 dark:border-red-800">
              <div className="flex items-start gap-2">
                <AlertCircle className="w-5 h-5 text-red-500 flex-shrink-0 mt-0.5" />
                <div>
                  <h4 className="font-medium text-red-800 dark:text-red-300">Error</h4>
                  <p className="text-sm text-red-600 dark:text-red-400 mt-1">{analysis.error}</p>
                </div>
              </div>
            </div>
          )}

          {/* Summarize Result */}
          {analysis && !analysis.loading && !analysis.error && analysis.type === 'summarize' && (
            <div>
              <div className="flex items-center justify-between mb-4">
                <h3 className="font-semibold text-gray-900 dark:text-white">AI Summary</h3>
                <button onClick={() => setAnalysis(null)} className="text-gray-400 hover:text-gray-600"><X className="w-4 h-4" /></button>
              </div>
              <p className="text-xs text-gray-500 dark:text-slate-400 mb-3">{analysis.docTitle} ({analysis.docId})</p>
              <div className="p-4 bg-purple-50 dark:bg-purple-900/20 rounded-lg border border-purple-200 dark:border-purple-800">
                <p className="text-sm text-purple-900 dark:text-purple-200 leading-relaxed whitespace-pre-wrap">{analysis.data?.summary}</p>
              </div>
              <p className="text-xs text-gray-400 mt-3 italic">Generated by SNOWFLAKE.CORTEX.SUMMARIZE()</p>
            </div>
          )}

          {/* Extract Result */}
          {analysis && !analysis.loading && !analysis.error && analysis.type === 'extract' && (
            <div>
              <div className="flex items-center justify-between mb-4">
                <h3 className="font-semibold text-gray-900 dark:text-white">Extracted Fields</h3>
                <button onClick={() => setAnalysis(null)} className="text-gray-400 hover:text-gray-600"><X className="w-4 h-4" /></button>
              </div>
              <p className="text-xs text-gray-500 dark:text-slate-400 mb-3">{analysis.docTitle} ({analysis.docId})</p>
              <div className="space-y-3">
                {Object.entries(analysis.data || {}).map(([key, value]) => (
                  <div key={key} className="p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
                    <p className="text-xs font-semibold text-blue-600 dark:text-blue-400 uppercase">{key.replace(/_/g, ' ')}</p>
                    <p className="text-sm text-blue-900 dark:text-blue-200 mt-1 whitespace-pre-wrap">{String(value) || '—'}</p>
                  </div>
                ))}
              </div>
              <p className="text-xs text-gray-400 mt-3 italic">Extracted from INSURANCE_AI_HUB.DOCUMENTS.POLICY_DOCUMENTS</p>
            </div>
          )}

          {/* Classify Result */}
          {analysis && !analysis.loading && !analysis.error && analysis.type === 'classify' && (
            <div>
              <div className="flex items-center justify-between mb-4">
                <h3 className="font-semibold text-gray-900 dark:text-white">Classification Result</h3>
                <button onClick={() => setAnalysis(null)} className="text-gray-400 hover:text-gray-600"><X className="w-4 h-4" /></button>
              </div>
              <p className="text-xs text-gray-500 dark:text-slate-400 mb-3">{analysis.docTitle} ({analysis.docId})</p>
              <div className="p-4 bg-green-50 dark:bg-green-900/20 rounded-lg border border-green-200 dark:border-green-800">
                <p className="text-sm font-semibold text-green-800 dark:text-green-300 mb-2">
                  Predicted Category: <span className="text-lg">{analysis.data?.label || 'Unknown'}</span>
                </p>
                {analysis.data?.score != null && (
                  <div className="mt-2">
                    <p className="text-xs text-green-600 dark:text-green-400 mb-1">Confidence: {(Number(analysis.data.score) * 100).toFixed(1)}%</p>
                    <div className="w-full h-2 bg-green-200 dark:bg-green-800 rounded-full overflow-hidden">
                      <div className="h-full bg-green-600 rounded-full" style={{ width: `${Number(analysis.data.score) * 100}%` }} />
                    </div>
                  </div>
                )}
                {analysis.data?.classifications && (
                  <div className="mt-3 space-y-1">
                    <p className="text-xs font-semibold text-green-700 dark:text-green-400">All Scores:</p>
                    {(Array.isArray(analysis.data.classifications) ? analysis.data.classifications : []).map((c: any, i: number) => (
                      <div key={i} className="flex items-center justify-between text-xs">
                        <span className="text-green-800 dark:text-green-300">{c.label}</span>
                        <span className="text-green-600 dark:text-green-400">{(Number(c.score) * 100).toFixed(1)}%</span>
                      </div>
                    ))}
                  </div>
                )}
              </div>
              <p className="text-xs text-gray-400 mt-3 italic">Generated by SNOWFLAKE.CORTEX.CLASSIFY_TEXT()</p>
            </div>
          )}

          {/* Bulk Classify Result */}
          {analysis && !analysis.loading && !analysis.error && analysis.type === 'bulk' && (
            <div>
              <div className="flex items-center justify-between mb-4">
                <h3 className="font-semibold text-gray-900 dark:text-white">Bulk Classification Results</h3>
                <button onClick={() => setAnalysis(null)} className="text-gray-400 hover:text-gray-600"><X className="w-4 h-4" /></button>
              </div>
              <div className="space-y-2">
                {(analysis.data || []).map((row: any) => {
                  let parsed: any = {};
                  try { parsed = JSON.parse(row.CLASSIFICATION || '{}'); } catch { parsed = { label: row.CLASSIFICATION }; }
                  return (
                    <div key={row.DOCUMENT_ID} className="flex items-center justify-between p-3 rounded-lg bg-gray-50 dark:bg-slate-700/50">
                      <div>
                        <p className="text-sm font-medium text-gray-900 dark:text-white">{row.DOCUMENT_TITLE}</p>
                        <p className="text-xs text-gray-500">{row.DOCUMENT_ID} · {row.DOCUMENT_TYPE}</p>
                      </div>
                      <div className="text-right">
                        <span className="px-2 py-1 bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400 rounded text-xs font-medium">
                          {parsed.label || 'N/A'}
                        </span>
                        {parsed.score && <p className="text-[10px] text-gray-400 mt-0.5">{(Number(parsed.score)*100).toFixed(0)}% confidence</p>}
                      </div>
                    </div>
                  );
                })}
              </div>
              <p className="text-xs text-gray-400 mt-3 italic">Bulk classification via SNOWFLAKE.CORTEX.CLASSIFY_TEXT()</p>
            </div>
          )}

          {/* Compare Result */}
          {analysis && !analysis.loading && !analysis.error && analysis.type === 'compare' && (
            <div>
              <div className="flex items-center justify-between mb-4">
                <h3 className="font-semibold text-gray-900 dark:text-white">Document Comparison</h3>
                <button onClick={() => setAnalysis(null)} className="text-gray-400 hover:text-gray-600"><X className="w-4 h-4" /></button>
              </div>
              <div className="grid grid-cols-2 gap-4">
                {(analysis.data || []).map((doc: any) => (
                  <div key={doc.DOCUMENT_ID} className="space-y-3">
                    <div className="p-3 bg-gray-50 dark:bg-slate-700/50 rounded-lg">
                      <p className="text-sm font-bold text-gray-900 dark:text-white">{doc.DOCUMENT_TITLE}</p>
                      <p className="text-xs text-gray-500 mt-1">{doc.DOCUMENT_ID} · {doc.DOCUMENT_TYPE} · {doc.PAGE_COUNT} pages</p>
                    </div>
                    <div className="p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
                      <p className="text-xs font-semibold text-blue-600 dark:text-blue-400 uppercase mb-1">Coverage</p>
                      <p className="text-xs text-blue-900 dark:text-blue-200">{doc.COVERAGE_SUMMARY || '—'}</p>
                    </div>
                    <div className="p-3 bg-red-50 dark:bg-red-900/20 rounded-lg border border-red-200 dark:border-red-800">
                      <p className="text-xs font-semibold text-red-600 dark:text-red-400 uppercase mb-1">Exclusions</p>
                      <p className="text-xs text-red-900 dark:text-red-200">{doc.EXCLUSION_CLAUSES || '—'}</p>
                    </div>
                  </div>
                ))}
              </div>
              <p className="text-xs text-gray-400 mt-3 italic">Side-by-side from INSURANCE_AI_HUB.DOCUMENTS.POLICY_DOCUMENTS</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
