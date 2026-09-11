import KPICard from '../components/dashboard/KPICard';
import RefreshButton from '../components/shared/RefreshButton';
import StatusBadge from '../components/shared/StatusBadge';
import { useSnowflakeQuery, useRefresh, toObjects } from '../hooks/useSnowflakeQuery';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { Loader2 } from 'lucide-react';

const GOV_SQL = `
WITH scores AS (SELECT 'SCR' AS SECTION, TABLE_NAME AS C1, OVERALL_SCORE::VARCHAR AS C2, COMPLETENESS_SCORE::VARCHAR AS C3, ACCURACY_SCORE::VARCHAR AS C4, CONSISTENCY_SCORE::VARCHAR AS C5, TIMELINESS_SCORE::VARCHAR AS C6, RULES_PASSED::VARCHAR AS C7, RULES_FAILED::VARCHAR AS C8, TREND AS C9 FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_SCORES WHERE SCORE_DATE=(SELECT MAX(SCORE_DATE) FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_SCORES)),
failures AS (SELECT 'FAIL' AS SECTION, r.TARGET_TABLE||'.'||r.TARGET_COLUMN AS C1, rl.RULE_NAME AS C2, rl.SEVERITY AS C3, r.PASS_RATE::VARCHAR AS C4, r.FAILED_RECORDS::VARCHAR AS C5, COALESCE(LEFT(r.ERROR_SAMPLE,120),'') AS C6, NULL AS C7, NULL AS C8, NULL AS C9 FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_RESULTS r JOIN INSURANCE_AI_HUB.DATA_QUALITY.DQ_RULES rl ON r.RULE_ID=rl.RULE_ID WHERE r.STATUS='FAIL' AND DATE(r.EXECUTION_DATE)=(SELECT MAX(DATE(EXECUTION_DATE)) FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_RESULTS WHERE STATUS='FAIL')),
trend AS (SELECT 'TRD' AS SECTION, TABLE_NAME AS C1, SCORE_DATE::VARCHAR AS C2, OVERALL_SCORE::VARCHAR AS C3, NULL AS C4, NULL AS C5, NULL AS C6, NULL AS C7, NULL AS C8, NULL AS C9 FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_SCORES WHERE TABLE_NAME IN ('CUSTOMERS','POLICIES','CLAIMS','BILLING','AGENTS'))
SELECT * FROM scores UNION ALL SELECT * FROM failures UNION ALL SELECT * FROM trend ORDER BY SECTION, C1`;

