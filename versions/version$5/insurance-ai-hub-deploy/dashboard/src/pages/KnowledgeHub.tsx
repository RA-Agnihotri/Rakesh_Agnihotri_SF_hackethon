import { useState, useRef, useEffect } from 'react';
import { Search, FileText, Bot, Send, Loader2, User, Sparkles, X, BookOpen, Mic, MicOff, Languages } from 'lucide-react';
import { useSnowflakeQuery, toObjects } from '../hooks/useSnowflakeQuery';
import { getToken } from '../services/snowflake-api';
import RefreshButton from '../components/shared/RefreshButton';
import { useRefresh } from '../hooks/useSnowflakeQuery';
import { useVoiceInput } from '../hooks/useVoiceInput';
import { detectAndTranslate, type TranslationResult } from '../services/translate';

const DOCS_SQL = `
  SELECT DOCUMENT_ID, DOCUMENT_TITLE, DOCUMENT_TYPE, DOCUMENT_STATUS, PAGE_COUNT,
         LEFT(CONTENT_TEXT, 200) AS PREVIEW
  FROM INSURANCE_AI_HUB.DOCUMENTS.POLICY_DOCUMENTS
  ORDER BY DOCUMENT_ID`;

const CHUNKS_SQL = `
  SELECT CHUNK_ID, DOCUMENT_ID, CHUNK_INDEX, SECTION_TITLE, TOKEN_COUNT,
         LEFT(CHUNK_TEXT, 150) AS CHUNK_PREVIEW
  FROM INSURANCE_AI_HUB.DOCUMENTS.DOCUMENT_CHUNKS
  ORDER BY DOCUMENT_ID, CHUNK_INDEX`;

const SUGGESTIONS = [
  'What does the health insurance policy cover?',
  'What are the exclusions for auto insurance?',
  'What is the deductible for the homeowners policy?',
  'Explain the life insurance death benefit and exclusions',
  'What is the coverage limit for the umbrella policy?',
  'How do I file a claim under the health policy?',
  'What does workers compensation cover?',
  'What are the disability insurance benefit terms?',
];

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

