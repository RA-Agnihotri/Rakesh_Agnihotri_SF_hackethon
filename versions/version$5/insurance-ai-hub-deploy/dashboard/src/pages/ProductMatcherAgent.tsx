import { useState, useRef, useEffect } from 'react';
import KPICard from '../components/dashboard/KPICard';
import DataVisualizer, { type DataSet } from '../components/shared/DataVisualizer';
import { PieChart, Pie, Cell, Tooltip, ResponsiveContainer } from 'recharts';
import { Database, Search, CheckCircle2, Target, Zap, Bot, Send, User, Sparkles, X, Mic, MicOff, Languages, Loader2 } from 'lucide-react';
import { getToken } from '../services/snowflake-api';
import { useVoiceInput } from '../hooks/useVoiceInput';
import { detectAndTranslate, type TranslationResult } from '../services/translate';

const AGENT = 'PRODUCT_MATCHING_AGENT';
const ACCENT = '#f59e0b';
const COLORS = ['#f59e0b', '#3b82f6', '#22c55e', '#8b5cf6'];

const TOOLS = [
  { name: 'product_matching_analyst', type: 'Cortex Analyst', target: 'SV_PRODUCT_MATCHING', icon: Target, color: 'text-orange-500' },
  { name: 'customer_analyst', type: 'Cortex Analyst', target: 'SV_INSURANCE_OPS', icon: Database, color: 'text-blue-500' },
  { name: 'product_search', type: 'Cortex Search', target: 'CORTEX_SEARCH_SVC', icon: Search, color: 'text-green-500' },
];

const ROUTING = [
  { name: 'Match Scores', value: 40 }, { name: 'Customer Profiles', value: 25 },
  { name: 'Product Search', value: 20 }, { name: 'Cross-Domain', value: 15 },
];

const SUGGESTIONS = [
  'What products are the best match for customer CUST-00042?',
  'Which matching strategy performs best for high-risk customers?',
  'Show me the top 5 product recommendations for Corporate segment',
  'What is the match accuracy across all strategies?',
];

function getBaseUrl() { return import.meta.env.DEV ? '' : (import.meta.env.VITE_SNOWFLAKE_ACCOUNT_URL || ''); }

interface ChatMsg { id: string; role: 'user' | 'assistant'; content: string; timestamp: Date; datasets?: DataSet[]; }

function parseAgentContent(contentBlocks: any[]): { text: string; datasets: DataSet[] } {
  const parts: string[] = [];
  const datasets: DataSet[] = [];
  for (const b of contentBlocks) {
    if (b.type === 'text' && b.text) parts.push(b.text);
    if (b.type === 'tool_result' || b.tool_result) {
      const tr = b.tool_result || b;
      const contents = Array.isArray(tr.content) ? tr.content : [tr.content || {}];
      for (const c of contents) {
        if (c.type === 'json' && c.json?.result_set?.data) {
          const rs = c.json.result_set;
          datasets.push({ columns: rs.resultSetMetaData?.rowType?.map((x: any) => x.name) || [], types: rs.resultSetMetaData?.rowType?.map((x: any) => x.type) || [], rows: rs.data });
        }
      }
    }
  }
  return { text: parts.join('') || (datasets.length > 0 ? '' : 'No text returned.'), datasets };
}

