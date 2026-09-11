import { useState, useRef, useEffect } from 'react';
import { useSnowflakeQuery, useRefresh, toObjects } from '../hooks/useSnowflakeQuery';
import KPICard from '../components/dashboard/KPICard';
import RefreshButton from '../components/shared/RefreshButton';
import { Loader2, Bot, Send, User, Sparkles, X, BarChart3 } from 'lucide-react';
import { getToken } from '../services/snowflake-api';

const PILLARS = ['Executive', 'Claims', 'Fraud', 'Underwriting', 'Data Trust'] as const;

const ALL_KPI_SQL = `
SELECT 'Executive' AS PILLAR, 'Premium Revenue' AS LABEL, TO_VARCHAR(SUM(PREMIUM_AMOUNT),'$999,999,999') AS VALUE, 'up' AS TREND FROM INSURANCE_AI_HUB.ANALYTICS.POLICIES WHERE POLICY_STATUS='Active'
UNION ALL SELECT 'Executive','Active Policies',TO_VARCHAR(COUNT(*)),'up' FROM INSURANCE_AI_HUB.ANALYTICS.POLICIES WHERE POLICY_STATUS='Active'
UNION ALL SELECT 'Executive','Total Customers',TO_VARCHAR(COUNT(*)),'stable' FROM INSURANCE_AI_HUB.ANALYTICS.CUSTOMERS
UNION ALL SELECT 'Executive','Total Coverage',TO_VARCHAR(SUM(COVERAGE_AMOUNT),'$999,999,999'),'stable' FROM INSURANCE_AI_HUB.ANALYTICS.POLICIES WHERE POLICY_STATUS='Active'
UNION ALL SELECT 'Executive','Revenue at Risk',TO_VARCHAR(SUM(REVENUE_AT_RISK),'$999,999,999'),'down' FROM INSURANCE_AI_HUB.ANALYTICS.AT_RISK_POLICIES
UNION ALL SELECT 'Executive','Outstanding Balance',TO_VARCHAR(SUM(OUTSTANDING_BALANCE),'$999,999,999'),'down' FROM INSURANCE_AI_HUB.ANALYTICS.BILLING
UNION ALL SELECT 'Claims','Total Claims Filed',TO_VARCHAR(COUNT(*)),'stable' FROM INSURANCE_AI_HUB.ANALYTICS.CLAIMS
UNION ALL SELECT 'Claims','Open Claims',TO_VARCHAR(COUNT(*)),'down' FROM INSURANCE_AI_HUB.ANALYTICS.CLAIMS WHERE CLAIM_STATUS IN ('Open','Under Investigation','Escalated')
UNION ALL SELECT 'Claims','Avg Resolution Days',TO_VARCHAR(ROUND(AVG(DAYS_TO_RESOLVE),1)),'stable' FROM INSURANCE_AI_HUB.ANALYTICS.CLAIMS WHERE DAYS_TO_RESOLVE IS NOT NULL
UNION ALL SELECT 'Claims','Total Claim Amount',TO_VARCHAR(SUM(CLAIM_AMOUNT),'$999,999,999'),'stable' FROM INSURANCE_AI_HUB.ANALYTICS.CLAIMS
UNION ALL SELECT 'Claims','Total Approved',TO_VARCHAR(SUM(APPROVED_AMOUNT),'$999,999,999'),'stable' FROM INSURANCE_AI_HUB.ANALYTICS.CLAIMS WHERE APPROVED_AMOUNT IS NOT NULL
UNION ALL SELECT 'Claims','Fraud-Flagged Claims',TO_VARCHAR(COUNT(*)),'down' FROM INSURANCE_AI_HUB.ANALYTICS.CLAIMS WHERE FRAUD_FLAG=TRUE
UNION ALL SELECT 'Fraud','High-Risk Claims (>0.7)',TO_VARCHAR(COUNT(*)),'down' FROM INSURANCE_AI_HUB.ANALYTICS.CLAIMS WHERE FRAUD_SCORE>0.7
UNION ALL SELECT 'Fraud','Fraud Exposure',TO_VARCHAR(SUM(CLAIM_AMOUNT),'$999,999,999'),'down' FROM INSURANCE_AI_HUB.ANALYTICS.CLAIMS WHERE FRAUD_SCORE>0.7
UNION ALL SELECT 'Fraud','Fraud-Flagged',TO_VARCHAR(COUNT(*)),'stable' FROM INSURANCE_AI_HUB.ANALYTICS.CLAIMS WHERE FRAUD_FLAG=TRUE
UNION ALL SELECT 'Fraud','Avg Fraud Score',TO_VARCHAR(ROUND(AVG(FRAUD_SCORE),2)),'stable' FROM INSURANCE_AI_HUB.ANALYTICS.CLAIMS
UNION ALL SELECT 'Fraud','Under Investigation',TO_VARCHAR(COUNT(*)),'down' FROM INSURANCE_AI_HUB.ANALYTICS.CLAIMS WHERE CLAIM_STATUS='Under Investigation'
UNION ALL SELECT 'Fraud','Escalated Claims',TO_VARCHAR(COUNT(*)),'down' FROM INSURANCE_AI_HUB.ANALYTICS.CLAIMS WHERE CLAIM_STATUS='Escalated'
UNION ALL SELECT 'Underwriting','Avg Loss Ratio',TO_VARCHAR(ROUND(AVG(LOSS_RATIO),2)),'stable' FROM INSURANCE_AI_HUB.ANALYTICS.POLICIES
UNION ALL SELECT 'Underwriting','At-Risk Policies',TO_VARCHAR(COUNT(*)),'down' FROM INSURANCE_AI_HUB.ANALYTICS.AT_RISK_POLICIES
UNION ALL SELECT 'Underwriting','Avg Risk Score',TO_VARCHAR(ROUND(AVG(RISK_SCORE),2)),'stable' FROM INSURANCE_AI_HUB.ANALYTICS.AT_RISK_POLICIES
UNION ALL SELECT 'Underwriting','Avg Churn Prob',TO_VARCHAR(ROUND(AVG(CHURN_PROBABILITY),2)),'down' FROM INSURANCE_AI_HUB.ANALYTICS.AT_RISK_POLICIES
UNION ALL SELECT 'Underwriting','Avg Credit Score',TO_VARCHAR(ROUND(AVG(CREDIT_SCORE))),'up' FROM INSURANCE_AI_HUB.ANALYTICS.CUSTOMERS
UNION ALL SELECT 'Underwriting','High-Risk Tier %',TO_VARCHAR(ROUND(COUNT(CASE WHEN RISK_TIER IN ('High','Very High') THEN 1 END)*100.0/COUNT(*),1))||'%','stable' FROM INSURANCE_AI_HUB.ANALYTICS.CUSTOMERS
UNION ALL SELECT 'Data Trust','Avg DQ Score',TO_VARCHAR(ROUND(AVG(OVERALL_SCORE),1)),CASE WHEN AVG(OVERALL_SCORE)>=85 THEN 'up' ELSE 'down' END FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_SCORES WHERE SCORE_DATE=(SELECT MAX(SCORE_DATE) FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_SCORES)
UNION ALL SELECT 'Data Trust','Failed Rules',TO_VARCHAR(COUNT(*)),'down' FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_RESULTS WHERE STATUS='FAIL' AND EXECUTION_DATE=(SELECT MAX(EXECUTION_DATE) FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_RESULTS WHERE STATUS='FAIL')
UNION ALL SELECT 'Data Trust','Critical Columns',TO_VARCHAR(COUNT(*)),'down' FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_COLUMN_HEALTH WHERE HEALTH_STATUS='Critical'
UNION ALL SELECT 'Data Trust','Warning Columns',TO_VARCHAR(COUNT(*)),'down' FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_COLUMN_HEALTH WHERE HEALTH_STATUS='Warning'
UNION ALL SELECT 'Data Trust','Total DQ Rules',TO_VARCHAR(COUNT(*)),'stable' FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_RULES WHERE ACTIVE_FLAG=TRUE
UNION ALL SELECT 'Data Trust','Tables Monitored',TO_VARCHAR(COUNT(DISTINCT TABLE_NAME)),'stable' FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_SCORES`;

