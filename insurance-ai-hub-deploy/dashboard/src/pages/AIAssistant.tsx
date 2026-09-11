import { useState, useRef, useEffect } from 'react';
import { Send, Trash2, Bot, User, Sparkles, ChevronDown, ChevronRight, Database, Search, FileCode, Zap, Clock, CheckCircle2 } from 'lucide-react';
import { useChatStore } from '../stores';
import { runAgentQuery, clearConversation, type AgentResponse, type ToolTraceItem } from '../services/cortex-agent';
import { SNOWFLAKE_CONFIG } from '../lib/constants';

const AGENT_NAME = 'INSURANCE_INTELLIGENCE_AGENT';
const AGENT_FQN = SNOWFLAKE_CONFIG.agentFqn;

const AGENT_TOOLS = [
  { name: 'insurance_operations_analyst', type: 'Cortex Analyst', target: 'SV_INSURANCE_OPS', icon: Database, color: 'text-blue-500 bg-blue-50 dark:bg-blue-900/30' },
  { name: 'data_quality_analyst', type: 'Cortex Analyst', target: 'SV_DATA_QUALITY', icon: Database, color: 'text-purple-500 bg-purple-50 dark:bg-purple-900/30' },
  { name: 'policy_document_search', type: 'Cortex Search', target: 'CORTEX_SEARCH_SVC', icon: Search, color: 'text-green-500 bg-green-50 dark:bg-green-900/30' },
];

const SUGGESTIONS = [
  { q: 'What is the total premium revenue by policy type?', category: 'Analytics' },
  { q: 'How many claims are open and what is the average resolution time?', category: 'Claims' },
  { q: 'What does the health insurance policy say about pre-existing conditions?', category: 'Documents' },
  { q: 'Which tables have the lowest data quality scores?', category: 'Data Quality' },
  { q: 'What is the total revenue at risk by risk category?', category: 'Risk' },
  { q: 'Show me high fraud risk claims above 0.7 score', category: 'Fraud' },
];

const CATEGORY_COLORS: Record<string, string> = {
  Analytics: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400',
  Claims: 'bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400',
  Documents: 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400',
  'Data Quality': 'bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400',
  Risk: 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400',
  Fraud: 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400',
};

interface ChatMsg {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
  toolTrace?: ToolTraceItem[];
  sql?: string;
  requestId?: string;
  latencyMs?: number;
}

