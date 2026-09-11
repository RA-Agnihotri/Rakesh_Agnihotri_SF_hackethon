import { useSnowflakeQuery, useRefresh, toObjects } from '../hooks/useSnowflakeQuery';
import KPICard from '../components/dashboard/KPICard';
import RefreshButton from '../components/shared/RefreshButton';
import { Loader2, Shield, Users } from 'lucide-react';

const ADMIN_SQL = `SELECT CURRENT_USER()::VARCHAR AS CUR_USER, CURRENT_ROLE()::VARCHAR AS CUR_ROLE, CURRENT_WAREHOUSE()::VARCHAR AS CUR_WH, CURRENT_DATABASE()::VARCHAR AS CUR_DB`;

export default function AdminConsole() {
  const sessionQ = useSnowflakeQuery('admin-all', ADMIN_SQL);
  const rolesQ = useSnowflakeQuery('admin-roles', `SHOW DATABASE ROLES IN DATABASE INSURANCE_AI_HUB`);
  const maskingQ = useSnowflakeQuery('admin-masking', `SHOW MASKING POLICIES IN SCHEMA INSURANCE_AI_HUB.ANALYTICS`);
  const refreshS = useRefresh('admin-all');

  const session = sessionQ.data?.data?.[0] || [];
  const roles = rolesQ.data?.data?.map((r: string[]) => ({ name: r[1], grantedFrom: r[7] })) || [];
  const masking = maskingQ.data?.data?.map((r: string[]) => ({ name: r[1], schema: r[3] })) || [];

  if (sessionQ.isLoading) return <div className="flex items-center justify-center h-64"><Loader2 className="w-8 h-8 text-brand-600 animate-spin" /></div>;

  return (
    <div className="space-y-6">
      <div className="flex justify-end"><RefreshButton onRefresh={refreshS} /></div>
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <KPICard label="Current User" value={session[0]||'—'} trend="stable" />
        <KPICard label="Current Role" value={session[1]||'—'} trend="stable" />
        <KPICard label="Warehouse" value={session[2]||'—'} trend="stable" />
        <KPICard label="Database" value={session[3]||'—'} trend="stable" />
      </div>
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white dark:bg-slate-800 rounded-xl border border-gray-200 dark:border-slate-700 p-5">
          <div className="flex items-center gap-2 mb-4"><Users className="w-4 h-4 text-gray-500" /><h3 className="font-semibold text-gray-900 dark:text-white">Database Roles ({roles.length})</h3></div>
          <div className="space-y-2">{roles.map((r:any,i:number) => (
            <div key={i} className="flex items-center justify-between p-3 rounded-lg bg-gray-50 dark:bg-slate-700/50">
              <p className="text-sm font-medium text-gray-900 dark:text-white font-mono">{r.name}</p>
              <span className="text-xs text-gray-500">{Number(r.grantedFrom)>0?`${r.grantedFrom} child roles`:'Base role'}</span>
            </div>
          ))}</div>
        </div>
        <div className="bg-white dark:bg-slate-800 rounded-xl border border-gray-200 dark:border-slate-700 p-5">
          <div className="flex items-center gap-2 mb-4"><Shield className="w-4 h-4 text-gray-500" /><h3 className="font-semibold text-gray-900 dark:text-white">Masking Policies ({masking.length})</h3></div>
          <div className="space-y-2">{masking.map((m:any,i:number) => (
            <div key={i} className="p-3 rounded-lg bg-gray-50 dark:bg-slate-700/50">
              <p className="text-sm font-medium text-gray-900 dark:text-white font-mono">{m.name}</p>
              <p className="text-xs text-gray-500">Schema: {m.schema}</p>
            </div>
          ))}</div>
        </div>
      </div>
    </div>
  );
}