export default function ProductMatcherAgent() {
  const [messages, setMessages] = useState<ChatMsg[]>([]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [isTranslating, setIsTranslating] = useState(false);
  const [translationInfo, setTranslationInfo] = useState<TranslationResult | null>(null);
  const bottomRef = useRef<HTMLDivElement>(null);
  const handleVoiceResult = async (text: string) => {
    setIsTranslating(true); setTranslationInfo(null);
    try { const r = await detectAndTranslate(text); setInput(r.translatedText); if (r.wasTranslated) setTranslationInfo(r); } catch { setInput(text); } finally { setIsTranslating(false); }
  };
  const voice = useVoiceInput(handleVoiceResult);
  useEffect(() => { bottomRef.current?.scrollIntoView({ behavior: 'smooth' }); }, [messages]);

  const handleAsk = async (question?: string) => {
    const text = (question || input).trim();
    if (!text || isLoading) return;
    setInput('');
    setMessages(prev => [...prev, { id: crypto.randomUUID(), role: 'user', content: text, timestamp: new Date() }]);
    setIsLoading(true);
    try {
      const token = getToken(); if (!token) throw new Error('Not authenticated');
      const resp = await fetch(`${getBaseUrl()}/api/v2/databases/INSURANCE_AI_HUB/schemas/ANALYTICS/agents/${AGENT}:run`, {
        method: 'POST', headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json', 'Accept': 'application/json', 'X-Snowflake-Authorization-Token-Type': 'PROGRAMMATIC_ACCESS_TOKEN' },
        body: JSON.stringify({ messages: [{ role: 'user', content: [{ type: 'text', text }] }], stream: false }),
      });
      if (!resp.ok) throw new Error(`Agent error ${resp.status}`);
      const ct = resp.headers.get('content-type') || ''; let contentBlocks: any[] = [];
      if (ct.includes('text/event-stream') || ct.includes('text/plain')) {
        for (const line of (await resp.text()).split('\n')) { if (!line.startsWith('data: ')) continue; const p = line.slice(6).trim(); if (p === '[DONE]') break; try { const e = JSON.parse(p); if (e.delta?.content) contentBlocks.push(...e.delta.content); if (e.content) contentBlocks.push(...(Array.isArray(e.content) ? e.content : [e.content])); } catch {} }
      } else { const r = await resp.json(); contentBlocks = r.content || []; if (typeof contentBlocks === 'string') contentBlocks = [{ type: 'text', text: contentBlocks }]; }
      const { text: respText, datasets } = parseAgentContent(contentBlocks);
      setMessages(prev => [...prev, { id: crypto.randomUUID(), role: 'assistant', content: respText, timestamp: new Date(), datasets }]);
    } catch (err: any) { setMessages(prev => [...prev, { id: crypto.randomUUID(), role: 'assistant', content: `**Error:** ${err.message}`, timestamp: new Date() }]); } finally { setIsLoading(false); }
  };

  return (
    <div className="flex gap-4 h-[calc(100vh-8rem)]">
      <div className="flex-1 flex flex-col min-w-0 overflow-y-auto space-y-4">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-orange-100 dark:bg-orange-900/30 flex items-center justify-center"><Target className="w-5 h-5 text-orange-600" /></div>
          <div><h1 className="text-xl font-bold text-gray-900 dark:text-white">Product Matcher Agent</h1><p className="text-sm text-gray-500 dark:text-slate-400">Multi-strategy product-customer matching with rule-based, similarity, and AI scoring</p></div>
          <span className="ml-auto px-3 py-1 rounded-full text-xs font-semibold bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400">{AGENT}</span>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <KPICard label="Agent Status" value="LIVE" trend="up" subtitle="Auto Orchestration" />
          <KPICard label="Tools" value="3" trend="stable" subtitle="2 Analyst + 1 Search" />
          <KPICard label="Match Strategies" value="3" trend="stable" subtitle="Rule / Similarity / AI" />
          <KPICard label="MCP" value="Atlassian" trend="up" subtitle="Jira + Confluence" />
        </div>
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          <div className="bg-white dark:bg-slate-800 rounded-xl border border-gray-200 dark:border-slate-700 p-5">
            <h3 className="font-semibold text-gray-900 dark:text-white mb-3">Agent Tools</h3>
            <div className="space-y-2">{TOOLS.map(t => (<div key={t.name} className="flex items-center justify-between p-3 rounded-lg bg-gray-50 dark:bg-slate-700/50"><div className="flex items-center gap-3"><t.icon className={`w-5 h-5 ${t.color}`} /><div><p className="text-sm font-medium text-gray-900 dark:text-white">{t.name}</p><p className="text-xs text-gray-500 dark:text-slate-400">{t.type} → {t.target}</p></div></div><span className="flex items-center gap-1 text-xs text-green-600"><CheckCircle2 className="w-3 h-3" />Active</span></div>))}
              <div className="flex items-center justify-between p-3 rounded-lg bg-orange-50 dark:bg-orange-900/20 border border-orange-200 dark:border-orange-800"><div className="flex items-center gap-3"><Zap className="w-5 h-5 text-orange-500" /><div><p className="text-sm font-medium text-gray-900 dark:text-white">Atlassian MCP</p><p className="text-xs text-gray-500">External MCP → Jira + Confluence</p></div></div><span className="flex items-center gap-1 text-xs text-orange-600"><CheckCircle2 className="w-3 h-3" />Connected</span></div>
            </div>
          </div>
          <div className="bg-white dark:bg-slate-800 rounded-xl border border-gray-200 dark:border-slate-700 p-5">
            <h3 className="font-semibold text-gray-900 dark:text-white mb-3">Expected Routing</h3>
            <ResponsiveContainer width="100%" height={200}><PieChart><Pie data={ROUTING} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={75} label={({ name, percent }: any) => `${name} ${(percent * 100).toFixed(0)}%`}>{ROUTING.map((_, i) => <Cell key={i} fill={COLORS[i]} />)}</Pie><Tooltip /></PieChart></ResponsiveContainer>
          </div>
        </div>
      </div>
      {/* Chat Panel */}
      <div className="w-[380px] flex-shrink-0 flex flex-col bg-white dark:bg-slate-800 rounded-xl border border-gray-200 dark:border-slate-700">
        <div className="flex items-center justify-between px-4 py-3 border-b border-gray-200 dark:border-slate-700">
          <div className="flex items-center gap-3"><div className="relative"><div className="w-9 h-9 rounded-lg bg-gradient-to-br from-orange-500 to-amber-500 flex items-center justify-center"><Target className="w-4 h-4 text-white" /></div><div className="absolute -bottom-0.5 -right-0.5 w-3 h-3 bg-green-500 rounded-full border-2 border-white dark:border-slate-800" /></div><div><h3 className="text-sm font-bold text-gray-900 dark:text-white">Product Match Chat</h3><p className="text-[10px] text-orange-600 dark:text-orange-400">Cortex Agent · Recommendations</p></div></div>
          {messages.length > 0 && <button onClick={() => setMessages([])} className="text-xs text-gray-400 hover:text-red-500 flex items-center gap-1"><X className="w-3 h-3" />Clear</button>}
        </div>
        <div className="flex-1 overflow-y-auto p-3 space-y-3 scrollbar-thin">
          {messages.length === 0 && (<div className="flex flex-col items-center justify-center h-full text-center px-3"><Sparkles className="w-10 h-10 text-orange-300 dark:text-orange-700 mb-3" /><h4 className="text-sm font-semibold text-gray-900 dark:text-white mb-1">Ask About Product Matching</h4><p className="text-xs text-gray-500 dark:text-slate-400 mb-4">Get match scores, recommendations, and strategy analysis.</p><div className="space-y-2 w-full">{SUGGESTIONS.map((s, i) => (<button key={i} onClick={() => handleAsk(s)} className="w-full text-left px-3 py-2 rounded-lg border border-gray-200 dark:border-slate-700 text-xs text-gray-600 dark:text-slate-400 hover:bg-orange-50 dark:hover:bg-orange-900/20 hover:border-orange-300 transition-colors">{s}</button>))}</div></div>)}
          {messages.map(msg => (
            <div key={msg.id} className={`flex gap-2 ${msg.role === 'user' ? 'justify-end' : ''}`}>
              {msg.role === 'assistant' && <div className="w-6 h-6 rounded-lg bg-gradient-to-br from-orange-500 to-amber-500 flex items-center justify-center flex-shrink-0 mt-1"><Bot className="w-3 h-3 text-white" /></div>}
              <div className={`max-w-[85%] rounded-2xl px-3 py-2 text-xs leading-relaxed ${msg.role === 'user' ? 'bg-brand-600 text-white' : 'bg-gray-50 dark:bg-slate-700/50 text-gray-700 dark:text-slate-300 border border-gray-200 dark:border-slate-600'}`}>
                {msg.content && <div className="whitespace-pre-wrap">{msg.content}</div>}
                {msg.datasets && msg.datasets.map((ds, di) => <DataVisualizer key={di} dataset={ds} accentColor={ACCENT} />)}
                <div className="mt-1 text-[9px] opacity-40">{msg.timestamp.toLocaleTimeString()}</div>
              </div>
              {msg.role === 'user' && <div className="w-6 h-6 rounded-lg bg-brand-600 flex items-center justify-center flex-shrink-0 mt-1"><User className="w-3 h-3 text-white" /></div>}
            </div>
          ))}
          {isLoading && <div className="flex gap-2"><div className="w-6 h-6 rounded-lg bg-gradient-to-br from-orange-500 to-amber-500 flex items-center justify-center flex-shrink-0"><Bot className="w-3 h-3 text-white animate-pulse" /></div><div className="bg-gray-50 dark:bg-slate-700/50 border rounded-2xl px-3 py-2"><p className="text-[10px] text-gray-500 mb-1">Finding matches...</p><div className="flex gap-1"><div className="w-1.5 h-1.5 bg-orange-500 rounded-full animate-bounce" style={{ animationDelay: '0ms' }} /><div className="w-1.5 h-1.5 bg-orange-500 rounded-full animate-bounce" style={{ animationDelay: '150ms' }} /><div className="w-1.5 h-1.5 bg-orange-500 rounded-full animate-bounce" style={{ animationDelay: '300ms' }} /></div></div></div>}
          <div ref={bottomRef} />
        </div>
        <div className="border-t border-gray-200 dark:border-slate-700 p-3">
          {(voice.state === 'recording' || isTranslating || voice.error || translationInfo) && (
            <div className="mb-2 flex items-center gap-2 text-[10px]">
              {voice.state === 'recording' && <span className="flex items-center gap-1 text-red-500 font-medium"><span className="w-1.5 h-1.5 rounded-full bg-red-500 animate-pulse" />Listening...</span>}
              {isTranslating && <span className="flex items-center gap-1 text-blue-500"><Loader2 className="w-3 h-3 animate-spin" /> Translating...</span>}
              {voice.error && <span className="text-red-500">{voice.error}</span>}
              {translationInfo && !isTranslating && <span className="flex items-center gap-1 text-emerald-600 dark:text-emerald-400"><Languages className="w-3 h-3" /> Translated</span>}
            </div>
          )}
          <div className="flex items-center bg-gray-50 dark:bg-slate-700 rounded-lg border border-gray-200 dark:border-slate-600 focus-within:ring-2 focus-within:ring-orange-500">
            <input value={input} onChange={e => { setInput(e.target.value); setTranslationInfo(null); }} onKeyDown={e => e.key === 'Enter' && !e.shiftKey && handleAsk()} placeholder={voice.state === 'recording' ? 'Listening...' : 'Ask about product matching...'} className="flex-1 px-3 py-2.5 bg-transparent text-sm text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none" disabled={isLoading || voice.state === 'recording'} />
            {voice.isSupported && <button onClick={voice.state === 'recording' ? voice.stopRecording : voice.startRecording} disabled={isLoading || isTranslating} className={`p-2 transition-colors ${voice.state === 'recording' ? 'text-red-500' : 'text-gray-400 hover:text-orange-600'} disabled:opacity-30`} title={voice.state === 'recording' ? 'Stop' : 'Voice input'}>{voice.state === 'recording' ? <MicOff className="w-4 h-4" /> : isTranslating ? <Loader2 className="w-4 h-4 animate-spin" /> : <Mic className="w-4 h-4" />}</button>}
            <button onClick={() => handleAsk()} disabled={!input.trim() || isLoading} className="p-2.5 text-orange-600 hover:text-orange-700 disabled:opacity-30"><Send className="w-4 h-4" /></button>
          </div>
        </div>
      </div>
    </div>
  );
}