export default function AIAssistant() {
  const [messages, setMessages] = useState<ChatMsg[]>([]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [showAgentInfo, setShowAgentInfo] = useState(true);
  const bottomRef = useRef<HTMLDivElement>(null);

  useEffect(() => { bottomRef.current?.scrollIntoView({ behavior: 'smooth' }); }, [messages]);

  const handleSend = async (question?: string) => {
    const q = (question || input).trim();
    if (!q || isLoading) return;
    setInput('');

    const userMsg: ChatMsg = { id: crypto.randomUUID(), role: 'user', content: q, timestamp: new Date() };
    setMessages(prev => [...prev, userMsg]);
    setIsLoading(true);

    const startTime = Date.now();
    try {
      const response: AgentResponse = await runAgentQuery(q);
      const latencyMs = Date.now() - startTime;

      const assistantMsg: ChatMsg = {
        id: crypto.randomUUID(),
        role: 'assistant',
        content: response.text,
        timestamp: new Date(),
        toolTrace: response.toolTrace,
        sql: response.sql,
        requestId: response.requestId,
        latencyMs,
      };
      setMessages(prev => [...prev, assistantMsg]);
    } catch (err: any) {
      setMessages(prev => [...prev, {
        id: crypto.randomUUID(),
        role: 'assistant',
        content: `**Error:** ${err.message}\n\nPlease check your connection and try again.`,
        timestamp: new Date(),
        latencyMs: Date.now() - startTime,
      }]);
    } finally {
      setIsLoading(false);
    }
  };

  const handleClear = () => {
    setMessages([]);
    clearConversation();
  };

  return (
    <div className="flex h-[calc(100vh-8rem)]">
      {/* Main Chat Area */}
      <div className="flex-1 flex flex-col min-w-0">

        {/* Agent Header Bar */}
        <div className="flex items-center justify-between px-4 py-2.5 bg-white dark:bg-slate-800 border-b border-gray-200 dark:border-slate-700 rounded-t-xl">
          <div className="flex items-center gap-3">
            <div className="relative">
              <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center">
                <Bot className="w-5 h-5 text-white" />
              </div>
              <div className="absolute -bottom-0.5 -right-0.5 w-3.5 h-3.5 bg-green-500 rounded-full border-2 border-white dark:border-slate-800" />
            </div>
            <div>
              <h3 className="text-sm font-bold text-gray-900 dark:text-white">{AGENT_NAME}</h3>
              <p className="text-xs text-green-600 dark:text-green-400 flex items-center gap-1">
                <Zap className="w-3 h-3" /> Live — {AGENT_FQN}
              </p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <span className="hidden sm:flex items-center gap-1 text-xs text-gray-500 dark:text-slate-400 bg-gray-100 dark:bg-slate-700 px-2 py-1 rounded">
              <Database className="w-3 h-3" /> 3 tools
            </span>
            <button onClick={() => setShowAgentInfo(!showAgentInfo)} className="text-xs text-brand-600 hover:underline">
              {showAgentInfo ? 'Hide' : 'Show'} info
            </button>
          </div>
        </div>

        {/* Messages */}
        <div className="flex-1 overflow-y-auto space-y-4 p-4 scrollbar-thin">
          {messages.length === 0 && (
            <div className="flex flex-col items-center justify-center h-full text-center px-4">
              <div className="w-20 h-20 rounded-2xl bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center mb-5 shadow-lg shadow-blue-500/20">
                <Sparkles className="w-10 h-10 text-white" />
              </div>
              <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-1">{AGENT_NAME}</h2>
              <p className="text-sm text-gray-500 dark:text-slate-400 max-w-lg mb-2">
                Powered by Snowflake Cortex — combines <strong>structured analytics</strong>, <strong>document search</strong>, and <strong>data quality intelligence</strong> in one conversational interface.
              </p>
              <p className="text-xs text-gray-400 dark:text-slate-500 mb-6 font-mono">{AGENT_FQN}</p>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 max-w-2xl w-full">
                {SUGGESTIONS.map((s, i) => (
                  <button
                    key={i}
                    onClick={() => handleSend(s.q)}
                    className="text-left px-4 py-3 rounded-xl border border-gray-200 dark:border-slate-700 hover:bg-gray-50 dark:hover:bg-slate-700 transition-colors group"
                  >
                    <span className={`inline-block text-[10px] font-semibold px-1.5 py-0.5 rounded mb-1.5 ${CATEGORY_COLORS[s.category] || 'bg-gray-100 text-gray-600'}`}>
                      {s.category}
                    </span>
                    <p className="text-sm text-gray-600 dark:text-slate-400 group-hover:text-gray-900 dark:group-hover:text-white transition-colors">{s.q}</p>
                  </button>
                ))}
              </div>
            </div>
          )}

          {messages.map((msg) => (
            <div key={msg.id}>
              <div className={`flex gap-3 ${msg.role === 'user' ? 'justify-end' : ''}`}>
                {msg.role === 'assistant' && (
                  <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center flex-shrink-0 mt-1">
                    <Bot className="w-4 h-4 text-white" />
                  </div>
                )}
                <div className={`max-w-2xl rounded-2xl px-4 py-3 text-sm leading-relaxed ${
                  msg.role === 'user'
                    ? 'bg-brand-600 text-white'
                    : 'bg-white dark:bg-slate-800 text-gray-700 dark:text-slate-300 border border-gray-200 dark:border-slate-700'
                }`}>
                  <div className="whitespace-pre-wrap">{msg.content}</div>
                  <div className="mt-2 flex items-center gap-3 text-xs opacity-50">
                    <span>{msg.timestamp.toLocaleTimeString()}</span>
                    {msg.latencyMs && <span className="flex items-center gap-0.5"><Clock className="w-3 h-3" /> {(msg.latencyMs / 1000).toFixed(1)}s</span>}
                  </div>
                </div>
                {msg.role === 'user' && (
                  <div className="w-8 h-8 rounded-lg bg-brand-600 flex items-center justify-center flex-shrink-0 mt-1">
                    <User className="w-4 h-4 text-white" />
                  </div>
                )}
              </div>

              {/* Tool Trace (below assistant messages) */}
              {msg.role === 'assistant' && msg.toolTrace && msg.toolTrace.length > 0 && (
                <ToolTracePanel trace={msg.toolTrace} sql={msg.sql} requestId={msg.requestId} />
              )}
            </div>
          ))}

          {isLoading && (
            <div className="flex gap-3">
              <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center flex-shrink-0">
                <Bot className="w-4 h-4 text-white animate-pulse" />
              </div>
              <div className="bg-white dark:bg-slate-800 border border-gray-200 dark:border-slate-700 rounded-2xl px-4 py-3">
                <p className="text-xs text-gray-500 dark:text-slate-400 mb-2">Agent is processing...</p>
                <div className="flex gap-1">
                  <div className="w-2 h-2 bg-brand-500 rounded-full animate-bounce" style={{ animationDelay: '0ms' }} />
                  <div className="w-2 h-2 bg-brand-500 rounded-full animate-bounce" style={{ animationDelay: '150ms' }} />
                  <div className="w-2 h-2 bg-brand-500 rounded-full animate-bounce" style={{ animationDelay: '300ms' }} />
                </div>
              </div>
            </div>
          )}
          <div ref={bottomRef} />
        </div>

        {/* Input */}
        <div className="border-t border-gray-200 dark:border-slate-700 p-4 bg-white dark:bg-slate-800 rounded-b-xl">
          <div className="flex gap-2">
            {messages.length > 0 && (
              <button onClick={handleClear} className="p-3 rounded-xl border border-gray-200 dark:border-slate-700 text-gray-400 hover:text-red-500 transition-colors" title="Clear conversation">
                <Trash2 className="w-5 h-5" />
              </button>
            )}
            <div className="flex-1 flex items-center bg-gray-50 dark:bg-slate-700 rounded-xl border border-gray-200 dark:border-slate-600 focus-within:ring-2 focus-within:ring-brand-500 focus-within:border-brand-500">
              <input
                value={input}
                onChange={(e) => setInput(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && !e.shiftKey && handleSend()}
                placeholder={`Ask ${AGENT_NAME} about insurance data...`}
                className="flex-1 px-4 py-3 bg-transparent text-sm text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none"
                disabled={isLoading}
              />
              <button onClick={() => handleSend()} disabled={!input.trim() || isLoading}
                className="p-3 text-brand-600 hover:text-brand-700 disabled:opacity-30">
                <Send className="w-5 h-5" />
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Right Sidebar — Agent Info */}
      {showAgentInfo && (
        <div className="w-72 flex-shrink-0 ml-4 bg-white dark:bg-slate-800 rounded-xl border border-gray-200 dark:border-slate-700 overflow-y-auto p-4 hidden lg:block">
          <h3 className="text-sm font-bold text-gray-900 dark:text-white mb-4 flex items-center gap-2">
            <Bot className="w-4 h-4 text-brand-600" /> Agent Configuration
          </h3>

          {/* Agent Identity */}
          <div className="mb-4 p-3 rounded-lg bg-gray-50 dark:bg-slate-700/50">
            <p className="text-xs text-gray-500 dark:text-slate-400">Agent Name</p>
            <p className="text-sm font-mono font-bold text-gray-900 dark:text-white">{AGENT_NAME}</p>
            <p className="text-xs text-gray-500 dark:text-slate-400 mt-2">Location</p>
            <p className="text-xs font-mono text-gray-600 dark:text-slate-300">{AGENT_FQN}</p>
            <p className="text-xs text-gray-500 dark:text-slate-400 mt-2">Status</p>
            <span className="inline-flex items-center gap-1 text-xs font-medium text-green-700 dark:text-green-400">
              <span className="w-1.5 h-1.5 rounded-full bg-green-500" /> Published (VERSION$2)
            </span>
          </div>

          {/* Tools */}
          <h4 className="text-xs font-semibold text-gray-500 dark:text-slate-400 uppercase mb-2">Tools (3)</h4>
          <div className="space-y-2 mb-4">
            {AGENT_TOOLS.map((tool) => (
              <div key={tool.name} className="p-2.5 rounded-lg border border-gray-100 dark:border-slate-600">
                <div className="flex items-center gap-2">
                  <div className={`w-6 h-6 rounded flex items-center justify-center ${tool.color}`}>
                    <tool.icon className="w-3 h-3" />
                  </div>
                  <div className="min-w-0">
                    <p className="text-xs font-medium text-gray-900 dark:text-white truncate">{tool.name}</p>
                    <p className="text-[10px] text-gray-500 dark:text-slate-400">{tool.type}</p>
                  </div>
                </div>
                <p className="text-[10px] font-mono text-gray-400 dark:text-slate-500 mt-1 truncate">{tool.target}</p>
              </div>
            ))}
          </div>

          {/* Capabilities */}
          <h4 className="text-xs font-semibold text-gray-500 dark:text-slate-400 uppercase mb-2">Capabilities</h4>
          <ul className="space-y-1.5 text-xs text-gray-600 dark:text-slate-400">
            <li className="flex items-center gap-2"><CheckCircle2 className="w-3 h-3 text-green-500" /> Structured data analytics</li>
            <li className="flex items-center gap-2"><CheckCircle2 className="w-3 h-3 text-green-500" /> Policy document search (RAG)</li>
            <li className="flex items-center gap-2"><CheckCircle2 className="w-3 h-3 text-green-500" /> Data quality investigation</li>
            <li className="flex items-center gap-2"><CheckCircle2 className="w-3 h-3 text-green-500" /> Multi-turn conversation</li>
            <li className="flex items-center gap-2"><CheckCircle2 className="w-3 h-3 text-green-500" /> Cross-domain reasoning</li>
            <li className="flex items-center gap-2"><CheckCircle2 className="w-3 h-3 text-green-500" /> Source citations</li>
          </ul>

          {/* Data Sources */}
          <h4 className="text-xs font-semibold text-gray-500 dark:text-slate-400 uppercase mt-4 mb-2">Data Sources</h4>
          <div className="text-[10px] font-mono text-gray-500 dark:text-slate-500 space-y-1">
            <p>ANALYTICS: 6 tables (1,585 rows)</p>
            <p>DOCUMENTS: 25 indexed chunks</p>
            <p>DATA_QUALITY: 4 tables (146 rows)</p>
          </div>
        </div>
      )}
    </div>
  );
}

/* Collapsible Tool Trace Panel */
function ToolTracePanel({ trace, sql, requestId }: { trace: ToolTraceItem[]; sql?: string; requestId?: string }) {
  const [open, setOpen] = useState(false);

  return (
    <div className="ml-11 mt-1 mb-2">
      <button onClick={() => setOpen(!open)}
        className="flex items-center gap-1.5 text-xs text-gray-400 dark:text-slate-500 hover:text-gray-600 dark:hover:text-slate-300 transition-colors">
        {open ? <ChevronDown className="w-3 h-3" /> : <ChevronRight className="w-3 h-3" />}
        <FileCode className="w-3 h-3" />
        Tool Trace ({trace.length} tool{trace.length !== 1 ? 's' : ''} called)
        {requestId && <span className="opacity-50">· {requestId.substring(0, 8)}</span>}
      </button>
      {open && (
        <div className="mt-2 p-3 bg-gray-50 dark:bg-slate-700/50 rounded-lg border border-gray-200 dark:border-slate-600 space-y-2">
          {trace.map((t, i) => (
            <div key={i} className="flex items-center gap-2 text-xs">
              <span className="w-1.5 h-1.5 rounded-full bg-green-500" />
              <span className="font-medium text-gray-700 dark:text-slate-300">{t.toolName}</span>
              <span className="text-gray-400">({t.toolType})</span>
              {t.target && <span className="font-mono text-gray-500 dark:text-slate-400">→ {t.target}</span>}
            </div>
          ))}
          {sql && (
            <div className="mt-2">
              <p className="text-[10px] font-semibold text-gray-500 dark:text-slate-400 uppercase mb-1">Generated SQL</p>
              <pre className="text-[11px] font-mono bg-gray-900 text-green-400 p-2.5 rounded overflow-x-auto max-h-32 scrollbar-thin">
                {sql}
              </pre>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
