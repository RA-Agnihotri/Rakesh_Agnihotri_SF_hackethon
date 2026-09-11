import KPICard from '../components/dashboard/KPICard';
import RefreshButton from '../components/shared/RefreshButton';
import { useSnowflakeQuery, useRefresh, toObjects } from '../hooks/useSnowflakeQuery';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, LineChart, Line, CartesianGrid, Legend } from 'recharts';
import { Loader2 } from 'lucide-react';

const COLORS = ['#3b82f6', '#22c55e', '#f59e0b', '#ef4444', '#8b5cf6', '#06b6d4'];

const DASHBOARD_SQL = `
WITH kpis AS (
  SELECT (SELECT SUM(PREMIUM_AMOUNT) FROM INSURANCE_AI_HUB.ANALYTICS.POLICIES WHERE POLICY_STATUS='Active') AS TOTAL_PREMIUM,
    (SELECT SUM(REVENUE_AT_RISK) FROM INSURANCE_AI_HUB.ANALYTICS.AT_RISK_POLICIES) AS REVENUE_AT_RISK,
    (SELECT COUNT(*) FROM INSURANCE_AI_HUB.ANALYTICS.POLICIES WHERE POLICY_STATUS='Active') AS ACTIVE_POLICIES,
    (SELECT COUNT(*) FROM INSURANCE_AI_HUB.ANALYTICS.CLAIMS WHERE CLAIM_STATUS IN ('Open','Under Investigation','Escalated')) AS OPEN_CLAIMS,
    (SELECT ROUND(AVG(DAYS_TO_RESOLVE),1) FROM INSURANCE_AI_HUB.ANALYTICS.CLAIMS WHERE DAYS_TO_RESOLVE IS NOT NULL) AS AVG_RESOLUTION,
    (SELECT COUNT(*) FROM INSURANCE_AI_HUB.ANALYTICS.CLAIMS WHERE FRAUD_SCORE > 0.7) AS HIGH_RISK_CLAIMS,
    (SELECT SUM(CLAIM_AMOUNT) FROM INSURANCE_AI_HUB.ANALYTICS.CLAIMS WHERE FRAUD_SCORE > 0.7) AS FRAUD_EXPOSURE,
    (SELECT COUNT(*) FROM INSURANCE_AI_HUB.ANALYTICS.CUSTOMERS) AS TOTAL_CUSTOMERS
),
pbt AS (SELECT 'PBT' AS SECTION, POLICY_TYPE AS DIM1, NULL AS DIM2, COUNT(*)::VARCHAR AS VAL1, SUM(PREMIUM_AMOUNT)::VARCHAR AS VAL2 FROM INSURANCE_AI_HUB.ANALYTICS.POLICIES WHERE POLICY_STATUS='Active' GROUP BY POLICY_TYPE),
cbs AS (SELECT 'CBS' AS SECTION, CLAIM_STATUS AS DIM1, NULL AS DIM2, COUNT(*)::VARCHAR AS VAL1, NULL AS VAL2 FROM INSURANCE_AI_HUB.ANALYTICS.CLAIMS GROUP BY CLAIM_STATUS),
rbc AS (SELECT 'RBC' AS SECTION, RISK_CATEGORY AS DIM1, NULL AS DIM2, COUNT(*)::VARCHAR AS VAL1, SUM(REVENUE_AT_RISK)::VARCHAR AS VAL2 FROM INSURANCE_AI_HUB.ANALYTICS.AT_RISK_POLICIES GROUP BY RISK_CATEGORY),
dqt AS (SELECT 'DQT' AS SECTION, TABLE_NAME AS DIM1, SCORE_DATE::VARCHAR AS DIM2, OVERALL_SCORE::VARCHAR AS VAL1, NULL AS VAL2 FROM INSURANCE_AI_HUB.DATA_QUALITY.DQ_SCORES WHERE TABLE_NAME IN ('CUSTOMERS','POLICIES','CLAIMS','BILLING'))
SELECT 'KPI' AS SECTION, TOTAL_PREMIUM::VARCHAR AS DIM1, REVENUE_AT_RISK::VARCHAR AS DIM2, ACTIVE_POLICIES::VARCHAR||'|'||OPEN_CLAIMS::VARCHAR||'|'||AVG_RESOLUTION::VARCHAR AS VAL1, HIGH_RISK_CLAIMS::VARCHAR||'|'||FRAUD_EXPOSURE::VARCHAR||'|'||TOTAL_CUSTOMERS::VARCHAR AS VAL2 FROM kpis
UNION ALL SELECT * FROM pbt UNION ALL SELECT * FROM cbs UNION ALL SELECT * FROM rbc UNION ALL SELECT * FROM dqt`;

