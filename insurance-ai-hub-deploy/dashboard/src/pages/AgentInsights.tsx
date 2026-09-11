import KPICard from '../components/dashboard/KPICard';
import RefreshButton from '../components/shared/RefreshButton';
import { useSnowflakeQuery, useRefresh, toObjects } from '../hooks/useSnowflakeQuery';
import { PieChart, Pie, Cell, Tooltip, ResponsiveContainer } from 'recharts';
import { Loader2, Database, Search, CheckCircle2 } from 'lucide-react';

const COLORS = ['#3b82f6', '#22c55e', '#f59e0b', '#ef4444', '#8b5cf6'];

const AGENT_SQL = `
SELECT 'insurance_operations_analyst' AS TOOL, 'Cortex Analyst' AS TYPE, 'SV_INSURANCE_OPS' AS TARGET
UNION ALL SELECT 'data_quality_analyst', 'Cortex Analyst', 'SV_DATA_QUALITY'
UNION ALL SELECT 'policy_document_search', 'Cortex Search', 'CORTEX_SEARCH_SVC'`;

export default function AgentInsights() {
  const q = useSnowflakeQuery('agent-tools', AGENT_SQL);
  const refresh = useRefresh('agent-tools');
  const tools = toObjects(q.data);

  const routing = [{name:'Analytics',value:45},{name:'Documents',value:28},{name:'Data Quality',value:17},{name:'Cross-Domain',value:10}];

  if (q.isLoading) return <div className="flex items-center justify-center h-64"><Loader2 className="w-8 h-8 text-brand-600 animate-spin" /></div>;

  return (
    <div className="space-y-6">
      <div className="flex justify-end"><RefreshButton onRefresh={refresh} /></div>
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <KPICard label="Agent Status" value="LIVE" trend="up" subtitle="VERSION$2" />
        <KPICard label="Tools Configured" value="3" trend="stable" subtitle="2 Analyst + 1 Search" />
        <KPICard label="Semantic Views" value="2" trend="stable" />
        <KPICard label="Search Service" value="ACTIVE" trend="up" subtitle="25 chunks" />
      </div>
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white dark:bg-slate-800 rounded-xl border border-gray-200 dark:border-slate-700 p-5">
          <h3 className="font-semibold text-gray-900 dark:text-white mb-4">Agent Tools</h3>
          <div className="space-y-3">{tools.map(t=>(
            <div key={t.TOOL} className="flex items-center justify-between p-3 rounded-lg bg-gray-50 dark:bg-slate-700/50">
              <div className="flex items-center gap-3">
                {t.TYPE==='Cortex Search'?<Search className="w-5 h-5 text-green-500"/>:<Database className="w-5 h-5 text-blue-500"/>}
                <div><p className="text-sm font-medium text-gray-900 dark:text-white">{t.TOOL}</p><p className="text-xs text-gray-500">{t.TYPE} → {t.TARGET}</p></div>
              </div>
              <span className="flex items-center gap-1 text-xs text-green-600"><CheckCircle2 className="w-3 h-3"/>Active</span>
            </div>))}</div>
        </div>
        <div className="bg-white dark:bg-slate-800 rounded-xl border border-gray-200 dark:border-slate-700 p-5">
          <h3 className="font-semibold text-gray-900 dark:text-white mb-4">Expected Routing</h3>
          <ResponsiveContainer width="100%" height={250}><PieChart><Pie data={routing} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={90} label={({name,percent})=>`${name} ${(percent*100).toFixed(0)}%`}>{routing.map((_,i)=><Cell key={i} fill={COLORS[i]}/>)}</Pie><Tooltip/></PieChart></ResponsiveContainer>
        </div>
      </div>
    </div>
  );
}