export default function KnowledgeHub() {
  const docsQ = useSnowflakeQuery('kh-docs', DOCS_SQL);
  const chunksQ = useSnowflakeQuery('kh-chunks', CHUNKS_SQL);
  const refreshDocs = useRefresh('kh-docs');

  const docs = toObjects(docsQ.data);
  const chunks = toObjects(chunksQ.data);

  const [selectedDocId, setSelectedDocId] = useState('');
  const [filterQuery, setFilterQuery] = useState('');

  // Chat state
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

  // Auto-select first doc
  useEffect(() => { if (docs.length > 0 && !selectedDocId) setSelectedDocId(docs[0].DOCUMENT_ID); }, [docs]);

  const selectedDoc = docs.find((d: any) => d.DOCUMENT_ID === selectedDocId);
  const selectedChunks = chunks.filter((c: any) => c.DOCUMENT_ID === selectedDocId);
  const filteredDocs = filterQuery
    ? docs.filter((d: any) => d.DOCUMENT_TITLE.toLowerCase().includes(filterQuery.toLowerCase()) || d.DOCUMENT_TYPE.toLowerCase().includes(filterQuery.toLowerCase()))
    : docs;

  // Ask the Agent about documents
  const handleAsk = async (question?: string) => {
    const q = (question || input).trim();
    if (!q || isLoading) return;
    setInput('');

    const userMsg: ChatMsg = { id: crypto.randomUUID(), role: 'user', content: q, timestamp: new Date() };
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
          messages: [{ role: 'user', content: [{ type: 'text', text: q }] }],
          stream: false,
        }),
      });

      if (!resp.ok) throw new Error(`Agent error ${resp.status}: ${resp.statusText}`);

      const contentType = resp.headers.get('content-type') || '';
      let content: any[] = [];

      if (contentType.includes('text/event-stream') || contentType.includes('text/plain')) {
        // SSE fallback parser
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
        content = result.content || result.choices?.[0]?.message?.content || [];
        if (typeof content === 'string') content = [{ type: 'text', text: content }];
      }

      // Extract text from response
      let answer = '';
      for (const block of content) {
        if (block.type === 'text' && block.text) {
          answer += block.text;
        }
        if (block.type === 'tool_result') {
          const tr = block.tool_result || block;
          const trContent = Array.isArray(tr.content) ? tr.content : [tr.content || {}];
          for (const c of trContent) {
            if (c.type === 'json' && c.json?.results) {
              // Cortex Search results — show cited passages
              const results = Array.isArray(c.json.results) ? c.json.results : [];
              for (const r of results) {
                const text = r.CHUNK_TEXT || r.text || '';
                if (text) {
                  const title = r.SECTION_TITLE || r.DOCUMENT_TITLE || 'Document';
                  const docId = r.DOCUMENT_ID || '';
                  answer += `\n\n**${title}** (${docId}):\n> ${text.substring(0, 400)}`;
                }
              }
            }
          }
        }
      }

      setMessages(prev => [...prev, {
        id: crypto.randomUUID(),
        role: 'assistant',
        content: answer || 'The agent processed your question but returned no text content.',
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

  if (docsQ.isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="w-8 h-8 text-brand-600 animate-spin" />
        <span className="ml-3 text-gray-500">Loading documents...</span>
      </div>
    );
  }

  return (
    <div className="flex gap-4 h-[calc(100vh-8rem)]">
      {/* Left: Document Browser */}
      <div className="w-80 flex-shrink-0 flex flex-col">
        <div className="flex items-center gap-2 mb-3">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              value={filterQuery}
              onChange={(e) => setFilterQuery(e.target.value)}
              placeholder="Filter documents..."
              className="w-full pl-10 pr-4 py-2 bg-white dark:bg-slate-800 border border-gray-200 dark:border-slate-700 rounded-lg text-sm focus:ring-2 focus:ring-brand-500 focus:outline-none"
            />
          </div>
          <RefreshButton onRefresh={refreshDocs} label="" />
        </div>

        <div className="flex-1 overflow-y-auto space-y-2 scrollbar-thin">
          {filteredDocs.map((doc: any) => (
            <button
              key={doc.DOCUMENT_ID}
              onClick={() => setSelectedDocId(doc.DOCUMENT_ID)}
              className={`w-full text-left p-3 rounded-xl border transition-colors ${
                selectedDocId === doc.DOCUMENT_ID
                  ? 'border-brand-500 bg-brand-50 dark:bg-brand-900/20'
                  : 'border-gray-200 dark:border-slate-700 bg-white dark:bg-slate-800 hover:bg-gray-50 dark:hover:bg-slate-700'
              }`}
            >
              <div className="flex items-start gap-2.5">
                <FileText className="w-4 h-4 text-brand-500 mt-0.5 flex-shrink-0" />
                <div className="min-w-0">
                  <p className="font-medium text-xs text-gray-900 dark:text-white truncate">{doc.DOCUMENT_TITLE}</p>
                  <p className="text-[10px] text-gray-500 dark:text-slate-400 mt-0.5">
                    {doc.DOCUMENT_ID} · {doc.DOCUMENT_TYPE} · {doc.PAGE_COUNT}pg
                  </p>
                  {doc.PREVIEW && (
                    <p className="text-[10px] text-gray-400 mt-1 line-clamp-2">{doc.PREVIEW}</p>
                  )}
                </div>
                <span className={`flex-shrink-0 text-[10px] px-1.5 py-0.5 rounded ${
                  doc.DOCUMENT_STATUS === 'Active'
                    ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400'
                    : 'bg-gray-100 text-gray-600'
                }`}>
                  {doc.DOCUMENT_STATUS}
                </span>
              </div>
            </button>
          ))}
          {filteredDocs.length === 0 && (
            <p className="text-center text-sm text-gray-400 py-8">No documents found</p>
          )}
        </div>

        {/* Selected Doc Chunks */}
        {selectedDoc && (
          <div className="mt-3 pt-3 border-t border-gray-200 dark:border-slate-700">
            <p className="text-[10px] font-semibold text-gray-500 dark:text-slate-400 uppercase mb-2">
              Indexed Chunks ({selectedChunks.length})
            </p>
            <div className="max-h-36 overflow-y-auto space-y-1 scrollbar-thin">
              {selectedChunks.map((c: any) => (
                <div key={c.CHUNK_ID} className="p-2 rounded bg-gray-50 dark:bg-slate-700/50 text-[10px]">
                  <span className="font-semibold text-brand-600">{c.SECTION_TITLE}</span>
                  <span className="text-gray-400 ml-1">({c.TOKEN_COUNT} tokens)</span>
                  <p className="text-gray-500 dark:text-slate-400 mt-0.5 truncate">{c.CHUNK_PREVIEW}</p>
                </div>
              ))}
              {selectedChunks.length === 0 && (
                <p className="text-[10px] text-gray-400 py-2">No chunks indexed for this document</p>
              )}
            </div>
          </div>
        )}
      </div>

      {/* Right: Agent Chat for Document Q&A */}
      <div className="flex-1 flex flex-col min-w-0 bg-white dark:bg-slate-800 rounded-xl border border-gray-200 dark:border-slate-700">
        {/* Header */}
        <div className="flex items-center justify-between px-4 py-3 border-b border-gray-200 dark:border-slate-700">
          <div className="flex items-center gap-3">
            <div className="relative">
              <div className="w-9 h-9 rounded-lg bg-gradient-to-br from-green-500 to-teal-600 flex items-center justify-center">
                <BookOpen className="w-4 h-4 text-white" />
              </div>
              <div className="absolute -bottom-0.5 -right-0.5 w-3 h-3 bg-green-500 rounded-full border-2 border-white dark:border-slate-800" />
            </div>
            <div>
              <h3 className="text-sm font-bold text-gray-900 dark:text-white">Knowledge Assistant</h3>
              <p className="text-[10px] text-green-600 dark:text-green-400">
                Powered by INSURANCE_INTELLIGENCE_AGENT · Cortex Search (RAG)
              </p>
            </div>
          </div>
          {messages.length > 0 && (
            <button
              onClick={() => setMessages([])}
              className="text-xs text-gray-400 hover:text-red-500 flex items-center gap-1 transition-colors"
            >
              <X className="w-3 h-3" /> Clear Chat
            </button>
          )}
        </div>

        {/* Chat Messages */}
        <div className="flex-1 overflow-y-auto p-4 space-y-3 scrollbar-thin">
          {messages.length === 0 && (
            <div className="flex flex-col items-center justify-center h-full text-center px-4">
              <Sparkles className="w-12 h-12 text-green-300 dark:text-green-700 mb-3" />
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-1">
                Ask About Policy Documents
              </h3>
              <p className="text-sm text-gray-500 dark:text-slate-400 max-w-md mb-5">
                Questions are answered by the Cortex Agent using <strong>Cortex Search</strong> over{' '}
                <strong>25 indexed document chunks</strong> with source citations. Select a document on the left to see its indexed chunks.
              </p>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 max-w-lg w-full">
                {SUGGESTIONS.slice(0, 6).map((s, i) => (
                  <button
                    key={i}
                    onClick={() => handleAsk(s)}
                    className="text-left px-3 py-2.5 rounded-lg border border-gray-200 dark:border-slate-700 text-xs text-gray-600 dark:text-slate-400 hover:bg-green-50 dark:hover:bg-green-900/20 hover:border-green-300 dark:hover:border-green-700 transition-colors"
                  >
                    {s}
                  </button>
                ))}
              </div>
            </div>
          )}

          {messages.map((msg) => (
            <div key={msg.id} className={`flex gap-2.5 ${msg.role === 'user' ? 'justify-end' : ''}`}>
              {msg.role === 'assistant' && (
                <div className="w-7 h-7 rounded-lg bg-gradient-to-br from-green-500 to-teal-600 flex items-center justify-center flex-shrink-0 mt-1">
                  <Bot className="w-3.5 h-3.5 text-white" />
                </div>
              )}
              <div className={`max-w-xl rounded-2xl px-4 py-2.5 text-sm leading-relaxed ${
                msg.role === 'user'
                  ? 'bg-brand-600 text-white'
                  : 'bg-gray-50 dark:bg-slate-700/50 text-gray-700 dark:text-slate-300 border border-gray-200 dark:border-slate-600'
              }`}>
                <div className="whitespace-pre-wrap">{msg.content}</div>
                <div className="mt-1 text-[10px] opacity-40">
                  {msg.timestamp.toLocaleTimeString()}
                </div>
              </div>
              {msg.role === 'user' && (
                <div className="w-7 h-7 rounded-lg bg-brand-600 flex items-center justify-center flex-shrink-0 mt-1">
                  <User className="w-3.5 h-3.5 text-white" />
                </div>
              )}
            </div>
          ))}

          {isLoading && (
            <div className="flex gap-2.5">
              <div className="w-7 h-7 rounded-lg bg-gradient-to-br from-green-500 to-teal-600 flex items-center justify-center flex-shrink-0">
                <Bot className="w-3.5 h-3.5 text-white animate-pulse" />
              </div>
              <div className="bg-gray-50 dark:bg-slate-700/50 border border-gray-200 dark:border-slate-600 rounded-2xl px-4 py-2.5">
                <p className="text-xs text-gray-500 mb-1">Searching documents...</p>
                <div className="flex gap-1">
                  <div className="w-1.5 h-1.5 bg-green-500 rounded-full animate-bounce" style={{ animationDelay: '0ms' }} />
                  <div className="w-1.5 h-1.5 bg-green-500 rounded-full animate-bounce" style={{ animationDelay: '150ms' }} />
                  <div className="w-1.5 h-1.5 bg-green-500 rounded-full animate-bounce" style={{ animationDelay: '300ms' }} />
                </div>
              </div>
            </div>
          )}
          <div ref={bottomRef} />
        </div>

        {/* Input */}
        <div className="border-t border-gray-200 dark:border-slate-700 p-3">
          {(voice.state === 'recording' || isTranslating || voice.error || translationInfo) && (
            <div className="mb-2 flex items-center gap-2 text-xs">
              {voice.state === 'recording' && <span className="flex items-center gap-1.5 text-red-500 font-medium"><span className="w-2 h-2 rounded-full bg-red-500 animate-pulse" />Listening...</span>}
              {isTranslating && <span className="flex items-center gap-1.5 text-blue-500 font-medium"><Loader2 className="w-3 h-3 animate-spin" /> Translating...</span>}
              {voice.error && <span className="text-red-500">{voice.error}</span>}
              {translationInfo && !isTranslating && <span className="flex items-center gap-1.5 text-emerald-600 dark:text-emerald-400"><Languages className="w-3 h-3" /> Translated from: "{translationInfo.originalText}"</span>}
            </div>
          )}
          <div className="flex gap-2">
            <div className="flex-1 flex items-center bg-gray-50 dark:bg-slate-700 rounded-lg border border-gray-200 dark:border-slate-600 focus-within:ring-2 focus-within:ring-green-500 focus-within:border-green-500">
              <input
                value={input}
                onChange={(e) => { setInput(e.target.value); setTranslationInfo(null); }}
                onKeyDown={(e) => e.key === 'Enter' && !e.shiftKey && handleAsk()}
                placeholder={voice.state === 'recording' ? 'Listening...' : 'Ask about policy coverage, exclusions, claims procedures...'}
                className="flex-1 px-3 py-2.5 bg-transparent text-sm text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none"
                disabled={isLoading || voice.state === 'recording'}
              />
              {voice.isSupported && (
                <button onClick={voice.state === 'recording' ? voice.stopRecording : voice.startRecording} disabled={isLoading || isTranslating}
                  className={`p-2.5 transition-colors ${voice.state === 'recording' ? 'text-red-500 hover:text-red-600' : 'text-gray-400 hover:text-green-600'} disabled:opacity-30`}
                  title={voice.state === 'recording' ? 'Stop recording' : 'Voice input'}>
                  {voice.state === 'recording' ? <MicOff className="w-4 h-4" /> : isTranslating ? <Loader2 className="w-4 h-4 animate-spin" /> : <Mic className="w-4 h-4" />}
                </button>
              )}
              <button
                onClick={() => handleAsk()}
                disabled={!input.trim() || isLoading}
                className="p-2.5 text-green-600 hover:text-green-700 disabled:opacity-30 transition-opacity"
              >
                <Send className="w-4 h-4" />
              </button>
            </div>
          </div>
          <p className="text-[10px] text-gray-400 mt-1.5 text-center">
            Powered by Cortex Search (RAG) over POLICY_DOCUMENTS &amp; DOCUMENT_CHUNKS
          </p>
        </div>
      </div>
    </div>
  );
}