export default function ExecutiveDashboard() {
  const q = useSnowflakeQuery('exec-all', DASHBOARD_SQL);
  const refresh = useRefresh('exec-all');

  const fc = (v: any) => { const n=Number(v); if(isNaN(n))return'—'; if(n>=1e6)return`$${(n/1e6).toFixed(1)}M`; if(n>=1e3)return`$${(n/1e3).toFixed(0)}K`; return`$${n.toFixed(0)}`; };

  if (q.isLoading) return <div className="flex items-center justify-center h-64"><Loader2 className="w-8 h-8 text-brand-600 animate-spin" /><span className="ml-3 text-gray-500">Loading dashboard...</span></div>;

  const rows = toObjects(q.data);
  const kpiRow = rows.find(r => r.SECTION === 'KPI');
  const tp = Number(kpiRow?.DIM1||0), rar = Number(kpiRow?.DIM2||0);
  const [ap,oc,ar] = (kpiRow?.VAL1||'0|0|0').split('|');
  const [hrc,fe,tc] = (kpiRow?.VAL2||'0|0|0').split('|');
  const premD = rows.filter(r=>r.SECTION==='PBT').map(r=>({type:r.DIM1,premium:Number(r.VAL2)}));
  const clmD = rows.filter(r=>r.SECTION==='CBS').map(r=>({status:r.DIM1,count:Number(r.VAL1)}));
  const rskD = rows.filter(r=>r.SECTION==='RBC').map(r=>({category:r.DIM1,revenue:Number(r.VAL2)}));
  const dqR = rows.filter(r=>r.SECTION==='DQT');
  const dqDates = [...new Set(dqR.map(r=>r.DIM2))].sort();
  const dqT = dqDates.map(d=>{const row:any={week:d};dqR.filter(r=>r.DIM2===d).forEach(r=>{row[r.DIM1]=Number(r.VAL1)});return row;});

  return (
    <div className="space-y-6">
      <div className="flex justify-end"><RefreshButton onRefresh={refresh} /></div>
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <KPICard label="Premium Revenue" value={fc(tp)} subtitle={`${ap} active policies`} trend="up" />
        <KPICard label="Revenue at Risk" value={fc(rar)} subtitle="At-risk policies" trend="down" />
        <KPICard label="Active Policies" value={ap} trend="up" />
        <KPICard label="Total Customers" value={tc} trend="stable" />
        <KPICard label="Open Claims" value={oc} subtitle="Open+Investigating+Escalated" trend="down" />
        <KPICard label="Avg Resolution Days" value={ar} trend="stable" />
        <KPICard label="High-Risk Claims" value={hrc} subtitle="Fraud score > 0.7" trend="down" />
        <KPICard label="Fraud Risk Exposure" value={fc(Number(fe))} trend="down" />
      </div>
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white dark:bg-slate-800 rounded-xl border border-gray-200 dark:border-slate-700 p-5">
          <h3 className="font-semibold text-gray-900 dark:text-white mb-4">Premium by Policy Type</h3>
          <ResponsiveContainer width="100%" height={250}>
            <BarChart data={premD} layout="vertical"><XAxis type="number" tickFormatter={v=>`$${(v/1000).toFixed(0)}K`}/><YAxis type="category" dataKey="type" width={60}/><Tooltip formatter={(v:number)=>[`$${v.toLocaleString()}`,'Premium']}/><Bar dataKey="premium" radius={[0,6,6,0]}>{premD.map((_,i)=><Cell key={i} fill={COLORS[i%6]}/>)}</Bar></BarChart>
          </ResponsiveContainer>
        </div>
        <div className="bg-white dark:bg-slate-800 rounded-xl border border-gray-200 dark:border-slate-700 p-5">
          <h3 className="font-semibold text-gray-900 dark:text-white mb-4">Claims by Status</h3>
          <ResponsiveContainer width="100%" height={250}>
            <PieChart><Pie data={clmD} dataKey="count" nameKey="status" cx="50%" cy="50%" outerRadius={90} label={({status,percent})=>`${status} ${(percent*100).toFixed(0)}%`}>{clmD.map((_,i)=><Cell key={i} fill={COLORS[i%6]}/>)}</Pie><Tooltip/></PieChart>
          </ResponsiveContainer>
        </div>
      </div>
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white dark:bg-slate-800 rounded-xl border border-gray-200 dark:border-slate-700 p-5">
          <h3 className="font-semibold text-gray-900 dark:text-white mb-4">DQ Score Trend</h3>
          <ResponsiveContainer width="100%" height={250}>
            <LineChart data={dqT}><CartesianGrid strokeDasharray="3 3"/><XAxis dataKey="week" tick={{fontSize:11}}/><YAxis domain={[60,100]}/><Tooltip/><Legend/><Line type="monotone" dataKey="CUSTOMERS" stroke="#ef4444" strokeWidth={2} dot={{r:3}}/><Line type="monotone" dataKey="POLICIES" stroke="#3b82f6" strokeWidth={2} dot={{r:3}}/><Line type="monotone" dataKey="CLAIMS" stroke="#f59e0b" strokeWidth={2} dot={{r:3}}/><Line type="monotone" dataKey="BILLING" stroke="#22c55e" strokeWidth={2} dot={{r:3}}/></LineChart>
          </ResponsiveContainer>
        </div>
        <div className="bg-white dark:bg-slate-800 rounded-xl border border-gray-200 dark:border-slate-700 p-5">
          <h3 className="font-semibold text-gray-900 dark:text-white mb-4">Revenue at Risk by Category</h3>
          <ResponsiveContainer width="100%" height={250}>
            <BarChart data={rskD} layout="vertical"><XAxis type="number" tickFormatter={v=>`$${(v/1000).toFixed(0)}K`}/><YAxis type="category" dataKey="category" width={130} tick={{fontSize:11}}/><Tooltip formatter={(v:number)=>[`$${v.toLocaleString()}`,'Revenue at Risk']}/><Bar dataKey="revenue" fill="#ef4444" radius={[0,6,6,0]}/></BarChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
}