export default function GovernanceDashboard() {
  const q = useSnowflakeQuery('gov-all', GOV_SQL);
  const refresh = useRefresh('gov-all');
  if (q.isLoading) return <div className="flex items-center justify-center h-64"><Loader2 className="w-8 h-8 text-brand-600 animate-spin" /><span className="ml-3 text-gray-500">Loading...</span></div>;

  const rows = toObjects(q.data);
  const scores = rows.filter(r=>r.SECTION==='SCR'), failures = rows.filter(r=>r.SECTION==='FAIL'), trendRows = rows.filter(r=>r.SECTION==='TRD');
  const avgScore = scores.length?(scores.reduce((s,r)=>s+Number(r.C2),0)/scores.length).toFixed(1):'—';
  const trendDates = [...new Set(trendRows.map(r=>r.C2))].sort();
  const trendData = trendDates.map(d=>{const row:any={week:d};trendRows.filter(r=>r.C2===d).forEach(r=>{row[r.C1]=Number(r.C3)});return row;});

  return (
    <div className="space-y-6">
      <div className="flex justify-end"><RefreshButton onRefresh={refresh} /></div>
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <KPICard label="Trusted Data Index" value={avgScore} trend={Number(avgScore)>=85?'up':'down'} />
        <KPICard label="Failed Rules" value={String(failures.length)} trend="down" />
        <KPICard label="Critical/High" value={String(failures.filter(f=>f.C3==='Critical'||f.C3==='High').length)} trend="down" />
        <KPICard label="Tables Monitored" value={String(scores.length)} trend="stable" />
      </div>
      <div className="bg-white dark:bg-slate-800 rounded-xl border border-gray-200 dark:border-slate-700 overflow-hidden">
        <div className="px-5 py-3 border-b border-gray-200 dark:border-slate-700"><h3 className="font-semibold text-gray-900 dark:text-white">Table Health Scores</h3></div>
        <div className="overflow-x-auto"><table className="w-full text-sm"><thead className="bg-gray-50 dark:bg-slate-700/50"><tr>{['Table','Score','Completeness','Accuracy','Consistency','Timeliness','Passed','Failed','Trend'].map(h=><th key={h} className="px-4 py-3 text-left text-xs font-semibold text-gray-500 dark:text-slate-400 uppercase">{h}</th>)}</tr></thead>
        <tbody className="divide-y divide-gray-100 dark:divide-slate-700">{scores.map(r=>(
          <tr key={r.C1} className="hover:bg-gray-50 dark:hover:bg-slate-700/30">
            <td className="px-4 py-3 font-medium text-gray-900 dark:text-white">{r.C1}</td>
            <td className="px-4 py-3"><span className={`font-bold ${Number(r.C2)>=90?'text-green-600':Number(r.C2)>=80?'text-yellow-600':'text-red-600'}`}>{r.C2}</span></td>
            <td className="px-4 py-3 text-gray-600 dark:text-slate-300">{r.C3}</td><td className="px-4 py-3 text-gray-600 dark:text-slate-300">{r.C4}</td>
            <td className="px-4 py-3 text-gray-600 dark:text-slate-300">{r.C5}</td><td className="px-4 py-3 text-gray-600 dark:text-slate-300">{r.C6}</td>
            <td className="px-4 py-3 text-green-600">{r.C7}</td><td className="px-4 py-3 text-red-600">{r.C8}</td>
            <td className="px-4 py-3"><span className={r.C9==='UP'?'text-green-500':r.C9==='DOWN'?'text-red-500':'text-gray-400'}>{r.C9==='UP'?'↑':r.C9==='DOWN'?'↓':'→'} {r.C9}</span></td>
          </tr>))}</tbody></table></div>
      </div>
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white dark:bg-slate-800 rounded-xl border border-gray-200 dark:border-slate-700 p-5">
          <h3 className="font-semibold text-gray-900 dark:text-white mb-4">DQ Score Trend</h3>
          <ResponsiveContainer width="100%" height={250}><LineChart data={trendData}><CartesianGrid strokeDasharray="3 3"/><XAxis dataKey="week" tick={{fontSize:10}}/><YAxis domain={[60,100]}/><Tooltip/><Legend/><Line type="monotone" dataKey="CUSTOMERS" stroke="#ef4444" strokeWidth={2}/><Line type="monotone" dataKey="POLICIES" stroke="#3b82f6" strokeWidth={2}/><Line type="monotone" dataKey="CLAIMS" stroke="#f59e0b" strokeWidth={2}/><Line type="monotone" dataKey="BILLING" stroke="#22c55e" strokeWidth={2}/><Line type="monotone" dataKey="AGENTS" stroke="#8b5cf6" strokeWidth={2}/></LineChart></ResponsiveContainer>
        </div>
        <div className="bg-white dark:bg-slate-800 rounded-xl border border-gray-200 dark:border-slate-700 p-5">
          <h3 className="font-semibold text-gray-900 dark:text-white mb-4">Failed Rules</h3>
          <div className="space-y-2 max-h-64 overflow-y-auto scrollbar-thin">{failures.map((f,i)=>(
            <div key={i} className="p-3 rounded-lg bg-red-50 dark:bg-red-900/10 border border-red-200 dark:border-red-800/50">
              <div className="flex items-center justify-between"><span className="text-sm font-medium text-red-800 dark:text-red-300">{f.C1}</span><StatusBadge status={f.C3==='Critical'?'Critical':f.C3==='High'?'Warning':'Healthy'}/></div>
              <p className="text-xs text-red-600 dark:text-red-400 mt-1">{f.C2} — Pass: {f.C4}% ({f.C5} failed)</p>
              {f.C6&&<p className="text-xs text-red-500 mt-1 italic truncate">Sample: {f.C6}</p>}
            </div>
          ))}{failures.length===0&&<p className="text-sm text-gray-500 text-center py-4">No failures.</p>}</div>
        </div>
      </div>
    </div>
  );
}