const PILLAR_SUGGESTIONS: Record<string, string[]> = {
  Executive: [
    'What is driving our premium revenue growth?',
    'Why is revenue at risk high and which policies contribute?',
    'How does total coverage compare across policy types?',
    'What is the outstanding billing balance breakdown?',
    'Show me customer growth trends',
    'Which policy types generate the most premium?',
  ],
  Claims: [
    'Which claims are taking the longest to resolve?',
    'What is the breakdown of open vs closed claims?',
    'How much has been approved vs total claimed?',
    'Which claim types have the highest amounts?',
    'Show me fraud-flagged claims details',
    'What is the average resolution time by claim type?',
  ],
  Fraud: [
    'Which claims have the highest fraud scores?',
    'What is our total fraud exposure amount?',
    'Show details of claims under investigation',
    'What patterns exist in high-risk fraud claims?',
    'How many escalated claims are there and why?',
    'What is the fraud score distribution across claims?',
  ],
  Underwriting: [
    'Why are some policies flagged as at-risk?',
    'What is the average loss ratio by policy type?',
    'Which customers have the highest churn probability?',
    'Show me the risk score distribution',
    'What percentage of customers are in high-risk tiers?',
    'How does credit score correlate with risk tier?',
  ],
  'Data Trust': [
    'Which tables have the lowest data quality scores?',
    'What DQ rules are currently failing?',
    'Show me critical column health issues',
    'What is the trend of overall DQ scores?',
    'Which data quality dimensions need attention?',
    'How many tables are being monitored for quality?',
  ],
};

