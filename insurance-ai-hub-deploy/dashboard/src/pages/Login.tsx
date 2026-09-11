import { useState } from 'react';
import { Activity, Key, ArrowRight, AlertCircle } from 'lucide-react';
import { setToken } from '../services/snowflake-api';
import { executeSQL } from '../services/snowflake-api';
import { SNOWFLAKE_CONFIG } from '../lib/constants';

interface Props {
  onLogin: () => void;
}

export default function Login({ onLogin }: Props) {
  const [pat, setPat] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleLogin = async () => {
    if (!pat.trim()) { setError('Please enter your PAT token'); return; }
    setLoading(true);
    setError('');

    try {
      setToken(pat.trim());
      // Validate token AND warm up warehouse — touches multiple tables for cache priming
      await executeSQL(`SELECT CURRENT_USER(), CURRENT_ROLE(), CURRENT_WAREHOUSE(),
        (SELECT COUNT(*) FROM INSURANCE_AI_HUB.ANALYTICS.POLICIES) AS T1,
        (SELECT COUNT(*) FROM INSURANCE_AI_HUB.ANALYTICS.CLAIMS) AS T2,
        (SELECT COUNT(*) FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_SCORES) AS T3`);
      onLogin();
    } catch (err: any) {
      setError(err.message || 'Authentication failed. Please check your PAT token.');
      setToken('');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-950 to-slate-900 flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-blue-600/20 border border-blue-500/30 mb-4">
            <Activity className="w-8 h-8 text-blue-400" />
          </div>
          <h1 className="text-2xl font-bold text-white">Insurance Intelligence Platform</h1>
          <p className="text-slate-400 mt-2 text-sm">Connect to Snowflake with your Programmatic Access Token</p>
        </div>

        <div className="bg-slate-800/50 backdrop-blur rounded-2xl border border-slate-700 p-6">
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-slate-300 mb-1.5">Account</label>
              <div className="px-3 py-2.5 bg-slate-700/50 rounded-lg text-sm text-slate-400 border border-slate-600">
                {SNOWFLAKE_CONFIG.accountUrl.replace('https://', '').replace('.snowflakecomputing.com', '')}
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-300 mb-1.5">
                <Key className="w-3.5 h-3.5 inline mr-1" />
                PAT Token
              </label>
              <input
                type="password"
                value={pat}
                onChange={(e) => { setPat(e.target.value); setError(''); }}
                onKeyDown={(e) => e.key === 'Enter' && handleLogin()}
                placeholder="Paste your Programmatic Access Token here..."
                className="w-full px-3 py-2.5 bg-slate-700/50 border border-slate-600 rounded-lg text-sm text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                autoFocus
              />
            </div>

            {error && (
              <div className="flex items-start gap-2 p-3 bg-red-500/10 border border-red-500/30 rounded-lg">
                <AlertCircle className="w-4 h-4 text-red-400 flex-shrink-0 mt-0.5" />
                <p className="text-sm text-red-400">{error}</p>
              </div>
            )}

            <button
              onClick={handleLogin}
              disabled={loading || !pat.trim()}
              className="w-full flex items-center justify-center gap-2 py-2.5 bg-blue-600 hover:bg-blue-700 disabled:bg-blue-600/50 disabled:cursor-not-allowed text-white font-medium rounded-lg text-sm transition-colors"
            >
              {loading ? (
                <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
              ) : (
                <>Connect <ArrowRight className="w-4 h-4" /></>
              )}
            </button>
          </div>

          <div className="mt-5 pt-5 border-t border-slate-700">
            <p className="text-xs text-slate-500 leading-relaxed">
              <strong className="text-slate-400">How to get a PAT token:</strong><br />
              Snowsight → User Menu (bottom-left) → My Profile → Programmatic Access Tokens → Generate New Token
            </p>
            <div className="mt-3 flex gap-2 text-xs text-slate-500">
              <span className="px-2 py-0.5 bg-slate-700 rounded">Role: {SNOWFLAKE_CONFIG.role}</span>
              <span className="px-2 py-0.5 bg-slate-700 rounded">WH: {SNOWFLAKE_CONFIG.warehouse}</span>
              <span className="px-2 py-0.5 bg-slate-700 rounded">DB: {SNOWFLAKE_CONFIG.database}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