function getBaseUrl(): string {
  if (import.meta.env.DEV) return '';
  return import.meta.env.VITE_SNOWFLAKE_ACCOUNT_URL || '';
}

interface ChatMsg {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
}

export default function KPIDashboard() {
  const [pillar, setPillar] = useState<string>('Executive');
  const q = useSnowflakeQuery('kpi-all', ALL_KPI_SQL);
  const refresh = useRefresh('kpi-all');
  const kpis = toObjects(q.data).filter(r => r.PILLAR === pillar);

  // Agent chat state (local to this page, separate from AI Assistant)
  const [messages, setMessages] = useState<ChatMsg[]>([]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const bottomRef = useRef<HTMLDivElement>(null);

  useEffect(() => { bottomRef.current?.scrollIntoView({ behavior: 'smooth' }); }, [messages]);

  const handleAsk = async (question?: string) => {
    const text = (question || input).trim();
    if (!text || isLoading) return;
    setInput('');

    const userMsg: ChatMsg = { id: crypto.randomUUID(), role: 'user', content: text, timestamp: new Date() };
    setMessages(prev => [...prev, userMsg]);
    setIsLoading(true);

    try {
      const token = getToken();
      if (!token) throw new Error('Not authenticated. Please log in first.');

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
          messages: [{ role: 'user', content: [{ type: 'text', text }] }],
          stream: false,
        }),
      });

      if (!resp.ok) throw new Error(`Agent error ${resp.status}: ${resp.statusText}`);

      const contentType = resp.headers.get('content-type') || '';
      let content: any[] = [];

      if (contentType.includes('text/event-stream') || contentType.includes('text/plain')) {
        const rawText = await resp.text();
        for (const line of rawText.split('\n')) {
          if (!line.startsWith('data: ')) continue;
          const payload = line.slice(6).trim();
          if (payload === '[DONE]') break;
          try {
            const event = JSON.parse(payload);
            if (event.delta?.content) content.push(...event.delta.content);
            if (event.content) content.push(...(Array.isArray(event.content) ? event.content : [event.content]));
          } catch {}
        }
      } else {
        const result = await resp.json();
        content = result.content || [];
        if (typeof content === 'string') content = [{ type: 'text', text: content }];
      }

      // Extract text + format table data from response
      const parts: string[] = [];
      for (const block of content) {
        if (block.type === 'text' && block.text) parts.push(block.text);
        if (block.type === 'tool_result') {
          const tr = block.tool_result || block;
          const trContent = Array.isArray(tr.content) ? tr.content : [tr.content || {}];
          for (const c of trContent) {
            if (c.type === 'json' && c.json) {
              if (c.json.result_set?.data && c.json.result_set?.resultSetMetaData?.rowType) {
                const cols = c.json.result_set.resultSetMetaData.rowType.map((col: any) => col.name);
                const rows = c.json.result_set.data;
                const header = '| ' + cols.join(' | ') + ' |';
                const sep = '| ' + cols.map(() => '---').join(' | ') + ' |';
                const dataRows = rows.slice(0, 20).map((r: string[]) => '| ' + r.map((v: any) => v ?? 'NULL').join(' | ') + ' |');
                parts.push('\n' + [header, sep, ...dataRows].join('\n'));
                if (rows.length > 20) parts.push(`\n*...and ${rows.length - 20} more rows*`);
              }
            }
          }
        }
      }

      setMessages(prev => [...prev, {
        id: crypto.randomUUID(),
        role: 'assistant',
        content: parts.join('') || 'The agent processed your question but returned no text.',
        timestamp: new Date(),
      }]);
    } catch (err: any) {
      setMessages(prev => [...prev, {
        id: crypto.randomUUID(),
        role: 'assistant',
        content: `**Error:** ${err.message}`,
        timestamp: new Date(),
      }]);
    } finally {
      setIsLoading(false);
    }
  };

  const suggestions = PILLAR_SUGGESTIONS[pillar] || PILLAR_SUGGESTIONS['Executive'];

  return (
    <div className="flex gap-4 h-[calc(100vh-8rem)]">
      {/* Left: KPI Cards */}
      <div className="flex-1 flex flex-col min-w-0 overflow-y-auto">
        <div className="flex items-center justify-between mb-4">
          <div className="flex flex-wrap gap-2">
            {PILLARS.map(p => (
              <button key={p} onClick={() => setPillar(p)}
                className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                  pillar === p
                    ? 'bg-brand-600 text-white'
                    : 'bg-white dark:bg-slate-800 text-gray-600 dark:text-slate-400 border border-gray-200 dark:border-slate-700 hover:bg-gray-50 dark:hover:bg-slate-700'
                }`}>
                {p}
              </button>
            ))}
          </div>
          <RefreshButton onRefresh={refresh} />
        </div>

        {q.isLoading ? (
          <div className="flex items-center justify-center h-48">
            <Loader2 className="w-6 h-6 text-brand-600 animate-spin" />
            <span className="ml-2 text-gray-500">Loading KPIs...</span>
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {kpis.map((kpi, i) => (
              <KPICard key={i} label={kpi.LABEL} value={kpi.VALUE} trend={kpi.TREND as any} />
            ))}
          </div>
        )}
      </div>

      {/* Right: KPI Agent Chat */}
      <div className="w-[380px] flex-shrink-0 flex flex-col bg-white dark:bg-slate-800 rounded-xl border border-gray-200 dark:border-slate-700">
        {/* Header */}
        <div className="flex items-center justify-between px-4 py-3 border-b border-gray-200 dark:border-slate-700">
          <div className="flex items-center gap-3">
            <div className="relative">
              <div className="w-9 h-9 rounded-lg bg-gradient-to-br from-violet-500 to-purple-600 flex items-center justify-center">
                <BarChart3 className="w-4 h-4 text-white" />
              </div>
              <div className="absolute -bottom-0.5 -right-0.5 w-3 h-3 bg-green-500 rounded-full border-2 border-white dark:border-slate-800" />
            </div>
            <div>
              <h3 className="text-sm font-bold text-gray-900 dark:text-white">KPI Assistant</h3>
              <p className="text-[10px] text-purple-600 dark:text-purple-400">Cortex Agent · {pillar} Pillar</p>
            </div>
          </div>
          {messages.length > 0 && (
            <button onClick={() => setMessages([])}
              className="text-xs text-gray-400 hover:text-red-500 flex items-center gap-1 transition-colors">
              <X className="w-3 h-3" /> Clear
            </button>
          )}
        </div>

        {/* Messages */}
        <div className="flex-1 overflow-y-auto p-3 space-y-3 scrollbar-thin">
          {messages.length === 0 && (
            <div className="flex flex-col items-center justify-center h-full text-center px-3">
              <Sparkles className="w-10 h-10 text-purple-300 dark:text-purple-700 mb-3" />
              <h4 className="text-sm font-semibold text-gray-900 dark:text-white mb-1">
                Ask About {pillar} KPIs
              </h4>
              <p className="text-xs text-gray-500 dark:text-slate-400 mb-4">
                Get deeper insights into your {pillar.toLowerCase()} metrics using the Cortex Agent.
              </p>
              <div className="space-y-2 w-full">
                {suggestions.map((s, i) => (
                  <button key={i} onClick={() => handleAsk(s)}
                    className="w-full text-left px-3 py-2 rounded-lg border border-gray-200 dark:border-slate-700 text-xs text-gray-600 dark:text-slate-400 hover:bg-purple-50 dark:hover:bg-purple-900/20 hover:border-purple-300 dark:hover:border-purple-700 transition-colors">
                    {s}
                  </button>
                ))}
              </div>
            </div>
          )}

          {messages.map((msg) => (
            <div key={msg.id} className={`flex gap-2 ${msg.role === 'user' ? 'justify-end' : ''}`}>
              {msg.role === 'assistant' && (
                <div className="w-6 h-6 rounded-lg bg-gradient-to-br from-violet-500 to-purple-600 flex items-center justify-center flex-shrink-0 mt-1">
                  <Bot className="w-3 h-3 text-white" />
                </div>
              )}
              <div className={`max-w-[85%] rounded-2xl px-3 py-2 text-xs leading-relaxed ${
                msg.role === 'user'
                  ? 'bg-brand-600 text-white'
                  : 'bg-gray-50 dark:bg-slate-700/50 text-gray-700 dark:text-slate-300 border border-gray-200 dark:border-slate-600'
              }`}>
                <div className="whitespace-pre-wrap">{msg.content}</div>
                <div className="mt-1 text-[9px] opacity-40">{msg.timestamp.toLocaleTimeString()}</div>
              </div>
              {msg.role === 'user' && (
                <div className="w-6 h-6 rounded-lg bg-brand-600 flex items-center justify-center flex-shrink-0 mt-1">
                  <User className="w-3 h-3 text-white" />
                </div>
              )}
            </div>
          ))}

          {isLoading && (
            <div className="flex gap-2">
              <div className="w-6 h-6 rounded-lg bg-gradient-to-br from-violet-500 to-purple-600 flex items-center justify-center flex-shrink-0">
                <Bot className="w-3 h-3 text-white animate-pulse" />
              </div>
              <div className="bg-gray-50 dark:bg-slate-700/50 border border-gray-200 dark:border-slate-600 rounded-2xl px-3 py-2">
                <p className="text-[10px] text-gray-500 mb-1">Analyzing KPIs...</p>
                <div className="flex gap-1">
                  <div className="w-1.5 h-1.5 bg-purple-500 rounded-full animate-bounce" style={{ animationDelay: '0ms' }} />
                  <div className="w-1.5 h-1.5 bg-purple-500 rounded-full animate-bounce" style={{ animationDelay: '150ms' }} />
                  <div className="w-1.5 h-1.5 bg-purple-500 rounded-full animate-bounce" style={{ animationDelay: '300ms' }} />
                </div>
              </div>
            </div>
          )}
          <div ref={bottomRef} />
        </div>

        {/* Input */}
        <div className="border-t border-gray-200 dark:border-slate-700 p-3">
          <div className="flex items-center bg-gray-50 dark:bg-slate-700 rounded-lg border border-gray-200 dark:border-slate-600 focus-within:ring-2 focus-within:ring-purple-500 focus-within:border-purple-500">
            <input
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && !e.shiftKey && handleAsk()}
              placeholder={`Ask about ${pillar.toLowerCase()} KPIs...`}
              className="flex-1 px-3 py-2.5 bg-transparent text-sm text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none"
              disabled={isLoading}
            />
            <button onClick={() => handleAsk()} disabled={!input.trim() || isLoading}
              className="p-2.5 text-purple-600 hover:text-purple-700 disabled:opacity-30 transition-opacity">
              <Send className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
